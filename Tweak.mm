// language: Objective-C++, file: Tweak.mm, target: iOS ARM64 (TFT v18.7.5951209 - Sheepct Grandmaster v11 Final)
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include "UE5FinalEngine.hpp"
#include "FinalMetaAndEconomy.hpp"
#include <cmath>
#include <algorithm>

template <typename T>
static inline T ClampVal(T v, T lo, T hi) {
    return (v < lo) ? lo : ((v > hi) ? hi : v);
}

@interface SheepctPassthroughView : UIView
@end

@implementation SheepctPassthroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return (hit == self) ? nil : hit;
}
@end

@interface SheepctPassthroughWindow : UIWindow
@end

@implementation SheepctPassthroughWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return (hit == self || hit == self.rootViewController.view) ? nil : hit;
}
@end

namespace ScreenLayout {

enum class UIAction {
    FindMatchButton,
    AcceptMatchButton,
    BuyXPButton,
    RefreshShopButton,
    ShopSlot0, ShopSlot1, ShopSlot2, ShopSlot3, ShopSlot4,
    AugmentCard0, AugmentCard1, AugmentCard2,
    ArmoryCard0, ArmoryCard1, ArmoryCard2,
    CarouselPriority0,
    ExitEliminatedButton
};

struct ViewportMetrics {
    CGRect fullBounds;
    UIEdgeInsets safeInsets;
    CGRect safeCanvas;
    CGRect game16x9Frame;
};

static ViewportMetrics ResolveMetrics() {
    ViewportMetrics m{};
    UIWindow *win = nil;
    for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
        if (s.activationState == UISceneActivationStateForegroundActive && [s isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *ws = (UIWindowScene *)s;
            for (UIWindow *w in ws.windows) {
                if (![w isKindOfClass:[SheepctPassthroughWindow class]] && !w.hidden) { win = w; break; }
            }
            if (!win) win = ws.windows.firstObject;
            break;
        }
    }
    if (!win) {
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            if (![w isKindOfClass:[SheepctPassthroughWindow class]] && !w.hidden) { win = w; break; }
        }
    }

    CGRect bounds = win ? win.bounds : [UIScreen mainScreen].bounds;
    if (bounds.size.height > bounds.size.width) {
        bounds.size = CGSizeMake(bounds.size.height, bounds.size.width);
    }
    UIEdgeInsets insets = win ? win.safeAreaInsets : UIEdgeInsetsZero;

    m.fullBounds = bounds;
    m.safeInsets = insets;

    CGFloat leftPad = std::max(insets.left, insets.right);
    CGFloat bottomPad = insets.bottom * 0.5;
    m.safeCanvas = CGRectMake(leftPad, insets.top, bounds.size.width - leftPad * 2.0, bounds.size.height - insets.top - bottomPad);

    CGFloat targetRatio = 16.0 / 9.0;
    CGFloat curRatio = m.safeCanvas.size.width / std::max<CGFloat>(1.0, m.safeCanvas.size.height);
    if (curRatio > targetRatio) {
        m.game16x9Frame = m.safeCanvas;
    } else {
        CGFloat h = m.safeCanvas.size.width / targetRatio;
        CGFloat y = m.safeCanvas.origin.y + (m.safeCanvas.size.height - h) * 0.5;
        m.game16x9Frame = CGRectMake(m.safeCanvas.origin.x, y, m.safeCanvas.size.width, h);
    }
    return m;
}

static CGPoint PointForAction(UIAction action) {
    ViewportMetrics m = ResolveMetrics();
    CGRect hud = m.safeCanvas;
    CGRect c16 = m.game16x9Frame;

    auto HudPt = [&](CGFloat nx, CGFloat ny) -> CGPoint {
        return CGPointMake(hud.origin.x + hud.size.width * nx, hud.origin.y + hud.size.height * ny);
    };
    auto CenterPt = [&](CGFloat nx, CGFloat ny) -> CGPoint {
        return CGPointMake(c16.origin.x + c16.size.width * nx, c16.origin.y + c16.size.height * ny);
    };

    switch (action) {
        case UIAction::BuyXPButton:          return HudPt(0.085, 0.835);
        case UIAction::RefreshShopButton:    return HudPt(0.085, 0.935);
        case UIAction::FindMatchButton:      return HudPt(0.865, 0.915);
        case UIAction::ShopSlot0:            return HudPt(0.225, 0.905);
        case UIAction::ShopSlot1:            return HudPt(0.362, 0.905);
        case UIAction::ShopSlot2:            return HudPt(0.500, 0.905);
        case UIAction::ShopSlot3:            return HudPt(0.638, 0.905);
        case UIAction::ShopSlot4:            return HudPt(0.775, 0.905);
        case UIAction::AcceptMatchButton:    return CenterPt(0.500, 0.745);
        case UIAction::AugmentCard0:
        case UIAction::ArmoryCard0:          return CenterPt(0.245, 0.520);
        case UIAction::AugmentCard1:
        case UIAction::ArmoryCard1:          return CenterPt(0.500, 0.520);
        case UIAction::AugmentCard2:
        case UIAction::ArmoryCard2:          return CenterPt(0.755, 0.520);
        case UIAction::CarouselPriority0:    return CenterPt(0.420, 0.480);
        case UIAction::ExitEliminatedButton: return CenterPt(0.500, 0.640);
    }
    return CenterPt(0.5, 0.5);
}

static CGRect RectForShopSlot(int slotIndex) {
    ViewportMetrics m = ResolveMetrics();
    CGRect hud = m.safeCanvas;
    CGFloat slotW = hud.size.width * 0.128;
    CGFloat slotH = hud.size.height * 0.165;
    int clampedSlot = ClampVal(slotIndex, 0, 4);
    UIAction act = static_cast<UIAction>(static_cast<int>(UIAction::ShopSlot0) + clampedSlot);
    CGPoint center = PointForAction(act);
    return CGRectMake(center.x - slotW * 0.5, center.y - slotH * 0.5, slotW, slotH);
}

static CGRect RectForBoardHex(int row, int col) {
    ViewportMetrics m = ResolveMetrics();
    CGRect c16 = m.game16x9Frame;
    CGFloat startX = c16.origin.x + c16.size.width * 0.255;
    CGFloat stepX  = c16.size.width * 0.078;
    CGFloat startY = c16.origin.y + c16.size.height * 0.440;
    CGFloat stepY  = c16.size.height * 0.082;
    CGFloat stagger = (row % 2 == 1) ? (stepX * 0.5) : 0.0;
    CGFloat cx = startX + static_cast<CGFloat>(col) * stepX + stagger;
    CGFloat cy = startY + static_cast<CGFloat>(row) * stepY;
    return CGRectMake(cx - 21.0, cy - 21.0, 42.0, 42.0);
}

static CGPoint PointForBenchSlot(int benchIdx) {
    ViewportMetrics m = ResolveMetrics();
    CGRect c16 = m.game16x9Frame;
    CGFloat startX = c16.origin.x + c16.size.width * 0.215;
    CGFloat stepX  = c16.size.width * 0.071;
    CGFloat y      = c16.origin.y + c16.size.height * 0.775;
    int clamped = ClampVal(benchIdx, 0, 8);
    return CGPointMake(startX + static_cast<CGFloat>(clamped) * stepX, y);
}

static CGPoint PointForItemBenchSlot(int itemIdx) {
    ViewportMetrics m = ResolveMetrics();
    CGRect hud = m.safeCanvas;
    CGFloat x = hud.origin.x + hud.size.width * 0.045;
    CGFloat startY = hud.origin.y + hud.size.height * 0.280;
    CGFloat stepY  = hud.size.height * 0.055;
    int clamped = ClampVal(itemIdx, 0, 9);
    return CGPointMake(x, startY + static_cast<CGFloat>(clamped) * stepY);
}

} // namespace ScreenLayout

namespace TFTCore {

struct UnitInstance {
    uintptr_t actorAddr = 0;
    std::string champName;
    int starLevel = 1;
    int cost = 1;
    int row = -1;
    int col = 0;
    std::vector<std::string> equippedItems;
};

struct EnemyIntel {
    int slot = 0;
    int hp = 100;
    int level = 1;
    bool hasAssassins = false;
    bool hasHeavyAoE = false;
    bool hasZephyrOrShroud = false;
};

struct LiveState {
    bool inGame = false;
    bool isEliminated = false;
    bool isCarousel = false;
    bool hasArmoryPopup = false;
    int stage = 1;
    int round = 1;
    int hp = 100;
    int gold = 0;
    int level = 1;
    int streak = 0;
    int aliveCount = 8;
    int lobbyAvgLevel = 1;
    std::string shopSlots[5];
    std::vector<UnitInstance> myBoardUnits;
    std::vector<UnitInstance> myBenchUnits;
    std::vector<std::string> itemBenchItems;
    std::vector<std::string> augmentChoices;
    std::vector<EnemyIntel> enemies;
    std::unordered_map<std::string, int> globalPoolTaken;
};

static UE5::FinalRuntimeSDK g_SDK;

static UIView *FindGameRenderView(UIView *root) {
    if (!root) return nil;
    NSString *clsName = NSStringFromClass([root class]);
    if ([clsName containsString:@"FIOSView"] || [clsName containsString:@"Metal"] || [clsName containsString:@"EAGL"]) {
        return root;
    }
    for (UIView *sub in root.subviews) {
        UIView *found = FindGameRenderView(sub);
        if (found) return found;
    }
    return nil;
}

static void SimulateTouchAt(CGPoint pt) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *gameWin = nil;
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            if (![w isKindOfClass:[SheepctPassthroughWindow class]] && !w.hidden) { gameWin = w; break; }
        }
        if (!gameWin) return;
        UIView *renderView = FindGameRenderView(gameWin) ?: gameWin;

        UITouch *touch = [[UITouch alloc] init];
        @try {
            [touch setValue:@(UITouchPhaseBegan) forKey:@"phase"];
            [touch setValue:@(1) forKey:@"tapCount"];
            [touch setValue:gameWin forKey:@"window"];
            [touch setValue:renderView forKey:@"view"];
            [touch setValue:[NSValue valueWithCGPoint:pt] forKey:@"_locationInWindow"];
            [touch setValue:[NSValue valueWithCGPoint:pt] forKey:@"_previousLocationInWindow"];
            [touch setValue:@([[NSProcessInfo processInfo] systemUptime]) forKey:@"timestamp"];

            NSSet *touches = [NSSet setWithObject:touch];
            UIEvent *event = [[UIApplication sharedApplication] valueForKey:@"_touchesEvent"];
            if (event && [event respondsToSelector:@selector(_addTouch:forDelayedDelivery:)]) {
                ((void (*)(id, SEL, id, BOOL))objc_msgSend)(event, @selector(_addTouch:forDelayedDelivery:), touch, NO);
            }
            [renderView touchesBegan:touches withEvent:event];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.04 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [touch setValue:@(UITouchPhaseEnded) forKey:@"phase"];
                [touch setValue:@([[NSProcessInfo processInfo] systemUptime]) forKey:@"timestamp"];
                [renderView touchesEnded:touches withEvent:event];
            });
        } @catch (NSException *ex) {
            UIView *hit = [gameWin hitTest:pt withEvent:nil];
            if ([hit isKindOfClass:[UIControl class]]) {
                [(UIControl *)hit sendActionsForControlEvents:UIControlEventTouchUpInside];
            }
        }
    });
}

static void SimulateDrag(CGPoint fromPt, CGPoint toPt) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *gameWin = nil;
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            if (![w isKindOfClass:[SheepctPassthroughWindow class]] && !w.hidden) { gameWin = w; break; }
        }
        if (!gameWin) return;
        UIView *renderView = FindGameRenderView(gameWin) ?: gameWin;

        UITouch *touch = [[UITouch alloc] init];
        @try {
            [touch setValue:@(UITouchPhaseBegan) forKey:@"phase"];
            [touch setValue:@(1) forKey:@"tapCount"];
            [touch setValue:gameWin forKey:@"window"];
            [touch setValue:renderView forKey:@"view"];
            [touch setValue:[NSValue valueWithCGPoint:fromPt] forKey:@"_locationInWindow"];
            [touch setValue:[NSValue valueWithCGPoint:fromPt] forKey:@"_previousLocationInWindow"];
            [touch setValue:@([[NSProcessInfo processInfo] systemUptime]) forKey:@"timestamp"];

            NSSet *touches = [NSSet setWithObject:touch];
            UIEvent *event = [[UIApplication sharedApplication] valueForKey:@"_touchesEvent"];
            if (event && [event respondsToSelector:@selector(_addTouch:forDelayedDelivery:)]) {
                ((void (*)(id, SEL, id, BOOL))objc_msgSend)(event, @selector(_addTouch:forDelayedDelivery:), touch, NO);
            }
            [renderView touchesBegan:touches withEvent:event];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.06 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [touch setValue:@(UITouchPhaseMoved) forKey:@"phase"];
                [touch setValue:[NSValue valueWithCGPoint:fromPt] forKey:@"_previousLocationInWindow"];
                [touch setValue:[NSValue valueWithCGPoint:toPt] forKey:@"_locationInWindow"];
                [touch setValue:@([[NSProcessInfo processInfo] systemUptime]) forKey:@"timestamp"];
                [renderView touchesMoved:touches withEvent:event];

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.06 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [touch setValue:@(UITouchPhaseEnded) forKey:@"phase"];
                    [touch setValue:@([[NSProcessInfo processInfo] systemUptime]) forKey:@"timestamp"];
                    [renderView touchesEnded:touches withEvent:event];
                });
            });
        } @catch (NSException *ex) {}
    });
}

static LiveState PollLiveState() {
    LiveState st;
    if (!g_SDK.GUObjectArrayAddr || !g_SDK.FNamePoolAddr) return st;

    auto playerStates = g_SDK.FindAllObjectsOfClass("TFTPlayerState", 16);
    if (playerStates.empty()) return st;

    uintptr_t psClass = 0;
    if (!UE5::ReadMem(playerStates[0] + 0x10, psClass) || !psClass) return st;
    st.inGame = true;

    int32_t offGoldA  = g_SDK.ResolvePropertyOffset(psClass, "Gold");
    int32_t offGoldB  = g_SDK.ResolvePropertyOffset(psClass, "CurrentGold");
    int32_t offGold   = std::max(offGoldA, offGoldB);

    int32_t offHPA    = g_SDK.ResolvePropertyOffset(psClass, "Health");
    int32_t offHPB    = g_SDK.ResolvePropertyOffset(psClass, "CurrentHealth");
    int32_t offHP     = std::max(offHPA, offHPB);

    int32_t offLvlA   = g_SDK.ResolvePropertyOffset(psClass, "Level");
    int32_t offLvlB   = g_SDK.ResolvePropertyOffset(psClass, "CurrentLevel");
    int32_t offLevel  = std::max(offLvlA, offLvlB);

    int32_t offStreak = g_SDK.ResolvePropertyOffset(psClass, "WinStreak");
    int32_t offLocal  = g_SDK.ResolvePropertyOffset(psClass, "bIsLocalPlayer");

    int alive = 0, sumLvl = 0;
    uintptr_t localPS = 0;
    for (size_t idx = 0; idx < playerStates.size(); ++idx) {
        uintptr_t ps = playerStates[idx];
        int hp = 100, lvl = 1, gold = 0, streak = 0;
        uint8_t isLocal = (idx == 0) ? 1 : 0;

        if (offHP > 0) UE5::ReadMem(ps + static_cast<uintptr_t>(offHP), hp);
        if (offLevel > 0) UE5::ReadMem(ps + static_cast<uintptr_t>(offLevel), lvl);
        if (offGold > 0) UE5::ReadMem(ps + static_cast<uintptr_t>(offGold), gold);
        if (offStreak > 0) UE5::ReadMem(ps + static_cast<uintptr_t>(offStreak), streak);
        if (offLocal > 0) UE5::ReadMem(ps + static_cast<uintptr_t>(offLocal), isLocal);

        if (hp > 0) { alive++; sumLvl += lvl; }
        if (isLocal || idx == 0) {
            localPS = ps;
            st.hp = hp; st.level = lvl; st.gold = gold; st.streak = streak;
            st.isEliminated = (hp <= 0);
        } else {
            EnemyIntel ei;
            ei.slot = static_cast<int>(idx); ei.hp = hp; ei.level = lvl;
            st.enemies.push_back(ei);
        }
    }
    st.aliveCount = std::max(1, alive);
    st.lobbyAvgLevel = std::max(1, sumLvl / st.aliveCount);

    if (localPS) {
        auto items = g_SDK.ReadFNameArray(localPS, psClass, "ItemBench", 16);
        if (items.empty()) items = g_SDK.ReadFNameArray(localPS, psClass, "InventoryItems", 16);
        st.itemBenchItems = items;

        auto shopArr = g_SDK.ReadFNameArray(localPS, psClass, "ShopChampions", 5);
        for (size_t i = 0; i < std::min<size_t>(5, shopArr.size()); ++i) {
            st.shopSlots[i] = shopArr[i];
        }
        st.augmentChoices = g_SDK.ReadFNameArray(localPS, psClass, "AugmentChoices", 3);
    }

    auto actors = g_SDK.FindAllObjectsOfClass("TFTArmyActor", 128);
    if (!actors.empty()) {
        uintptr_t actClass = 0;
        if (UE5::ReadMem(actors[0] + 0x10, actClass) && actClass) {
            int32_t offStar  = g_SDK.ResolvePropertyOffset(actClass, "StarLevel");
            int32_t offCost  = g_SDK.ResolvePropertyOffset(actClass, "GoldCost");
            int32_t offRow   = g_SDK.ResolvePropertyOffset(actClass, "GridRow");
            int32_t offCol   = g_SDK.ResolvePropertyOffset(actClass, "GridCol");
            int32_t offItems = g_SDK.ResolvePropertyOffset(actClass, "HeldItems");

            for (uintptr_t act : actors) {
                std::string rawName = g_SDK.GetObjectName(act);
                if (rawName.empty()) continue;
                st.globalPoolTaken[rawName] += 1;
                UnitInstance u;
                u.actorAddr = act;
                u.champName = rawName;
                if (offStar > 0) UE5::ReadMem(act + static_cast<uintptr_t>(offStar), u.starLevel);
                if (offCost > 0) UE5::ReadMem(act + static_cast<uintptr_t>(offCost), u.cost);
                if (offRow > 0) UE5::ReadMem(act + static_cast<uintptr_t>(offRow), u.row);
                if (offCol > 0) UE5::ReadMem(act + static_cast<uintptr_t>(offCol), u.col);

                if (offItems > 0) {
                    UE5::TArrayHeader itemArr{};
                    if (UE5::ReadMem(act + static_cast<uintptr_t>(offItems), itemArr) &&
                        itemArr.Data && itemArr.Count > 0 && itemArr.Count <= 3) {
                        for (int32_t k = 0; k < itemArr.Count; ++k) {
                            uintptr_t itemObj = 0;
                            if (UE5::ReadMem(itemArr.Data + static_cast<uintptr_t>(k) * 8, itemObj) && itemObj) {
                                u.equippedItems.push_back(g_SDK.GetObjectName(itemObj));
                            }
                        }
                    }
                }

                if (u.row >= 0 && u.row <= 3) st.myBoardUnits.push_back(u);
                else st.myBenchUnits.push_back(u);
            }
        }
    }

    uintptr_t gameState = g_SDK.FindFirstObjectOfClass("TFTGameState");
    if (gameState) {
        uintptr_t gsClass = 0;
        if (UE5::ReadMem(gameState + 0x10, gsClass) && gsClass) {
            int32_t offStage = g_SDK.ResolvePropertyOffset(gsClass, "Stage");
            int32_t offRound = g_SDK.ResolvePropertyOffset(gsClass, "Round");
            if (offStage > 0) UE5::ReadMem(gameState + static_cast<uintptr_t>(offStage), st.stage);
            if (offRound > 0) UE5::ReadMem(gameState + static_cast<uintptr_t>(offRound), st.round);
            st.isCarousel = (st.round == 4 && st.stage >= 2) || (st.stage == 1 && st.round == 1);
        }
    }
    return st;
}

static bool SendRPC(const char *rpcName, void *rpcParams) {
    if (!g_SDK.GUObjectArrayAddr || !g_SDK.FNamePoolAddr || !rpcName) return false;
    uintptr_t pc = g_SDK.FindFirstObjectOfClass("TFTPlayerController");
    if (!pc) return false;
    uintptr_t pcClass = 0;
    if (!UE5::ReadMem(pc + 0x10, pcClass) || !pcClass) return false;
    uintptr_t fn = g_SDK.FindFunction(pcClass, rpcName);
    if (!fn) return false;
    return g_SDK.CallProcessEvent(pc, fn, rpcParams);
}

static void BuyXP()          { if (!SendRPC("Server_ShopExp", nullptr)) SimulateTouchAt(ScreenLayout::PointForAction(ScreenLayout::UIAction::BuyXPButton)); }
static void RollShop()       { if (!SendRPC("Server_ShopRoll", nullptr)) SimulateTouchAt(ScreenLayout::PointForAction(ScreenLayout::UIAction::RefreshShopButton)); }
static void BuySlot(int idx) {
    int32_t p = idx;
    ScreenLayout::UIAction s[5] = {ScreenLayout::UIAction::ShopSlot0, ScreenLayout::UIAction::ShopSlot1, ScreenLayout::UIAction::ShopSlot2, ScreenLayout::UIAction::ShopSlot3, ScreenLayout::UIAction::ShopSlot4};
    if (!SendRPC("Server_ShopPurchase", &p)) SimulateTouchAt(ScreenLayout::PointForAction(s[ClampVal(idx, 0, 4)]));
}
static void SellUnit(uintptr_t actorAddr, int benchSlotFallback) {
    if (!SendRPC("Server_ShopSell", &actorAddr)) {
        SimulateDrag(ScreenLayout::PointForBenchSlot(benchSlotFallback), ScreenLayout::PointForAction(ScreenLayout::UIAction::ShopSlot4));
    }
}
static void MoveUnitToHex(uintptr_t actorAddr, int benchIdx, int targetRow, int targetCol) {
    struct MoveParams { uintptr_t Actor; int32_t Row; int32_t Col; } mp{actorAddr, targetRow, targetCol};
    if (!SendRPC("Server_MoveActor", &mp)) {
        CGRect hex = ScreenLayout::RectForBoardHex(targetRow, targetCol);
        SimulateDrag(ScreenLayout::PointForBenchSlot(benchIdx), CGPointMake(CGRectGetMidX(hex), CGRectGetMidY(hex)));
    }
}
static void CombineAndEquip(uintptr_t targetActor, int itemSlotA, int itemSlotB) {
    struct CombineParams { int32_t SlotA; int32_t SlotB; uintptr_t TargetActor; } cp{itemSlotA, itemSlotB, targetActor};
    SendRPC("Server_CombineItems", &cp);
}
static void EquipSingleItem(uintptr_t targetActor, int itemSlot, int hexRow, int hexCol) {
    struct EquipParams { int32_t ItemSlot; uintptr_t TargetActor; } ep{itemSlot, targetActor};
    if (!SendRPC("Server_EquipItem", &ep)) {
        CGRect hex = ScreenLayout::RectForBoardHex(hexRow, hexCol);
        SimulateDrag(ScreenLayout::PointForItemBenchSlot(itemSlot), CGPointMake(CGRectGetMidX(hex), CGRectGetMidY(hex)));
    }
}
static void UseConsumableOnUnit(uintptr_t targetActor, int consumableItemSlot, int hexRow, int hexCol) {
    struct UseParams { int32_t ItemSlot; uintptr_t TargetActor; } up{consumableItemSlot, targetActor};
    if (!SendRPC("Server_EquipItem", &up)) {
        CGRect hex = ScreenLayout::RectForBoardHex(hexRow, hexCol);
        SimulateDrag(ScreenLayout::PointForItemBenchSlot(consumableItemSlot), CGPointMake(CGRectGetMidX(hex), CGRectGetMidY(hex)));
    }
}
static void SwapItemsBetweenUnits(uintptr_t fromActor, uintptr_t toActor) {
    struct SwapParams { uintptr_t SourceActor; uintptr_t DestActor; } sp{fromActor, toActor};
    SendRPC("Server_SwapItems", &sp);
}
static void PickAugment(int idx) {
    int32_t p = idx;
    ScreenLayout::UIAction c[3] = {ScreenLayout::UIAction::AugmentCard0, ScreenLayout::UIAction::AugmentCard1, ScreenLayout::UIAction::AugmentCard2};
    if (!SendRPC("Server_AugmentChoiceSelect", &p)) SimulateTouchAt(ScreenLayout::PointForAction(c[ClampVal(idx, 0, 2)]));
}
static void RerollAugment(int idx) { int32_t p = idx; SendRPC("Server_AugmentChoiceReroll", &p); }
static void PickArmory(int idx) {
    int32_t p = idx;
    ScreenLayout::UIAction a[3] = {ScreenLayout::UIAction::ArmoryCard0, ScreenLayout::UIAction::ArmoryCard1, ScreenLayout::UIAction::ArmoryCard2};
    if (!SendRPC("Server_ArmoryChoiceSelect", &p)) SimulateTouchAt(ScreenLayout::PointForAction(a[ClampVal(idx, 0, 2)]));
}
static void CleanQuitMatch() {
    if (!SendRPC("Server_NotifyCleanQuit", nullptr)) SimulateTouchAt(ScreenLayout::PointForAction(ScreenLayout::UIAction::ExitEliminatedButton));
}
static void ApplyFPSUnlock(float targetFPS) {
    uintptr_t engine = g_SDK.FindFirstObjectOfClass("GameEngine");
    if (!engine) return;
    uintptr_t cls = 0;
    if (UE5::ReadMem(engine + 0x10, cls) && cls) {
        int32_t offFPS = g_SDK.ResolvePropertyOffset(cls, "MaxSmoothedFrameRate");
        if (offFPS > 0) UE5::WriteMem(engine + static_cast<uintptr_t>(offFPS), targetFPS);
    }
}

} // namespace TFTCore

class FinalMasterBrain {
public:
    enum class PositionMode { Standard, AntiAssassin, AntiClumpAoE };
    enum class ForcePosOverride { AutoDetect, ForceStandard, ForceAntiAssassin, ForceAntiClumpAoE };

    enum class AtomicActionType {
        Idle,
        LobbyQueue,
        ExitEliminated,
        CarouselPick,
        ArmoryPick,
        AugmentPick,
        AugmentReroll,
        TransferMagneticRemove,
        TransferSellHolder,
        TransferDirectSwap,
        EquipCompletedItem,
        FieldUnitFromBench,
        SellJunkBenchUnit,
        BuyShopUnit,
        SlamCombineItems,
        BuyXP,
        RollShop
    };

    struct AtomicPlan {
        AtomicActionType action = AtomicActionType::Idle;
        NSString *badge;
        NSString *detail;
        UIColor  *color;
        PositionMode posMode = PositionMode::Standard;
        const FinalCompEntry *pivotTarget = nullptr;
        BOOL highlightShop[5] = {NO,NO,NO,NO,NO};
        int incomePerRound = 5;
        double hitProb = 0.0;

        int argInt0 = 0;
        int argInt1 = 0;
        int argInt2 = 0;
        uintptr_t argPtr0 = 0;
        uintptr_t argPtr1 = 0;
    };

    static int EvaluateUnitCarryPower(const TFTCore::UnitInstance &u, const FinalCompEntry *comp) {
        NSString *name = [NSString stringWithUTF8String:u.champName.c_str()] ?: @"";
        int basePower = u.cost * 100 + u.starLevel * 180;

        for (NSString *c in comp->carries) {
            if ([name localizedCaseInsensitiveContainsString:c]) return basePower + 1000;
        }
        for (NSString *t in comp->mainTanks) {
            if ([name localizedCaseInsensitiveContainsString:t]) return basePower + 850;
        }
        for (NSString *sub in comp->subCarries) {
            if ([name localizedCaseInsensitiveContainsString:sub]) return basePower + 550;
        }
        for (NSString *hold in comp->earlyHoldUnits) {
            if ([name localizedCaseInsensitiveContainsString:hold]) return basePower + 150;
        }
        return basePower;
    }

    static const FinalCompEntry* PickOptimalComp(const TFTCore::LiveState &st, NSArray<NSValue *> *allComps, const FinalCompEntry *current) {
        const FinalCompEntry *best = current;
        double bestScore = -999.0;
        for (NSValue *val in allComps) {
            const FinalCompEntry *c = static_cast<const FinalCompEntry *>([val pointerValue]);
            if (!c) continue;
            double score = (100.0 - c->avgPlace * 15.0) + (c->top4Rate * 0.55);
            for (const auto &item : st.itemBenchItems) {
                NSString *nsItem = [NSString stringWithUTF8String:item.c_str()] ?: @"";
                for (NSString *req in c->itemComponents) {
                    if ([nsItem localizedCaseInsensitiveContainsString:req]) score += 20.0;
                }
            }
            int contested = 0;
            for (NSString *carry in c->carries) {
                const char *utf8Carry = [carry UTF8String];
                if (utf8Carry) {
                    auto it = st.globalPoolTaken.find(utf8Carry);
                    if (it != st.globalPoolTaken.end()) contested += it->second;
                }
            }
            score -= static_cast<double>(contested) * 12.0;
            if (score > bestScore) { bestScore = score; best = c; }
        }
        return best;
    }

    static AtomicPlan BuildFinalPlan(const TFTCore::LiveState &st,
                                     const FinalCompEntry *activeComp,
                                     NSArray<NSValue *> *allComps,
                                     BOOL autoPivotEnabled,
                                     BOOL autoTransferItems,
                                     BOOL autoQueueAndExit,
                                     ForcePosOverride posOverride,
                                     int hpFloor) {
        AtomicPlan p;
        p.badge = @"FINAL TOP 1 • CHỜ TRẬN";
        p.detail = @"Sẵn sàng tự động leo hạng, chuyển đồ & xếp cờ";
        p.color = [UIColor systemCyanColor];

        if (!st.inGame) {
            if (autoQueueAndExit) {
                p.action = AtomicActionType::LobbyQueue;
                p.badge = @"SẢNH • TỰ TÌM & NHẬN TRẬN";
                p.color = [UIColor systemYellowColor];
            }
            return p;
        }

        if (st.isEliminated) {
            if (autoQueueAndExit) {
                p.action = AtomicActionType::ExitEliminated;
                p.badge = @"ĐÃ BỊ LOẠI • TỰ RỜI TRẬN";
                p.color = [UIColor systemRedColor];
            }
            return p;
        }

        if (!activeComp) return p;

        EconomySummary econ = CalcRoundEconomy(st.gold, st.streak);
        p.incomePerRound = econ.totalRoundIncome;

        int avgCost = (activeComp->macro == FinalMacroStyle::Reroll1Cost31) ? 1 :
                      (activeComp->macro == FinalMacroStyle::Reroll2Cost32) ? 2 :
                      (activeComp->macro == FinalMacroStyle::Reroll3Cost41) ? 3 :
                      (activeComp->macro == FinalMacroStyle::Fast9CapBoard) ? 5 : 4;
        const char *carryUtf8 = (activeComp->carries.count > 0) ? [activeComp->carries.firstObject UTF8String] : "";
        int taken = (carryUtf8 && st.globalPoolTaken.count(carryUtf8)) ? st.globalPoolTaken.at(carryUtf8) : 0;
        p.hitProb = CalcShopHitChance(st.level, avgCost, 2, taken) * 100.0;

        if (posOverride == ForcePosOverride::ForceStandard) {
            p.posMode = PositionMode::Standard;
        } else if (posOverride == ForcePosOverride::ForceAntiAssassin) {
            p.posMode = PositionMode::AntiAssassin;
        } else if (posOverride == ForcePosOverride::ForceAntiClumpAoE) {
            p.posMode = PositionMode::AntiClumpAoE;
        } else {
            bool lobbyAssassin = false, lobbyAoE = false;
            for (const auto &e : st.enemies) {
                if (e.hp <= 0) continue;
                if (e.hasAssassins) lobbyAssassin = true;
                if (e.hasHeavyAoE || e.hasZephyrOrShroud) lobbyAoE = true;
            }
            if (lobbyAssassin) p.posMode = PositionMode::AntiAssassin;
            else if (lobbyAoE || st.aliveCount <= 3) p.posMode = PositionMode::AntiClumpAoE;
        }

        if (autoPivotEnabled) {
            if ((st.stage == 3 && st.round == 2) || (st.stage == 4 && st.round == 1)) {
                const FinalCompEntry *cand = PickOptimalComp(st, allComps, activeComp);
                if (cand && cand != activeComp) { p.pivotTarget = cand; activeComp = cand; }
            }
            if (st.stage >= 5 && st.hp >= 55 && st.gold >= 50 && activeComp->macro != FinalMacroStyle::Fast9CapBoard) {
                for (NSValue *v in allComps) {
                    const FinalCompEntry *c = static_cast<const FinalCompEntry *>([v pointerValue]);
                    if (c && c->macro == FinalMacroStyle::Fast9CapBoard) { p.pivotTarget = c; activeComp = c; break; }
                }
            }
        }

        int firstWantedShopIdx = -1;
        for (int i = 0; i < 5; ++i) {
            if (st.shopSlots[i].empty()) continue;
            NSString *slotName = [NSString stringWithUTF8String:st.shopSlots[i].c_str()] ?: @"";
            for (NSString *u in activeComp->coreUnits) {
                if ([slotName localizedCaseInsensitiveContainsString:u]) {
                    p.highlightShop[i] = YES;
                    if (firstWantedShopIdx < 0) firstWantedShopIdx = i;
                    break;
                }
            }
            if (!p.highlightShop[i] && st.stage <= 3) {
                for (NSString *h in activeComp->earlyHoldUnits) {
                    if ([slotName localizedCaseInsensitiveContainsString:h]) {
                        p.highlightShop[i] = YES;
                        if (firstWantedShopIdx < 0) firstWantedShopIdx = i;
                        break;
                    }
                }
            }
        }

        if (st.isCarousel) {
            p.action = AtomicActionType::CarouselPick;
            p.badge = [NSString stringWithFormat:@"ĐI CHỢ %d-%d • NHẶT ĐỒ BiS", st.stage, st.round];
            p.color = [UIColor systemYellowColor];
            p.detail = [NSString stringWithFormat:@"Ưu tiên: %@", [activeComp->itemComponents componentsJoinedByString:@" > "]];
            return p;
        }
        if (st.hasArmoryPopup) {
            p.action = AtomicActionType::ArmoryPick;
            p.badge = @"KHO VŨ KHÍ • CHỌN ĐỒ CHUẨN";
            p.color = [UIColor systemYellowColor];
            return p;
        }
        if (st.augmentChoices.size() == 3) {
            int bestIdx = 0, bestSc = -1;
            for (int i = 0; i < 3; ++i) {
                NSString *aug = [NSString stringWithUTF8String:st.augmentChoices[static_cast<size_t>(i)].c_str()] ?: @"";
                int sc = 50;
                NSArray *godTier = @[@"HedgeFund", @"LevelUp", @"PrismaticTicket", @"PandorasBench", @"TradeSector", @"GoldenGamble", @"BirthdayPresent", @"JeweledLotus", @"Ascension", @"MarchOfProgress", @"BuriedTreasures", @"InvestedPlusPlus", @"TacticiansCrown", @"ItemGrab", @"GoldenRemover"];
                for (NSString *k in godTier) if ([aug containsString:k]) sc += 30;
                for (NSString *u in activeComp->carries) if ([aug localizedCaseInsensitiveContainsString:u]) sc += 40;
                if (sc > bestSc) { bestSc = sc; bestIdx = i; }
            }
            p.argInt0 = bestIdx;
            if (bestSc < 68) {
                p.action = AtomicActionType::AugmentReroll;
                p.badge = [NSString stringWithFormat:@"ĐỔI LÕI #%d (ĐIỂM %d)", bestIdx + 1, bestSc];
                p.color = [UIColor systemOrangeColor];
            } else {
                p.action = AtomicActionType::AugmentPick;
                p.badge = [NSString stringWithFormat:@"CHỌN LÕI #%d (ĐIỂM %d)", bestIdx + 1, bestSc];
                p.color = [UIColor systemGreenColor];
            }
            return p;
        }

        NSDictionary *hexMap = (p.posMode == PositionMode::AntiAssassin) ? activeComp->antiAssassinHex :
                               (p.posMode == PositionMode::AntiClumpAoE) ? activeComp->antiClumpAoEHex : activeComp->standardHex;
        for (size_t b = 0; b < st.myBenchUnits.size(); ++b) {
            NSString *bName = [NSString stringWithUTF8String:st.myBenchUnits[b].champName.c_str()] ?: @"";
            for (NSString *targetKey in hexMap) {
                if ([bName localizedCaseInsensitiveContainsString:targetKey]) {
                    NSArray<NSNumber *> *coord = hexMap[targetKey];
                    if (coord.count >= 2) {
                        p.action = AtomicActionType::FieldUnitFromBench;
                        p.argPtr0 = st.myBenchUnits[b].actorAddr;
                        p.argInt0 = static_cast<int>(b);
                        p.argInt1 = [coord[0] intValue];
                        p.argInt2 = [coord[1] intValue];
                        p.badge = [NSString stringWithFormat:@"ĐƯA %@ LÊN SÂN", targetKey];
                        p.color = [UIColor systemCyanColor];
                        return p;
                    }
                }
            }
        }

        if (autoTransferItems && !st.myBoardUnits.empty()) {
            const TFTCore::UnitInstance *weakHolder = nullptr;
            int weakPwr = 999999;
            const TFTCore::UnitInstance *strongTarget = nullptr;
            int strongPwr = -1;

            for (const auto &bu : st.myBoardUnits) {
                int pwr = EvaluateUnitCarryPower(bu, activeComp);
                if (!bu.equippedItems.empty() && pwr < weakPwr) { weakPwr = pwr; weakHolder = &bu; }
                if (bu.equippedItems.size() < 3 && pwr > strongPwr) { strongPwr = pwr; strongTarget = &bu; }
            }

            if (strongTarget && strongPwr >= 900) {
                NSString *sName = [NSString stringWithUTF8String:strongTarget->champName.c_str()] ?: @"";
                for (size_t idx = 0; idx < st.itemBenchItems.size(); ++idx) {
                    NSString *bagItem = [NSString stringWithUTF8String:st.itemBenchItems[idx].c_str()] ?: @"";
                    for (NSString *cKey in activeComp->bisItems) {
                        if ([sName localizedCaseInsensitiveContainsString:cKey]) {
                            for (NSString *bis in activeComp->bisItems[cKey]) {
                                if ([bagItem localizedCaseInsensitiveContainsString:bis]) {
                                    p.action = AtomicActionType::EquipCompletedItem;
                                    p.argPtr0 = strongTarget->actorAddr;
                                    p.argInt0 = static_cast<int>(idx);
                                    p.argInt1 = strongTarget->row;
                                    p.argInt2 = strongTarget->col;
                                    p.badge = [NSString stringWithFormat:@"LẮP %@ -> %@", bis, cKey];
                                    p.color = [UIColor systemGreenColor];
                                    return p;
                                }
                            }
                        }
                    }
                }
            }

            if (weakHolder && strongTarget && weakHolder->actorAddr != strongTarget->actorAddr && (strongPwr - weakPwr) >= 350) {
                int removerIdx = -1;
                for (size_t idx = 0; idx < st.itemBenchItems.size(); ++idx) {
                    NSString *itName = [NSString stringWithUTF8String:st.itemBenchItems[idx].c_str()] ?: @"";
                    if ([itName localizedCaseInsensitiveContainsString:@"Remover"] || [itName localizedCaseInsensitiveContainsString:@"Magnetic"]) {
                        removerIdx = static_cast<int>(idx);
                        break;
                    }
                }
                if (removerIdx >= 0) {
                    p.action = AtomicActionType::TransferMagneticRemove;
                    p.argPtr0 = weakHolder->actorAddr;
                    p.argInt0 = removerIdx;
                    p.argInt1 = weakHolder->row;
                    p.argInt2 = weakHolder->col;
                    p.badge = @"THÁO ĐỒ BẰNG NAM CHÂM";
                    p.color = [UIColor systemGreenColor];
                    return p;
                }

                NSString *holderName = [NSString stringWithUTF8String:weakHolder->champName.c_str()] ?: @"";
                BOOL isFinalCore = NO;
                for (NSString *core in activeComp->coreUnits) if ([holderName localizedCaseInsensitiveContainsString:core]) isFinalCore = YES;
                BOOL hasBenchCopy = NO;
                for (const auto &bu : st.myBenchUnits) if (bu.champName == weakHolder->champName) { hasBenchCopy = YES; break; }

                if (!isFinalCore || hasBenchCopy || weakHolder->starLevel == 1) {
                    p.action = AtomicActionType::TransferSellHolder;
                    p.argPtr0 = weakHolder->actorAddr;
                    p.badge = @"BÁN TƯỚNG CẦM HỘ -> CHUYỂN ĐỒ";
                    p.color = [UIColor systemGreenColor];
                    return p;
                } else {
                    p.action = AtomicActionType::TransferDirectSwap;
                    p.argPtr0 = weakHolder->actorAddr;
                    p.argPtr1 = strongTarget->actorAddr;
                    p.badge = @"HOÁN ĐỔI ĐỒ CHỦ LỰC";
                    p.color = [UIColor systemGreenColor];
                    return p;
                }
            }
        }

        if (firstWantedShopIdx >= 0 && st.gold >= 1) {
            p.action = AtomicActionType::BuyShopUnit;
            p.argInt0 = firstWantedShopIdx;
            p.badge = [NSString stringWithFormat:@"MUA TƯỚNG Ô #%d", firstWantedShopIdx + 1];
            p.color = [UIColor systemGreenColor];
            return p;
        }

        for (size_t b = 0; b < st.myBenchUnits.size(); ++b) {
            NSString *bName = [NSString stringWithUTF8String:st.myBenchUnits[b].champName.c_str()] ?: @"";
            BOOL keep = NO;
            for (NSString *u in activeComp->coreUnits) if ([bName localizedCaseInsensitiveContainsString:u]) keep = YES;
            if (!keep && st.stage <= 3) {
                for (NSString *h in activeComp->earlyHoldUnits) if ([bName localizedCaseInsensitiveContainsString:h]) keep = YES;
            }
            if (!keep) {
                p.action = AtomicActionType::SellJunkBenchUnit;
                p.argPtr0 = st.myBenchUnits[b].actorAddr;
                p.argInt0 = static_cast<int>(b);
                p.badge = @"BÁN TƯỚNG THỪA HÀNG CHỜ";
                p.color = [UIColor systemOrangeColor];
                return p;
            }
        }

        if (autoTransferItems && st.itemBenchItems.size() >= 2 && !st.myBoardUnits.empty()) {
            const TFTCore::UnitInstance *bestTarget = nullptr;
            int topPwr = -1;
            NSArray<NSString *> *wantedBis = nil;
            for (const auto &bu : st.myBoardUnits) {
                if (bu.equippedItems.size() >= 3) continue;
                int pwr = EvaluateUnitCarryPower(bu, activeComp);
                if (pwr > topPwr) {
                    NSString *uName = [NSString stringWithUTF8String:bu.champName.c_str()] ?: @"";
                    for (NSString *cKey in activeComp->bisItems) {
                        if ([uName localizedCaseInsensitiveContainsString:cKey]) {
                            topPwr = pwr; bestTarget = &bu; wantedBis = activeComp->bisItems[cKey]; break;
                        }
                    }
                }
            }
            if (bestTarget && wantedBis) {
                const auto &recipes = GetItemRecipes();
                for (size_t i = 0; i < st.itemBenchItems.size(); ++i) {
                    for (size_t j = i + 1; j < st.itemBenchItems.size(); ++j) {
                        NSString *cA = [NSString stringWithUTF8String:st.itemBenchItems[i].c_str()] ?: @"";
                        NSString *cB = [NSString stringWithUTF8String:st.itemBenchItems[j].c_str()] ?: @"";
                        for (const auto &rec : recipes) {
                            bool ok = ([cA localizedCaseInsensitiveContainsString:rec.compA] && [cB localizedCaseInsensitiveContainsString:rec.compB]) ||
                                      ([cA localizedCaseInsensitiveContainsString:rec.compB] && [cB localizedCaseInsensitiveContainsString:rec.compA]);
                            if (ok && [wantedBis containsObject:rec.completedItem]) {
                                p.action = AtomicActionType::SlamCombineItems;
                                p.argInt0 = static_cast<int>(i);
                                p.argInt1 = static_cast<int>(j);
                                p.argPtr0 = bestTarget->actorAddr;
                                p.badge = [NSString stringWithFormat:@"GHÉP %@", rec.completedItem];
                                p.color = [UIColor systemGreenColor];
                                return p;
                            }
                        }
                    }
                }
            }
        }

        if (st.hp <= hpFloor || st.hp < 28) {
            p.badge = [NSString stringWithFormat:@"ALL-IN TOP 1 (%d HP)", st.hp];
            p.color = [UIColor systemRedColor];
            if ((activeComp->macro == FinalMacroStyle::Fast8Standard || activeComp->macro == FinalMacroStyle::ChallengerFlex) && st.level < 8 && st.gold >= 32) {
                p.action = AtomicActionType::BuyXP;
                p.detail = @"Đẩy cấp 8 khẩn cấp rồi roll tìm 4 vàng 2★";
            } else if (st.gold >= 2) {
                p.action = AtomicActionType::RollShop;
                p.detail = @"Roll cạn vàng nâng cấp khung giữ mạng";
            }
            return p;
        }

        switch (activeComp->macro) {
            case FinalMacroStyle::Fast9CapBoard:
                if (st.level < 9 && st.gold >= 54) { p.action = AtomicActionType::BuyXP; p.badge = @"FAST 9 • MUA XP (>50G)"; p.color = [UIColor systemPurpleColor]; }
                else if (st.level >= 9 && st.gold > 22) { p.action = AtomicActionType::RollShop; p.badge = @"LV9 • ROLL 5 VÀNG (>20G)"; p.color = [UIColor systemGreenColor]; }
                else { p.badge = @"FAST 9 • TÍCH LÃI 50G"; p.color = [UIColor systemPurpleColor]; }
                break;
            case FinalMacroStyle::Reroll1Cost31:
                if (st.stage == 3 && st.round == 1 && st.gold > 34) { p.action = AtomicActionType::RollShop; p.badge = @"3-1 ROLL XUỐNG 32G"; p.color = [UIColor systemOrangeColor]; }
                else if (st.stage >= 3 && st.gold > 52) { p.action = AtomicActionType::RollShop; p.badge = @"LV5 SLOW ROLL (>50G)"; p.color = [UIColor systemGreenColor]; }
                else { p.badge = @"REROLL 1V • TÍCH LÃI"; p.color = [UIColor systemYellowColor]; }
                break;
            case FinalMacroStyle::Reroll2Cost32:
                if (st.level < 6 && st.gold >= 54) { p.action = AtomicActionType::BuyXP; p.badge = @"LÊN CẤP 6 (>50G)"; p.color = [UIColor systemCyanColor]; }
                else if (st.level >= 6 && st.gold > 52) { p.action = AtomicActionType::RollShop; p.badge = @"LV6 SLOW ROLL 2V (>50G)"; p.color = [UIColor systemGreenColor]; }
                else { p.badge = @"REROLL 2V • TÍCH LÃI"; p.color = [UIColor systemCyanColor]; }
                break;
            case FinalMacroStyle::Reroll3Cost41:
                if (st.level < 7 && st.gold >= 54) { p.action = AtomicActionType::BuyXP; p.badge = @"LÊN CẤP 7 (>50G)"; p.color = [UIColor systemCyanColor]; }
                else if (st.level >= 7 && st.gold > 52) { p.action = AtomicActionType::RollShop; p.badge = @"LV7 SLOW ROLL 3V (>50G)"; p.color = [UIColor systemGreenColor]; }
                else { p.badge = @"REROLL 3V • TÍCH LÃI"; p.color = [UIColor systemCyanColor]; }
                break;
            case FinalMacroStyle::LossStreakCashout:
                if (st.stage <= 3 && st.round <= 3) { p.badge = @"CHUỖI THUA • TÍCH LÃI"; p.color = [UIColor systemPurpleColor]; }
                else if (st.level < 8 && st.gold >= 24) { p.action = AtomicActionType::BuyXP; p.badge = @"NỔ HŨ • ĐẨY CẤP 8"; p.color = [UIColor systemOrangeColor]; }
                else if (st.level >= 8 && st.gold > 22) { p.action = AtomicActionType::RollShop; p.badge = @"LV8 CASHOUT • ROLL (>20G)"; p.color = [UIColor systemGreenColor]; }
                break;
            default:
                if (st.stage == 4 && st.round >= 2 && st.level < 8 && st.gold >= 24) { p.action = AtomicActionType::BuyXP; p.badge = @"4-2 FAST 8 • LÊN CẤP"; p.color = [UIColor systemOrangeColor]; }
                else if (st.level >= 8 && st.gold > 32) { p.action = AtomicActionType::RollShop; p.badge = @"LV8 • ROLL (>30G)"; p.color = [UIColor systemGreenColor]; }
                else if (st.gold >= 54) { p.action = AtomicActionType::BuyXP; p.badge = @"DƯ LÃI 50G • MUA XP"; p.color = [UIColor systemCyanColor]; }
                else { p.badge = [NSString stringWithFormat:@"VÒNG %d-%d • TÍCH LÃI", st.stage, st.round]; p.color = [UIColor systemCyanColor]; }
                break;
        }

        p.detail = [NSString stringWithFormat:@"Thu nhập +%dG/vòng • Trúng/roll ~%.0f%% • Còn %d người",
                    p.incomePerRound, p.hitProb, st.aliveCount];
        return p;
    }
};

@interface SheepctFinalController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) SheepctPassthroughWindow *window;
@property (nonatomic, strong) UIVisualEffectView *topPill;
@property (nonatomic, strong) UILabel *pillTitleLabel;
@property (nonatomic, strong) UILabel *pillSubLabel;
@property (nonatomic, strong) UIButton *autoToggleBtn;
@property (nonatomic, strong) UIButton *posCycleBtn;
@property (nonatomic, strong) UIButton *drawerBtn;

@property (nonatomic, strong) NSArray<UIView *> *shopHighlightBoxes;
@property (nonatomic, strong) NSMutableArray<UIView *> *boardHexMarkers;

@property (nonatomic, strong) UIVisualEffectView *drawerView;
@property (nonatomic, strong) UISegmentedControl *strategyModeSeg;
@property (nonatomic, strong) UISwitch *autoTransferSwitch;
@property (nonatomic, strong) UISwitch *autoQueueSwitch;
@property (nonatomic, strong) UITableView *compTable;
@property (nonatomic, strong) UITextView *intelView;
@property (nonatomic, strong) UILabel *sdkStatusLabel;

@property (nonatomic, strong) NSArray<NSValue *> *allComps;
@property (nonatomic, assign) const FinalCompEntry *activeComp;
@property (nonatomic, assign) BOOL autoPilotEnabled;
@property (nonatomic, assign) BOOL autoPivotEnabled;
@property (nonatomic, assign) BOOL autoTransferItems;
@property (nonatomic, assign) BOOL autoQueueAndExit;
@property (nonatomic, assign) FinalMasterBrain::ForcePosOverride posOverride;
@property (nonatomic, assign) int hpFloor;
@property (nonatomic, strong) NSTimer *loopTimer;
@end

@implementation SheepctFinalController

+ (instancetype)shared {
    static SheepctFinalController *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[self alloc] init]; });
    return s;
}

- (void)boot {
    _hpFloor = 30;
    _autoPivotEnabled = YES;
    _autoTransferItems = YES;
    _autoQueueAndExit = YES;
    _posOverride = FinalMasterBrain::ForcePosOverride::AutoDetect;

    TFTCore::g_SDK.Bootstrap();
    TFTCore::ApplyFPSUnlock(120.0f);

    self.allComps = GetFinalMasterComps();
    self.activeComp = (self.allComps.count > 0) ? static_cast<const FinalCompEntry *>([self.allComps.firstObject pointerValue]) : nullptr;

    [self buildHUD];
    self.loopTimer = [NSTimer scheduledTimerWithTimeInterval:0.70 target:self selector:@selector(tick) userInfo:nil repeats:YES];
}

- (void)buildHUD {
    UIWindowScene *activeScene = nil;
    for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
        if (s.activationState == UISceneActivationStateForegroundActive && [s isKindOfClass:[UIWindowScene class]]) {
            activeScene = (UIWindowScene *)s;
            break;
        }
    }
    self.window = activeScene ? [[SheepctPassthroughWindow alloc] initWithWindowScene:activeScene]
                              : [[SheepctPassthroughWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.windowLevel = UIWindowLevelAlert + 600;
    self.window.backgroundColor = [UIColor clearColor];
    self.view = [[SheepctPassthroughView alloc] initWithFrame:self.window.bounds];
    self.window.rootViewController = self;
    [self.window makeKeyAndVisible];

    ScreenLayout::ViewportMetrics vm = ScreenLayout::ResolveMetrics();

    NSMutableArray *boxes = [NSMutableArray arrayWithCapacity:5];
    for (int i = 0; i < 5; ++i) {
        UIView *box = [[UIView alloc] initWithFrame:ScreenLayout::RectForShopSlot(i)];
        box.userInteractionEnabled = NO;
        box.layer.cornerRadius = 10.0;
        box.layer.borderWidth = 2.5;
        box.layer.borderColor = [UIColor colorWithRed:0.15 green:0.95 blue:0.65 alpha:1.0].CGColor;
        box.backgroundColor = [UIColor colorWithRed:0.15 green:0.95 blue:0.65 alpha:0.12];
        box.hidden = YES;
        [self.view addSubview:box];
        [boxes addObject:box];
    }
    self.shopHighlightBoxes = boxes;
    self.boardHexMarkers = [NSMutableArray array];

    CGFloat pillW = std::min<CGFloat>(510.0, vm.safeCanvas.size.width * 0.72);
    CGFloat pillH = 44.0;
    CGFloat pillX = vm.safeCanvas.origin.x + (vm.safeCanvas.size.width - pillW) * 0.5;
    CGFloat pillY = std::max<CGFloat>(8.0, vm.safeInsets.top + 4.0);

    self.topPill = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    self.topPill.frame = CGRectMake(pillX, pillY, pillW, pillH);
    self.topPill.layer.cornerRadius = 22.0;
    self.topPill.clipsToBounds = YES;
    self.topPill.layer.borderWidth = 1.0;
    self.topPill.layer.borderColor = [UIColor colorWithRed:0.25 green:0.85 blue:0.98 alpha:0.75].CGColor;
    [self.topPill addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onDragPill:)]];
    [self.view addSubview:self.topPill];

    NSString *compName = self.activeComp ? self.activeComp->name : @"TFT Set 18";
    self.pillTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 4, pillW - 210, 18)];
    self.pillTitleLabel.text = [NSString stringWithFormat:@"FINAL V11 • %@", compName];
    self.pillTitleLabel.textColor = [UIColor systemCyanColor];
    self.pillTitleLabel.font = [UIFont boldSystemFontOfSize:11.5];
    [self.topPill.contentView addSubview:self.pillTitleLabel];

    self.pillSubLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 22, pillW - 210, 16)];
    self.pillSubLabel.text = @"120 FPS • Full Auto-Pilot, Chuyển Đồ BiS & Xếp Cờ";
    self.pillSubLabel.textColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    self.pillSubLabel.font = [UIFont systemFontOfSize:10];
    [self.topPill.contentView addSubview:self.pillSubLabel];

    self.posCycleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.posCycleBtn.frame = CGRectMake(pillW - 196, 7, 62, 30);
    self.posCycleBtn.layer.cornerRadius = 15.0;
    self.posCycleBtn.backgroundColor = [UIColor colorWithRed:0.20 green:0.35 blue:0.65 alpha:0.88];
    [self.posCycleBtn setTitle:@"POS:AUTO" forState:UIControlStateNormal];
    self.posCycleBtn.titleLabel.font = [UIFont boldSystemFontOfSize:9.5];
    [self.posCycleBtn addTarget:self action:@selector(onCyclePosMode) forControlEvents:UIControlEventTouchUpInside];
    [self.topPill.contentView addSubview:self.posCycleBtn];

    self.autoToggleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.autoToggleBtn.frame = CGRectMake(pillW - 128, 7, 74, 30);
    self.autoToggleBtn.layer.cornerRadius = 15.0;
    self.autoToggleBtn.backgroundColor = [UIColor colorWithWhite:0.22 alpha:0.9];
    [self.autoToggleBtn setTitle:@"AUTO: OFF" forState:UIControlStateNormal];
    self.autoToggleBtn.titleLabel.font = [UIFont boldSystemFontOfSize:10.5];
    [self.autoToggleBtn addTarget:self action:@selector(onToggleAuto) forControlEvents:UIControlEventTouchUpInside];
    [self.topPill.contentView addSubview:self.autoToggleBtn];

    self.drawerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.drawerBtn.frame = CGRectMake(pillW - 48, 7, 38, 30);
    self.drawerBtn.layer.cornerRadius = 15.0;
    self.drawerBtn.backgroundColor = [UIColor colorWithRed:0.15 green:0.55 blue:0.85 alpha:0.85];
    [self.drawerBtn setTitle:@"☰" forState:UIControlStateNormal];
    self.drawerBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [self.drawerBtn addTarget:self action:@selector(onToggleDrawer) forControlEvents:UIControlEventTouchUpInside];
    [self.topPill.contentView addSubview:self.drawerBtn];

    CGFloat drW = std::min<CGFloat>(400.0, vm.safeCanvas.size.width - 20.0);
    CGFloat drH = std::min<CGFloat>(314.0, vm.safeCanvas.size.height - 54.0);
    self.drawerView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThickMaterialDark]];
    self.drawerView.frame = CGRectMake(pillX + (pillW - drW) * 0.5, pillY + pillH + 8.0, drW, drH);
    self.drawerView.layer.cornerRadius = 16.0;
    self.drawerView.clipsToBounds = YES;
    self.drawerView.layer.borderWidth = 1.0;
    self.drawerView.layer.borderColor = [UIColor colorWithWhite:0.28 alpha:1.0].CGColor;
    self.drawerView.hidden = YES;
    [self.view addSubview:self.drawerView];

    self.strategyModeSeg = [[UISegmentedControl alloc] initWithItems:@[@"GM Auto-Pivot + Exodia", @"Khóa Bài Chọn"]];
    self.strategyModeSeg.frame = CGRectMake(10, 8, drW - 20, 26);
    self.strategyModeSeg.selectedSegmentIndex = 0;
    [self.strategyModeSeg addTarget:self action:@selector(onStrategyModeChanged) forControlEvents:UIControlEventValueChanged];
    [self.drawerView.contentView addSubview:self.strategyModeSeg];

    UILabel *slamLbl = [[UILabel alloc] initWithFrame:CGRectMake(12, 38, 130, 24)];
    slamLbl.text = @"Auto Chuyển/Ghép Đồ:";
    slamLbl.textColor = [UIColor whiteColor];
    slamLbl.font = [UIFont systemFontOfSize:10.5];
    [self.drawerView.contentView addSubview:slamLbl];

    self.autoTransferSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(140, 35, 51, 31)];
    self.autoTransferSwitch.on = YES;
    self.autoTransferSwitch.transform = CGAffineTransformMakeScale(0.75, 0.75);
    [self.autoTransferSwitch addTarget:self action:@selector(onSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.drawerView.contentView addSubview:self.autoTransferSwitch];

    UILabel *queueLbl = [[UILabel alloc] initWithFrame:CGRectMake(200, 38, 120, 24)];
    queueLbl.text = @"Auto Tìm/Thoát:";
    queueLbl.textColor = [UIColor whiteColor];
    queueLbl.font = [UIFont systemFontOfSize:10.5];
    [self.drawerView.contentView addSubview:queueLbl];

    self.autoQueueSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(315, 35, 51, 31)];
    self.autoQueueSwitch.on = YES;
    self.autoQueueSwitch.transform = CGAffineTransformMakeScale(0.75, 0.75);
    [self.autoQueueSwitch addTarget:self action:@selector(onSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.drawerView.contentView addSubview:self.autoQueueSwitch];

    self.compTable = [[UITableView alloc] initWithFrame:CGRectMake(8, 68, drW - 16, 138) style:UITableViewStylePlain];
    self.compTable.backgroundColor = [UIColor clearColor];
    self.compTable.separatorColor = [UIColor colorWithWhite:0.24 alpha:1.0];
    self.compTable.dataSource = self;
    self.compTable.delegate = self;
    [self.drawerView.contentView addSubview:self.compTable];

    self.intelView = [[UITextView alloc] initWithFrame:CGRectMake(8, 210, drW - 16, 68)];
    self.intelView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.78];
    self.intelView.textColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    self.intelView.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular];
    self.intelView.layer.cornerRadius = 8.0;
    self.intelView.editable = NO;
    [self updateIntelText:FinalMasterBrain::PositionMode::Standard];
    [self.drawerView.contentView addSubview:self.intelView];

    auto &sdk = TFTCore::g_SDK;
    self.sdkStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, drH - 28, drW - 20, 22)];
    self.sdkStatusLabel.text = [NSString stringWithFormat:@"UE5 SDK: GWorld +0x%lx | GObj +0x%lx | FName +0x%lx | PE[%d]",
                                sdk.GWorldPtr ? sdk.GWorldPtr - sdk.img.base : 0,
                                sdk.GUObjectArrayAddr ? sdk.GUObjectArrayAddr - sdk.img.base : 0,
                                sdk.FNamePoolAddr ? sdk.FNamePoolAddr - sdk.img.base : 0,
                                sdk.ProcessEventVTableIdx];
    self.sdkStatusLabel.textColor = [UIColor lightGrayColor];
    self.sdkStatusLabel.font = [UIFont monospacedSystemFontOfSize:9.5 weight:UIFontWeightRegular];
    [self.drawerView.contentView addSubview:self.sdkStatusLabel];

    [self renderBoardMarkersForMode:FinalMasterBrain::PositionMode::Standard];
}

- (void)updateIntelText:(FinalMasterBrain::PositionMode)mode {
    if (!self.activeComp) return;
    NSString *modeStr = (mode == FinalMasterBrain::PositionMode::AntiAssassin) ? @"BO GÓC CHỐNG SÁT THỦ" :
                        (mode == FinalMasterBrain::PositionMode::AntiClumpAoE) ? @"DÀN NGANG CHỐNG AOE / 1V1" : @"ĐỘI HÌNH CHUẨN";
    self.intelView.text = [NSString stringWithFormat:@"[%@] %@ (Top4: %.1f%% | Avg: %.2f)\nĐồ BiS: %@\nThế trận: %@",
                           self.activeComp->tier, self.activeComp->name, self.activeComp->top4Rate, self.activeComp->avgPlace,
                           self.activeComp->bisItems, modeStr];
}

- (void)renderBoardMarkersForMode:(FinalMasterBrain::PositionMode)mode {
    for (UIView *m in self.boardHexMarkers) [m removeFromSuperview];
    [self.boardHexMarkers removeAllObjects];
    if (!self.activeComp) return;

    NSDictionary *layout = (mode == FinalMasterBrain::PositionMode::AntiAssassin) ? self.activeComp->antiAssassinHex :
                           (mode == FinalMasterBrain::PositionMode::AntiClumpAoE) ? self.activeComp->antiClumpAoEHex : self.activeComp->standardHex;

    [layout enumerateKeysAndObjectsUsingBlock:^(NSString *unitName, NSArray<NSNumber *> *coord, BOOL *stop) {
        if (coord.count < 2 || !unitName) return;
        CGRect hexRect = ScreenLayout::RectForBoardHex([coord[0] intValue], [coord[1] intValue]);
        UIView *marker = [[UIView alloc] initWithFrame:hexRect];
        marker.userInteractionEnabled = NO;
        marker.layer.cornerRadius = hexRect.size.width * 0.5;
        marker.layer.borderWidth = 1.5;
        BOOL isCarry = [self.activeComp->carries containsObject:unitName];
        marker.layer.borderColor = (isCarry ? [UIColor systemYellowColor] : [UIColor systemCyanColor]).CGColor;
        marker.backgroundColor = [(isCarry ? [UIColor systemYellowColor] : [UIColor systemCyanColor]) colorWithAlphaComponent:0.16];
        marker.hidden = self.drawerView.hidden;

        NSUInteger maxLen = std::min<NSUInteger>(4, unitName.length);
        UILabel *lbl = [[UILabel alloc] initWithFrame:marker.bounds];
        lbl.text = [unitName substringToIndex:maxLen];
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.textColor = [UIColor whiteColor];
        lbl.font = [UIFont boldSystemFontOfSize:9];
        [marker addSubview:lbl];

        [self.view addSubview:marker];
        [self.boardHexMarkers addObject:marker];
    }];
}

- (void)tick {
    TFTCore::LiveState st = TFTCore::PollLiveState();
    FinalMasterBrain::AtomicPlan plan = FinalMasterBrain::BuildFinalPlan(
        st, self.activeComp, self.allComps, self.autoPivotEnabled, self.autoTransferItems, self.autoQueueAndExit, self.posOverride, self.hpFloor
    );

    if (plan.pivotTarget && plan.pivotTarget != self.activeComp) {
        self.activeComp = plan.pivotTarget;
        [self.compTable reloadData];
        [self renderBoardMarkersForMode:plan.posMode];
        [self updateIntelText:plan.posMode];
    }

    NSString *curCompName = self.activeComp ? self.activeComp->name : @"Set 18";
    self.pillTitleLabel.text = [NSString stringWithFormat:@"%@ • %d-%d | %dHP | %dG | Lv%d",
                                plan.badge, st.stage, st.round, st.hp, st.gold, st.level];
    self.pillTitleLabel.textColor = plan.color;
    self.pillSubLabel.text = [NSString stringWithFormat:@"[%@] %@", curCompName, plan.detail];

    for (int i = 0; i < 5; ++i) {
        self.shopHighlightBoxes[i].frame = ScreenLayout::RectForShopSlot(i);
        self.shopHighlightBoxes[i].hidden = !plan.highlightShop[i];
    }

    if (!self.autoPilotEnabled) return;

    switch (plan.action) {
        case FinalMasterBrain::AtomicActionType::LobbyQueue:
            TFTCore::SimulateTouchAt(ScreenLayout::PointForAction(ScreenLayout::UIAction::FindMatchButton));
            TFTCore::SimulateTouchAt(ScreenLayout::PointForAction(ScreenLayout::UIAction::AcceptMatchButton));
            break;
        case FinalMasterBrain::AtomicActionType::ExitEliminated:
            TFTCore::CleanQuitMatch();
            break;
        case FinalMasterBrain::AtomicActionType::CarouselPick:
            TFTCore::SimulateTouchAt(ScreenLayout::PointForAction(ScreenLayout::UIAction::CarouselPriority0));
            break;
        case FinalMasterBrain::AtomicActionType::ArmoryPick:
            TFTCore::PickArmory(0);
            break;
        case FinalMasterBrain::AtomicActionType::AugmentPick:
            TFTCore::PickAugment(plan.argInt0);
            break;
        case FinalMasterBrain::AtomicActionType::AugmentReroll:
            TFTCore::RerollAugment(plan.argInt0);
            break;
        case FinalMasterBrain::AtomicActionType::TransferMagneticRemove:
            TFTCore::UseConsumableOnUnit(plan.argPtr0, plan.argInt0, plan.argInt1, plan.argInt2);
            break;
        case FinalMasterBrain::AtomicActionType::TransferSellHolder:
            TFTCore::SellUnit(plan.argPtr0, 0);
            break;
        case FinalMasterBrain::AtomicActionType::TransferDirectSwap:
            TFTCore::SwapItemsBetweenUnits(plan.argPtr0, plan.argPtr1);
            break;
        case FinalMasterBrain::AtomicActionType::EquipCompletedItem:
            TFTCore::EquipSingleItem(plan.argPtr0, plan.argInt0, plan.argInt1, plan.argInt2);
            break;
        case FinalMasterBrain::AtomicActionType::FieldUnitFromBench:
            TFTCore::MoveUnitToHex(plan.argPtr0, plan.argInt0, plan.argInt1, plan.argInt2);
            break;
        case FinalMasterBrain::AtomicActionType::SellJunkBenchUnit:
            TFTCore::SellUnit(plan.argPtr0, plan.argInt0);
            break;
        case FinalMasterBrain::AtomicActionType::BuyShopUnit:
            TFTCore::BuySlot(plan.argInt0);
            break;
        case FinalMasterBrain::AtomicActionType::SlamCombineItems:
            TFTCore::CombineAndEquip(plan.argPtr0, plan.argInt0, plan.argInt1);
            break;
        case FinalMasterBrain::AtomicActionType::BuyXP:
            TFTCore::BuyXP();
            break;
        case FinalMasterBrain::AtomicActionType::RollShop:
            TFTCore::RollShop();
            break;
        case FinalMasterBrain::AtomicActionType::Idle:
        default:
            break;
    }
}

- (void)onCyclePosMode {
    int next = (static_cast<int>(self.posOverride) + 1) % 4;
    self.posOverride = static_cast<FinalMasterBrain::ForcePosOverride>(next);
    NSString *title = @"POS:AUTO";
    FinalMasterBrain::PositionMode viewMode = FinalMasterBrain::PositionMode::Standard;
    if (self.posOverride == FinalMasterBrain::ForcePosOverride::ForceStandard) {
        title = @"POS:STD";
        viewMode = FinalMasterBrain::PositionMode::Standard;
    } else if (self.posOverride == FinalMasterBrain::ForcePosOverride::ForceAntiAssassin) {
        title = @"POS:ASN";
        viewMode = FinalMasterBrain::PositionMode::AntiAssassin;
    } else if (self.posOverride == FinalMasterBrain::ForcePosOverride::ForceAntiClumpAoE) {
        title = @"POS:1V1";
        viewMode = FinalMasterBrain::PositionMode::AntiClumpAoE;
    }
    [self.posCycleBtn setTitle:title forState:UIControlStateNormal];
    [self renderBoardMarkersForMode:viewMode];
    [self updateIntelText:viewMode];
}

- (void)onToggleAuto {
    self.autoPilotEnabled = !self.autoPilotEnabled;
    if (self.autoPilotEnabled) {
        self.autoToggleBtn.backgroundColor = [UIColor systemGreenColor];
        [self.autoToggleBtn setTitle:@"AUTO: ON" forState:UIControlStateNormal];
        [self.autoToggleBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    } else {
        self.autoToggleBtn.backgroundColor = [UIColor colorWithWhite:0.22 alpha:0.9];
        [self.autoToggleBtn setTitle:@"AUTO: OFF" forState:UIControlStateNormal];
        [self.autoToggleBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}

- (void)onToggleDrawer {
    self.drawerView.hidden = !self.drawerView.hidden;
    for (UIView *m in self.boardHexMarkers) m.hidden = self.drawerView.hidden;
}

- (void)onStrategyModeChanged {
    self.autoPivotEnabled = (self.strategyModeSeg.selectedSegmentIndex == 0);
}

- (void)onSwitchChanged:(UISwitch *)sw {
    if (sw == self.autoTransferSwitch) self.autoTransferItems = sw.isOn;
    else if (sw == self.autoQueueSwitch) self.autoQueueAndExit = sw.isOn;
}

- (void)onDragPill:(UIPanGestureRecognizer *)g {
    CGPoint d = [g translationInView:self.view];
    self.topPill.center = CGPointMake(self.topPill.center.x + d.x, self.topPill.center.y + d.y);
    self.drawerView.center = CGPointMake(self.drawerView.center.x + d.x, self.drawerView.center.y + d.y);
    [g setTranslation:CGPointZero inView:self.view];
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section { return static_cast<NSInteger>(self.allComps.count); }
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.backgroundColor = [UIColor clearColor];
    const FinalCompEntry *c = static_cast<const FinalCompEntry *>([self.allComps[static_cast<NSUInteger>(ip.row)] pointerValue]);
    if (!c) return cell;
    BOOL sel = (c == self.activeComp);
    cell.textLabel.text = [NSString stringWithFormat:@"%@ [%@] %@", sel ? @"★" : @"•", c->tier, c->name];
    cell.textLabel.textColor = sel ? [UIColor systemCyanColor] : [UIColor whiteColor];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:11.5];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Top4: %.1f%% | Avg: %.2f | Đồ: %@",
                                 c->top4Rate, c->avgPlace, [c->itemComponents componentsJoinedByString:@", "]];
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
    return cell;
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    self.activeComp = static_cast<const FinalCompEntry *>([self.allComps[static_cast<NSUInteger>(ip.row)] pointerValue]);
    self.strategyModeSeg.selectedSegmentIndex = 1;
    self.autoPivotEnabled = NO;
    [self.compTable reloadData];
    [self renderBoardMarkersForMode:FinalMasterBrain::PositionMode::Standard];
    [self updateIntelText:FinalMasterBrain::PositionMode::Standard];
}

@end

__attribute__((constructor))
static void InitSheepctFinal() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[SheepctFinalController shared] boot];
    });
}
