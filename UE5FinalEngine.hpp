// language: C++, file: UE5FinalEngine.hpp, target: iOS ARM64 (TFT v18.7.5951209 - Sheepct Final Engine)
#pragma once
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>
#include <unordered_map>
#include <algorithm>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>

namespace UE5 {

template <typename T>
inline bool ReadMem(uintptr_t addr, T &out) {
    if (!addr || addr < 0x100000000ULL || addr > 0x1800000000ULL) return false;
    mach_vm_size_t outSize = 0;
    kern_return_t kr = mach_vm_read_overwrite(
        mach_task_self(),
        (mach_vm_address_t)addr,
        sizeof(T),
        (mach_vm_address_t)&out,
        &outSize
    );
    return (kr == KERN_SUCCESS && outSize == sizeof(T));
}

template <typename T>
inline bool WriteMem(uintptr_t addr, const T &val) {
    if (!addr || addr < 0x100000000ULL || addr > 0x1800000000ULL) return false;
    vm_machine_attribute_val_t valAttr = MATTR_VAL_CACHE_FLUSH;
    (void)valAttr;
    kern_return_t kr = mach_vm_write(
        mach_task_self(),
        (mach_vm_address_t)addr,
        (vm_offset_t)&val,
        sizeof(T)
    );
    return (kr == KERN_SUCCESS);
}

struct ImageLayout {
    uintptr_t base = 0;
    uintptr_t textStart = 0;
    size_t    textSize = 0;
    uintptr_t cstringStart = 0;
    size_t    cstringSize = 0;
};

inline ImageLayout GetMainImageLayout() {
    ImageLayout layout{};
    const struct mach_header_64 *hdr = reinterpret_cast<const struct mach_header_64 *>(_dyld_get_image_header(0));
    if (!hdr) return layout;
    layout.base = reinterpret_cast<uintptr_t>(hdr);
    intptr_t slide = _dyld_get_image_vmaddr_slide(0);

    const uint8_t *cmdPtr = reinterpret_cast<const uint8_t *>(hdr + 1);
    for (uint32_t i = 0; i < hdr->ncmds; ++i) {
        const struct load_command *lc = reinterpret_cast<const struct load_command *>(cmdPtr);
        if (lc->cmd == LC_SEGMENT_64) {
            const struct segment_command_64 *seg = reinterpret_cast<const struct segment_command_64 *>(cmdPtr);
            if (strcmp(seg->segname, "__TEXT") == 0) {
                const struct section_64 *sec = reinterpret_cast<const struct section_64 *>(seg + 1);
                for (uint32_t j = 0; j < seg->nsects; ++j) {
                    if (strcmp(sec[j].sectname, "__text") == 0) {
                        layout.textStart = static_cast<uintptr_t>(sec[j].addr + slide);
                        layout.textSize = static_cast<size_t>(sec[j].size);
                    } else if (strcmp(sec[j].sectname, "__cstring") == 0) {
                        layout.cstringStart = static_cast<uintptr_t>(sec[j].addr + slide);
                        layout.cstringSize = static_cast<size_t>(sec[j].size);
                    }
                }
            }
        }
        cmdPtr += lc->cmdsize;
    }
    return layout;
}

struct FName {
    int32_t ComparisonIndex = 0;
    int32_t Number = 0;
};

struct UObject {
    uintptr_t VTable = 0;
    int32_t   ObjectFlags = 0;
    int32_t   InternalIndex = 0;
    uintptr_t ClassPrivate = 0;
    FName     NamePrivate;
    uintptr_t OuterPrivate = 0;
};

struct FUObjectItem {
    uintptr_t Object = 0;
    int32_t   Flags = 0;
    int32_t   ClusterRootIndex = 0;
    int32_t   SerialNumber = 0;
    int32_t   Pad = 0;
};

struct TArrayHeader {
    uintptr_t Data = 0;
    int32_t   Count = 0;
    int32_t   Max = 0;
};

class FinalRuntimeSDK {
public:
    ImageLayout img{};
    uintptr_t GWorldPtr = 0;
    uintptr_t FNamePoolAddr = 0;
    uintptr_t GUObjectArrayAddr = 0;
    int32_t   ProcessEventVTableIdx = -1;
    uintptr_t CachedProcessEventAddr = 0;

    std::unordered_map<std::string, int32_t> propOffsetCache;
    std::unordered_map<std::string, uintptr_t> funcCache;

    static uintptr_t ResolveADRP(uintptr_t pc) {
        uint32_t i1 = 0, i2 = 0;
        if (!ReadMem(pc, i1) || !ReadMem(pc + 4, i2)) return 0;
        if ((i1 & 0x9F000000) != 0x90000000) return 0;
        int64_t imm = (((int64_t)((i1 >> 5) & 0x7FFFF) << 2) | ((i1 >> 29) & 0x3)) << 12;
        if (imm & (1ULL << 32)) imm |= ~((1ULL << 33) - 1);
        uintptr_t page = static_cast<uintptr_t>(static_cast<int64_t>(pc & ~0xFFFULL) + imm);
        if ((i2 & 0xFF800000) == 0x91000000) {
            uint32_t imm12 = (i2 >> 10) & 0xFFF;
            uint32_t sh = (i2 >> 22) & 0x1;
            return page + (static_cast<uintptr_t>(imm12) << (sh ? 12 : 0));
        }
        if ((i2 & 0xFFC00000) == 0xF9400000) {
            uint32_t imm12 = (i2 >> 10) & 0xFFF;
            return page + (static_cast<uintptr_t>(imm12) << 3);
        }
        return 0;
    }

    uintptr_t FindCString(const char *needle) const {
        if (!img.cstringStart || !img.cstringSize || !needle) return 0;
        size_t len = strlen(needle) + 1;
        const uint8_t *p = reinterpret_cast<const uint8_t *>(img.cstringStart);
        for (size_t i = 0; i + len <= img.cstringSize; ++i) {
            if (memcmp(p + i, needle, len) == 0) return img.cstringStart + i;
        }
        return 0;
    }

    bool IsValidCodePtr(uintptr_t addr) const {
        return img.textStart && addr >= img.textStart && addr < (img.textStart + img.textSize);
    }

    void Bootstrap() {
        img = GetMainImageLayout();
        if (!img.textStart) return;

        auto ScanXref = [&](const char *anchor, int rangeBack, int rangeFwd, bool requireLDR) -> uintptr_t {
            uintptr_t strAddr = FindCString(anchor);
            if (!strAddr) return 0;
            for (size_t off = 0; off + 64 < img.textSize; off += 4) {
                uintptr_t pc = img.textStart + off;
                if (ResolveADRP(pc) == strAddr) {
                    for (int d = rangeBack; d <= rangeFwd; d += 4) {
                        if (d == 0) continue;
                        uintptr_t candPC = static_cast<uintptr_t>(static_cast<int64_t>(pc) + d);
                        if (requireLDR) {
                            uint32_t insn2 = 0;
                            if (!ReadMem(candPC + 4, insn2) || (insn2 & 0xFFC00000) != 0xF9400000) continue;
                        }
                        uintptr_t cand = ResolveADRP(candPC);
                        if (cand && cand > img.textStart + img.textSize) return cand;
                    }
                }
            }
            return 0;
        };

        FNamePoolAddr     = ScanXref("ByteProperty", -28, 28, false);
        GWorldPtr         = ScanXref("SeamlessTravel FlushLevelStreaming", -64, 64, true);
        GUObjectArrayAddr = ScanXref("MaxUObjectsNotConsideredByGC", -48, 48, false);

        uintptr_t sampleObj = FindFirstObjectOfClass("TFTPlayerController");
        if (!sampleObj) sampleObj = FindFirstObjectOfClass("PlayerController");
        if (!sampleObj) sampleObj = FindFirstObjectOfClass("GameEngine");
        if (sampleObj) {
            uintptr_t vt = 0;
            if (ReadMem(sampleObj, vt) && vt) {
                for (int idx = 62; idx <= 82; ++idx) {
                    uintptr_t fnPtr = 0;
                    if (ReadMem(vt + static_cast<uintptr_t>(idx) * 8, fnPtr) && IsValidCodePtr(fnPtr)) {
                        ProcessEventVTableIdx = idx;
                        CachedProcessEventAddr = fnPtr;
                        break;
                    }
                }
            }
        }
    }

    std::string GetFName(int32_t index) const {
        if (!FNamePoolAddr || index < 0) return "";
        uint32_t block = static_cast<uint32_t>(index) >> 16;
        uint32_t offset = static_cast<uint32_t>(index) & 0xFFFF;
        uintptr_t blockPtr = 0;
        if (!ReadMem(FNamePoolAddr + 0x10 + static_cast<uintptr_t>(block) * 8, blockPtr) || !blockPtr) return "";

        uintptr_t entry = blockPtr + static_cast<uintptr_t>(offset) * 2;
        uint16_t hdr = 0;
        if (!ReadMem(entry, hdr)) return "";
        bool isWide = (hdr & 1) != 0;
        uint16_t len = hdr >> 6;
        if (len == 0 || len > 512) return "";

        char buf[516] = {0};
        mach_vm_size_t sz = 0;
        size_t byteLen = isWide ? static_cast<size_t>(len) * 2 : static_cast<size_t>(len);
        if (mach_vm_read_overwrite(mach_task_self(), entry + 2, byteLen, (mach_vm_address_t)buf, &sz) != KERN_SUCCESS) return "";
        if (!isWide) return std::string(buf, len);
        std::string out;
        out.reserve(len);
        for (uint16_t i = 0; i < len; ++i) out.push_back(buf[i * 2]);
        return out;
    }

    std::string GetObjectName(uintptr_t obj) const {
        UObject u{};
        if (!ReadMem(obj, u)) return "";
        return GetFName(u.NamePrivate.ComparisonIndex);
    }

    std::vector<uintptr_t> FindAllObjectsOfClass(const std::string &targetClassName, size_t maxCount = 128) const {
        std::vector<uintptr_t> results;
        if (!GUObjectArrayAddr || !FNamePoolAddr) return results;
        uintptr_t objectsPtr = 0;
        int32_t numElements = 0;
        if (!ReadMem(GUObjectArrayAddr + 0x10, objectsPtr) || !ReadMem(GUObjectArrayAddr + 0x24, numElements)) return results;
        if (!objectsPtr || numElements <= 0 || numElements > 1500000) return results;

        constexpr int32_t kPerChunk = 64 * 1024;
        for (int32_t i = 0; i < numElements; ++i) {
            uintptr_t chunk = 0;
            if (!ReadMem(objectsPtr + static_cast<uintptr_t>(i / kPerChunk) * 8, chunk) || !chunk) continue;
            FUObjectItem item{};
            if (!ReadMem(chunk + static_cast<uintptr_t>(i % kPerChunk) * sizeof(FUObjectItem), item) || !item.Object) continue;

            uintptr_t cls = 0;
            if (ReadMem(item.Object + 0x10, cls) && cls) {
                if (GetObjectName(cls) == targetClassName) {
                    results.push_back(item.Object);
                    if (results.size() >= maxCount) break;
                }
            }
        }
        return results;
    }

    uintptr_t FindFirstObjectOfClass(const std::string &targetClassName) const {
        auto v = FindAllObjectsOfClass(targetClassName, 1);
        return v.empty() ? 0 : v[0];
    }

    int32_t ResolvePropertyOffset(uintptr_t ustructAddr, const std::string &propName) {
        if (!ustructAddr) return -1;
        std::string key = std::to_string(ustructAddr) + ":" + propName;
        auto it = propOffsetCache.find(key);
        if (it != propOffsetCache.end()) return it->second;

        uintptr_t curStruct = ustructAddr;
        int depth = 0;
        while (curStruct && depth++ < 16) {
            uintptr_t prop = 0;
            ReadMem(curStruct + 0x50, prop);
            int guard = 0;
            while (prop && guard++ < 512) {
                FName pName{};
                ReadMem(prop + 0x28, pName);
                if (GetFName(pName.ComparisonIndex) == propName) {
                    int32_t offsetInternal = -1;
                    ReadMem(prop + 0x4C, offsetInternal);
                    propOffsetCache[key] = offsetInternal;
                    return offsetInternal;
                }
                ReadMem(prop + 0x20, prop);
            }
            ReadMem(curStruct + 0x40, curStruct);
        }
        propOffsetCache[key] = -1;
        return -1;
    }

    std::vector<std::string> ReadFNameArray(uintptr_t ownerObj, uintptr_t classAddr, const std::string &propName, int maxItems = 32) {
        std::vector<std::string> out;
        int32_t off = ResolvePropertyOffset(classAddr, propName);
        if (off <= 0) return out;
        TArrayHeader arr{};
        if (!ReadMem(ownerObj + static_cast<uintptr_t>(off), arr) || !arr.Data || arr.Count <= 0 || arr.Count > maxItems) return out;
        for (int32_t i = 0; i < arr.Count; ++i) {
            FName fn{};
            if (ReadMem(arr.Data + static_cast<uintptr_t>(i) * sizeof(FName), fn)) {
                std::string s = GetFName(fn.ComparisonIndex);
                if (!s.empty()) out.push_back(s);
            }
        }
        return out;
    }

    uintptr_t FindFunction(uintptr_t uclassAddr, const std::string &funcName) {
        if (!uclassAddr) return 0;
        std::string key = std::to_string(uclassAddr) + "::" + funcName;
        auto it = funcCache.find(key);
        if (it != funcCache.end()) return it->second;

        uintptr_t curStruct = uclassAddr;
        int depth = 0;
        while (curStruct && depth++ < 16) {
            uintptr_t field = 0;
            ReadMem(curStruct + 0x48, field);
            int guard = 0;
            while (field && guard++ < 512) {
                if (GetObjectName(field) == funcName) {
                    funcCache[key] = field;
                    return field;
                }
                ReadMem(field + 0x28, field);
            }
            ReadMem(curStruct + 0x40, curStruct);
        }
        funcCache[key] = 0;
        return 0;
    }

    bool CallProcessEvent(uintptr_t targetObj, uintptr_t ufunc, void *params) {
        if (!targetObj || !ufunc) return false;
        uintptr_t peAddr = CachedProcessEventAddr;
        if (!peAddr) {
            uintptr_t vtable = 0;
            if (!ReadMem(targetObj, vtable) || !vtable || ProcessEventVTableIdx < 0) return false;
            if (!ReadMem(vtable + static_cast<uintptr_t>(ProcessEventVTableIdx) * 8, peAddr) || !IsValidCodePtr(peAddr)) return false;
            CachedProcessEventAddr = peAddr;
        }
        using ProcessEventFn = void (*)(uintptr_t, uintptr_t, void *);
        reinterpret_cast<ProcessEventFn>(peAddr)(targetObj, ufunc, params);
        return true;
    }
};

} // namespace UE5
