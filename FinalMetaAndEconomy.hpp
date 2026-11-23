// language: C++, file: FinalMetaAndEconomy.hpp, target: iOS ARM64 (TFT v18.7.5951209 - Final Meta & Economy)
#pragma once
#import <Foundation/Foundation.h>
#include <vector>
#include <string>
#include <algorithm>
#include <cmath>

struct ItemRecipe {
    NSString *compA;
    NSString *compB;
    NSString *completedItem;
    int priority;
};

inline const std::vector<ItemRecipe>& GetItemRecipes() {
    static std::vector<ItemRecipe> recipes = {
        {@"TearOfTheGoddess", @"TearOfTheGoddess", @"BlueBuff", 95},
        {@"BFSword", @"TearOfTheGoddess", @"SpearOfShojin", 94},
        {@"NeedlesslyLargeRod", @"SparringGloves", @"JeweledGauntlet", 96},
        {@"RecurveBow", @"NeedlesslyLargeRod", @"GuinsoosRageblade", 98},
        {@"BFSword", @"SparringGloves", @"InfinityEdge", 95},
        {@"BFSword", @"NegatronCloak", @"Bloodthirster", 94},
        {@"BFSword", @"ChainVest", @"EdgeOfNight", 92},
        {@"BFSword", @"GiantsBelt", @"SteraksGage", 90},
        {@"ChainVest", @"NegatronCloak", @"GargoyleStoneplate", 97},
        {@"GiantsBelt", @"GiantsBelt", @"WarmogsArmor", 95},
        {@"NegatronCloak", @"GiantsBelt", @"SpiritVisage", 89},
        {@"BFSword", @"RecurveBow", @"GiantSlayer", 93},
        {@"RecurveBow", @"SparringGloves", @"LastWhisper", 91},
        {@"BFSword", @"NeedlesslyLargeRod", @"HextechGunblade", 92},
        {@"ChainVest", @"RecurveBow", @"TitansResolve", 93},
        {@"NeedlesslyLargeRod", @"GiantsBelt", @"Morellonomicon", 90},
        {@"NeedlesslyLargeRod", @"NegatronCloak", @"IonicSpark", 88},
        {@"ChainVest", @"GiantsBelt", @"SunfireCape", 91},
        {@"ChainVest", @"TearOfTheGoddess", @"ProtectorsVow", 89},
        {@"NeedlesslyLargeRod", @"RecurveBow", @"NashorsTooth", 92},
        {@"SparringGloves", @"TearOfTheGoddess", @"HandOfJustice", 88},
        {@"ChainVest", @"ChainVest", @"BrambleVest", 87},
        {@"NegatronCloak", @"NegatronCloak", @"DragonsClaw", 87},
        {@"GiantsBelt", @"NegatronCloak", @"Evenshroud", 89}
    };
    return recipes;
}

struct EconomySummary {
    int baseGold;
    int interestGold;
    int streakGold;
    int totalRoundIncome;
    int goldToNextInterest;
};

inline EconomySummary CalcRoundEconomy(int gold, int streak) {
    EconomySummary s{};
    s.baseGold = 5;
    int g = std::max(0, gold);
    s.interestGold = std::min(5, g / 10);
    int absStreak = std::abs(streak);
    if (absStreak >= 5) s.streakGold = 3;
    else if (absStreak >= 4) s.streakGold = 2;
    else if (absStreak >= 2) s.streakGold = 1;
    else s.streakGold = 0;

    s.totalRoundIncome = s.baseGold + s.interestGold + s.streakGold;
    int nextTier = std::min(50, ((g / 10) + 1) * 10);
    s.goldToNextInterest = (g >= 50) ? 0 : (nextTier - g);
    return s;
}

inline double CalcShopHitChance(int level, int cost, int copiesWanted, int copiesTaken) {
    static constexpr double kOdds[11][6] = {
        {0, 0,    0,    0,    0,    0},
        {0, 1.00, 0.00, 0.00, 0.00, 0.00},
        {0, 1.00, 0.00, 0.00, 0.00, 0.00},
        {0, 0.75, 0.25, 0.00, 0.00, 0.00},
        {0, 0.55, 0.30, 0.15, 0.00, 0.00},
        {0, 0.45, 0.33, 0.20, 0.02, 0.00},
        {0, 0.30, 0.40, 0.25, 0.05, 0.00},
        {0, 0.19, 0.30, 0.40, 0.10, 0.01},
        {0, 0.18, 0.25, 0.32, 0.22, 0.03},
        {0, 0.15, 0.20, 0.25, 0.30, 0.10},
        {0, 0.05, 0.10, 0.20, 0.40, 0.25}
    };
    static constexpr int kPoolSize[6] = {0, 22, 20, 17, 10, 9};
    int lvl = std::max(1, std::min(10, level));
    int c   = std::max(1, std::min(5, cost));
    double slotOdd = kOdds[lvl][c];
    if (slotOdd <= 0.0) return 0.0;

    int pool = kPoolSize[c];
    int rem = std::max(0, pool - copiesTaken);
    double share = (pool > 0) ? (static_cast<double>(rem) / static_cast<double>(pool * 12)) : 0.0;
    double perSlot = slotOdd * std::min(1.0, share * 12.0);
    double miss5 = std::pow(std::max(0.0, 1.0 - perSlot), 5.0);
    double hit = (1.0 - miss5) * std::min(3.0, static_cast<double>(std::max(1, copiesWanted)));
    return std::min(0.99, std::max(0.0, hit));
}

enum class FinalMacroStyle {
    ChallengerFlex,
    LossStreakCashout,
    Reroll1Cost31,
    Reroll2Cost32,
    Reroll3Cost41,
    Fast8Standard,
    Fast9CapBoard
};

struct FinalCompEntry {
    NSString *id;
    NSString *name;
    NSString *tier;
    FinalMacroStyle macro;
    double avgPlace;
    double top4Rate;
    NSArray<NSString *> *coreUnits;
    NSArray<NSString *> *earlyHoldUnits;
    NSArray<NSString *> *carries;
    NSArray<NSString *> *subCarries;
    NSArray<NSString *> *mainTanks;
    NSArray<NSString *> *itemComponents;
    NSDictionary<NSString *, NSArray<NSString *> *> *bisItems;
    NSDictionary<NSString *, NSArray<NSNumber *> *> *standardHex;
    NSDictionary<NSString *, NSArray<NSNumber *> *> *antiAssassinHex;
    NSDictionary<NSString *, NSArray<NSNumber *> *> *antiClumpAoEHex;
};

inline NSArray<NSValue *> *GetFinalMasterComps() {
    static std::vector<FinalCompEntry> db = {
        {
            @"426045", @"Nidalee Sivir Adaptor Fast 8", @"S+", FinalMacroStyle::Fast8Standard, 3.78, 72.4,
            @[@"Nidalee", @"Sivir", @"Lillia", @"Rakan", @"Shen", @"Amumu", @"KogMaw", @"Sett"],
            @[@"KogMaw", @"Vi", @"Warwick"],
            @[@"Nidalee", @"Sivir"],
            @[@"Sett", @"KogMaw"],
            @[@"Amumu", @"Shen", @"Rakan"],
            @[@"BFSword", @"RecurveBow", @"ChainVest", @"NegatronCloak"],
            @{@"Nidalee": @[@"Bloodthirster", @"EdgeOfNight", @"SteraksGage"], @"Sivir": @[@"InfinityEdge", @"BlueBuff", @"Deathblade"], @"Amumu": @[@"GargoyleStoneplate", @"WarmogsArmor", @"SpiritVisage"]},
            @{@"Amumu": @[@0,@3], @"Shen": @[@0,@2], @"Rakan": @[@0,@4], @"Sett": @[@0,@5], @"Nidalee": @[@1,@3], @"Lillia": @[@2,@1], @"Sivir": @[@3,@0], @"KogMaw": @[@3,@6]},
            @{@"Amumu": @[@0,@3], @"Shen": @[@2,@0], @"Rakan": @[@2,@6], @"Sett": @[@0,@4], @"Nidalee": @[@1,@3], @"Lillia": @[@3,@2], @"Sivir": @[@3,@0], @"KogMaw": @[@3,@6]},
            @{@"Amumu": @[@0,@1], @"Shen": @[@0,@3], @"Rakan": @[@0,@5], @"Sett": @[@0,@6], @"Nidalee": @[@1,@2], @"Lillia": @[@2,@4], @"Sivir": @[@3,@0], @"KogMaw": @[@3,@6]}
        },
        {
            @"426054", @"Elise Morgana Coven", @"S+", FinalMacroStyle::Fast8Standard, 3.97, 64.5,
            @[@"Elise", @"Morgana", @"Cassiopeia", @"Alune", @"Diana", @"Taric", @"ElderDragon"],
            @[@"Cassiopeia", @"Zyra", @"Soraka"],
            @[@"Elise", @"Morgana"],
            @[@"ElderDragon", @"Alune"],
            @[@"Taric", @"Diana"],
            @[@"NeedlesslyLargeRod", @"TearOfTheGoddess", @"RecurveBow", @"ChainVest"],
            @{@"Elise": @[@"GuinsoosRageblade", @"TitansResolve", @"GargoyleStoneplate"], @"Morgana": @[@"JeweledGauntlet", @"Morellonomicon", @"VoidStaff"], @"Taric": @[@"WarmogsArmor", @"GargoyleStoneplate", @"SunfireCape"]},
            @{@"Taric": @[@0,@3], @"Diana": @[@0,@2], @"Elise": @[@0,@4], @"Morgana": @[@3,@0], @"Cassiopeia": @[@3,@1], @"Alune": @[@3,@5], @"ElderDragon": @[@3,@6]},
            @{@"Taric": @[@0,@3], @"Diana": @[@2,@0], @"Elise": @[@1,@4], @"Morgana": @[@3,@0], @"Cassiopeia": @[@3,@1], @"Alune": @[@3,@5], @"ElderDragon": @[@2,@6]},
            @{@"Taric": @[@0,@1], @"Diana": @[@0,@5], @"Elise": @[@0,@3], @"Morgana": @[@3,@0], @"Cassiopeia": @[@3,@2], @"Alune": @[@3,@4], @"ElderDragon": @[@3,@6]}
        },
        {
            @"426053", @"Aphelios Lunar Exodia Fast 9", @"S+", FinalMacroStyle::Fast9CapBoard, 3.51, 64.0,
            @[@"Aphelios", @"Alune", @"Diana", @"Kayle", @"Leona", @"Maokai", @"Taric", @"Sejuani", @"Sett"],
            @[@"Kayle", @"Ashe", @"Sivir", @"Leona"],
            @[@"Aphelios", @"Alune"],
            @[@"Sett", @"Kayle"],
            @[@"Maokai", @"Taric", @"Sejuani"],
            @[@"RecurveBow", @"BFSword", @"SparringGloves", @"TearOfTheGoddess"],
            @{@"Aphelios": @[@"GuinsoosRageblade", @"InfinityEdge", @"GiantSlayer"], @"Alune": @[@"BlueBuff", @"JeweledGauntlet", @"SpearOfShojin"], @"Maokai": @[@"GargoyleStoneplate", @"WarmogsArmor", @"DragonsClaw"]},
            @{@"Maokai": @[@0,@3], @"Leona": @[@0,@2], @"Taric": @[@0,@4], @"Sejuani": @[@0,@1], @"Diana": @[@0,@5], @"Aphelios": @[@3,@6], @"Alune": @[@3,@5], @"Kayle": @[@3,@0]},
            @{@"Maokai": @[@0,@3], @"Leona": @[@2,@5], @"Taric": @[@2,@6], @"Sejuani": @[@0,@2], @"Diana": @[@1,@4], @"Aphelios": @[@3,@6], @"Alune": @[@3,@4], @"Kayle": @[@3,@0]},
            @{@"Maokai": @[@0,@1], @"Leona": @[@0,@3], @"Taric": @[@0,@5], @"Sejuani": @[@0,@6], @"Diana": @[@1,@2], @"Aphelios": @[@3,@6], @"Alune": @[@3,@3], @"Kayle": @[@3,@0]}
        },
        {
            @"426044", @"Veigar Sprykin Reroll", @"S", FinalMacroStyle::Reroll1Cost31, 4.12, 59.2,
            @[@"Veigar", @"Kobuko", @"Rammus", @"RekSai", @"Teemo", @"Tristana", @"Fiddlesticks"],
            @[@"Poppy", @"Ziggs"],
            @[@"Veigar", @"Teemo"],
            @[@"Tristana", @"Fiddlesticks"],
            @[@"Rammus", @"RekSai", @"Kobuko"],
            @[@"TearOfTheGoddess", @"NeedlesslyLargeRod", @"GiantsBelt", @"ChainVest"],
            @{@"Veigar": @[@"BlueBuff", @"JeweledGauntlet", @"HextechGunblade"], @"RekSai": @[@"GargoyleStoneplate", @"WarmogsArmor", @"SpiritVisage"]},
            @{@"Rammus": @[@0,@3], @"RekSai": @[@0,@2], @"Kobuko": @[@0,@4], @"Fiddlesticks": @[@1,@3], @"Veigar": @[@3,@0], @"Teemo": @[@3,@1], @"Tristana": @[@3,@6]},
            @{@"Rammus": @[@0,@3], @"RekSai": @[@2,@0], @"Kobuko": @[@2,@1], @"Fiddlesticks": @[@1,@4], @"Veigar": @[@3,@0], @"Teemo": @[@3,@2], @"Tristana": @[@3,@6]},
            @{@"Rammus": @[@0,@1], @"RekSai": @[@0,@3], @"Kobuko": @[@0,@5], @"Fiddlesticks": @[@1,@4], @"Veigar": @[@3,@0], @"Teemo": @[@3,@3], @"Tristana": @[@3,@6]}
        },
        {
            @"426048", @"Tristana Fae Reroll", @"S", FinalMacroStyle::Reroll3Cost41, 3.93, 58.8,
            @[@"Tristana", @"Lillia", @"Rakan", @"Rammus", @"Sivir", @"Xayah", @"Kobuko"],
            @[@"Sivir", @"Kobuko", @"Ashe"],
            @[@"Tristana", @"Xayah"],
            @[@"Sivir", @"Lillia"],
            @[@"Rammus", @"Rakan"],
            @[@"RecurveBow", @"BFSword", @"SparringGloves", @"GiantsBelt"],
            @{@"Tristana": @[@"GuinsoosRageblade", @"GiantSlayer", @"HextechGunblade"], @"Rammus": @[@"GargoyleStoneplate", @"WarmogsArmor", @"SpiritVisage"]},
            @{@"Rammus": @[@0,@3], @"Kobuko": @[@0,@2], @"Rakan": @[@0,@4], @"Lillia": @[@1,@3], @"Tristana": @[@3,@6], @"Xayah": @[@3,@5], @"Sivir": @[@3,@0]},
            @{@"Rammus": @[@0,@3], @"Kobuko": @[@2,@5], @"Rakan": @[@2,@6], @"Lillia": @[@1,@3], @"Tristana": @[@3,@6], @"Xayah": @[@3,@4], @"Sivir": @[@3,@0]},
            @{@"Rammus": @[@0,@1], @"Kobuko": @[@0,@3], @"Rakan": @[@0,@5], @"Lillia": @[@1,@2], @"Tristana": @[@3,@6], @"Xayah": @[@3,@3], @"Sivir": @[@3,@0]}
        },
        {
            @"426052", @"Ahri Spellweaver Flex", @"S", FinalMacroStyle::ChallengerFlex, 3.52, 60.3,
            @[@"Ahri", @"Alune", @"Diana", @"Lillia", @"Rakan", @"Yorick", @"Karma", @"Fiddlesticks"],
            @[@"Karma", @"Lux", @"Zyra"],
            @[@"Ahri", @"Alune"],
            @[@"Karma", @"Fiddlesticks"],
            @[@"Yorick", @"Rakan", @"Diana"],
            @[@"SparringGloves", @"NeedlesslyLargeRod", @"RecurveBow", @"TearOfTheGoddess"],
            @{@"Ahri": @[@"JeweledGauntlet", @"NashorsTooth", @"GiantSlayer"], @"Alune": @[@"Morellonomicon", @"VoidStaff", @"BlueBuff"]},
            @{@"Rakan": @[@0,@3], @"Yorick": @[@0,@2], @"Diana": @[@0,@4], @"Lillia": @[@1,@3], @"Ahri": @[@3,@0], @"Alune": @[@3,@1], @"Karma": @[@3,@6]},
            @{@"Rakan": @[@0,@3], @"Yorick": @[@2,@0], @"Diana": @[@2,@1], @"Lillia": @[@1,@3], @"Ahri": @[@3,@0], @"Alune": @[@3,@2], @"Karma": @[@3,@6]},
            @{@"Rakan": @[@0,@1], @"Yorick": @[@0,@3], @"Diana": @[@0,@5], @"Lillia": @[@1,@4], @"Ahri": @[@3,@0], @"Alune": @[@3,@3], @"Karma": @[@3,@6]}
        },
        {
            @"426057", @"KhaZix Rengar Cashout Assassin", @"S", FinalMacroStyle::LossStreakCashout, 4.10, 71.4,
            @[@"KhaZix", @"Rengar", @"Aphelios", @"Diana", @"Rakan", @"Rammus", @"Fiddlesticks"],
            @[@"Warwick", @"Gromp", @"Murkwolf"],
            @[@"KhaZix", @"Rengar"],
            @[@"Aphelios", @"Fiddlesticks"],
            @[@"Rammus", @"Rakan"],
            @[@"BFSword", @"SparringGloves", @"ChainVest", @"NeedlesslyLargeRod"],
            @{@"KhaZix": @[@"EdgeOfNight", @"HandOfJustice", @"InfinityEdge"], @"Rengar": @[@"Bloodthirster", @"SteraksGage", @"TitansResolve"]},
            @{@"Rammus": @[@0,@3], @"Rakan": @[@0,@2], @"Diana": @[@0,@4], @"KhaZix": @[@3,@1], @"Rengar": @[@3,@5], @"Aphelios": @[@3,@3]},
            @{@"Rammus": @[@0,@3], @"Rakan": @[@0,@2], @"Diana": @[@0,@4], @"KhaZix": @[@3,@0], @"Rengar": @[@3,@6], @"Aphelios": @[@3,@3]},
            @{@"Rammus": @[@0,@1], @"Rakan": @[@0,@5], @"Diana": @[@0,@3], @"KhaZix": @[@3,@0], @"Rengar": @[@3,@6], @"Aphelios": @[@3,@3]}
        }
    };

    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:db.size()];
    for (size_t i = 0; i < db.size(); ++i) {
        [arr addObject:[NSValue valueWithPointer:&db[i]]];
    }
    return arr;
}
