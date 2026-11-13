// Mod Settings -> Chaos Mind -> Leveling (MSU; saved with MSU's own settings). Added 13 Nov.
//  - Perk points per level: every perk point the game gives on a level-up is multiplied by this
//    (player.updateLevel). Levels that give none, such as the veteran levels, stay at none.
//  - Attribute level-ups per level: every level-up's round of raising three attributes is
//    multiplied by this. The game rolls each round's values in advance (one set per level up to
//    the last perk level, m.Attributes); each extra round gets its own fresh set
//    (fillAttributeLevelUpValues), so talents still count. Extra rounds on veteran levels give +1s,
//    like the game's own veteran rounds.
//  - XP multiplier: all XP a brother gains is multiplied by this (player.addXP), which also speeds
//    up leveling for testing.
// Names from the Legends copy of player.nut: addXP( _xp, _scale = true ), updateLevel(),
// fillAttributeLevelUpValues( _amount ), m.PerkPoints, m.LevelUps, m.Level.
::ChaosMind.Settings <- {
    PerkPoints = null,
    AttributeLevelUps = null,
    XPMult = null,
    ExtraRecruits = null,
    SaveSafety = null,
    Duels = null,

    // Mod Settings -> Chaos Mind -> Gameplay: leader duels (chaos_mind/duel.nut), off by default.
    function areDuelsOn()
    {
        return this.Duels != null && this.Duels.getValue() == true;
    }

    // Mod Settings -> Chaos Mind -> Saves: chaos_mind/save_safety.nut, off unless switched on.
    function isSaveSafetyOn()
    {
        return this.SaveSafety != null && this.SaveSafety.getValue() == true;
    }

    function getExtraRecruits()
    {
        return this.ExtraRecruits != null ? this.ExtraRecruits.getValue().tointeger() : 0;
    }

    // Changed in a running campaign: every town refreshes its recruits at once. Not while a save
    // is loading (MSU puts each save's stored settings back then).
    function refreshTowns()
    {
        if ((("Serialization" in ::MSU) && ("IsLoading" in ::MSU.Serialization) && ::MSU.Serialization.IsLoading) || !("State" in ::World) || ::World.State == null || !("EntityManager" in ::World) || ::World.EntityManager == null)
        {
            return;
        }

        foreach (town in ::World.EntityManager.getSettlements())
        {
            try
            {
                town.updateRoster(true);
            }
            catch (e)
            {
            }
        }

        ::logInfo("Chaos Mind: every town's recruits refreshed (" + this.getExtraRecruits() + " extra).");
    }

    function getPerkPointsPerLevel()
    {
        return this.PerkPoints != null ? this.PerkPoints.getValue().tointeger() : 1;
    }

    function getAttributeLevelUpsPerLevel()
    {
        return this.AttributeLevelUps != null ? this.AttributeLevelUps.getValue().tointeger() : 2;
    }

    function getXPMult()
    {
        return this.XPMult != null ? this.XPMult.getValue().tofloat() : 1.0;
    }

    // After the game's updateLevel: multiplies what it just gave.
    function onLevelsGained( _bro, _levelBefore, _perkPointsBefore, _levelUpsBefore )
    {
        local extraPerks = (_bro.m.PerkPoints - _perkPointsBefore) * (this.getPerkPointsPerLevel() - 1);

        if (extraPerks > 0)
        {
            _bro.m.PerkPoints += extraPerks;
        }

        local roundsMult = this.getAttributeLevelUpsPerLevel() - 1;
        local extraRounds = (_bro.m.LevelUps - _levelUpsBefore) * roundsMult;

        if (extraRounds > 0)
        {
            _bro.m.LevelUps += extraRounds;

            // Fresh rolls for the extra rounds of levels that come with rolled values.
            local maxRolled = ("XP" in ::Const && "MaxLevelWithPerkpoints" in ::Const.XP) ? ::Const.XP.MaxLevelWithPerkpoints : 11;
            local rolledLevels = ::Math.max(0, ::Math.min(_bro.m.Level, maxRolled) - ::Math.max(_levelBefore, 1));

            if (rolledLevels > 0 && ("fillAttributeLevelUpValues" in _bro))
            {
                try
                {
                    _bro.fillAttributeLevelUpValues(rolledLevels * roundsMult);
                }
                catch (e)
                {
                    ::logWarning("Chaos Mind: could not roll values for the extra attribute level-ups (" + e + "); they give +1 each.");
                }
            }
        }

        if (extraPerks > 0 || extraRounds > 0)
        {
            ::logInfo("Chaos Mind: " + _bro.getName() + " gets " + extraPerks + " extra perk point(s) and " + extraRounds + " extra attribute level-up(s) (Mod Settings).");
        }
    }

    // A new campaign: some origins hand their starting brothers levels directly, without a
    // level-up (the Lone Wolf: PerkPoints, LevelUps = 3 and Level = 4 in onSpawnAssets, readable in
    // the Legends copy). Their unspent ones are multiplied here the same way, once.
    function onNewCampaign()
    {
        foreach (bro in ::World.getPlayerRoster().getAll())
        {
            if (bro.m.Level > 1 && (bro.m.LevelUps > 0 || bro.m.PerkPoints > 0))
            {
                this.onLevelsGained(bro, 1, 0, 0);
            }
        }
    }
};

local page = ::ChaosMind.Mod.ModSettings.addPage("Leveling");
::ChaosMind.Settings.PerkPoints = page.addRangeSetting("PerkPointsPerLevel", 1, 1, 10, 1, "Perk points per level",
    "How many perk points a brother gets for each level that gives one. 1 is the normal game. Levels without a perk point stay without.");
// Defaults to 2 (13 Nov, asked for so new runs start with it); MSU keeps each save's own value.
::ChaosMind.Settings.AttributeLevelUps = page.addRangeSetting("AttributeLevelUpsPerLevel", 2, 1, 5, 1, "Attribute level-ups per level",
    "How many times a brother raises three attributes for each level he gains. 1 is the normal game; 2 (the default) lets him pick three attributes twice. Each extra time gets its own rolled values.");
::ChaosMind.Settings.XPMult = page.addRangeSetting("XPMultiplier", 1.0, 0.5, 20.0, 0.5, "XP multiplier",
    "All experience brothers gain is multiplied by this. 1 is the normal game; raise it to level brothers quickly, e.g. for testing.");

// Mod Settings -> Chaos Mind -> Recruiting (13 Nov). Defaults to 12, asked for as "12 more recruits
// every town"; MSU keeps each save's own value.
local recruiting = ::ChaosMind.Mod.ModSettings.addPage("Recruiting");
::ChaosMind.Settings.ExtraRecruits = recruiting.addRangeSetting("ExtraRecruits", 12, 0, 20, 1, "Extra recruits per town",
    "Every town offers this many more recruits each time its recruits refresh (every few days). 0 is the normal game. Changing it in a campaign refreshes every town's recruits at once.");

// Mod Settings -> Chaos Mind -> Gameplay (13 Nov, evening): leader duels, off by default because
// every duel crashed at round start ("Class/Structure with key "" is not registered").
local gameplay = ::ChaosMind.Mod.ModSettings.addPage("Gameplay");
::ChaosMind.Settings.Duels = gameplay.addBooleanSetting("LeaderDuels", false, "Leader duels (experimental)",
    "When you engage a party with a leader, he may challenge one of your men to a duel first. Off by default: duels have crashed the game at their first round. Turn on only to test them.");

// Mod Settings -> Chaos Mind -> Saves (13 Nov, evening): saves that load without the mod, off by
// default after its first version corrupted a save (chaos_mind/save_safety.nut).
local saves = ::ChaosMind.Mod.ModSettings.addPage("Saves");
::ChaosMind.Settings.SaveSafety = saves.addBooleanSetting("SaveSafety", false, "Saves load without the mod (experimental)",
    "When saving, keep this mod's items, perks and contracts as plain data so the save still loads if the mod is removed; they come back when it's installed again. Off by default: its first version corrupted a save. Before the sword is claimed, saves always need the mod.");

try
{
    ::ChaosMind.Settings.ExtraRecruits.addAfterChangeCallback(function( _oldValue )
    {
        if (_oldValue != this.getValue())
        {
            ::ChaosMind.Settings.refreshTowns();
        }
    });
}
catch (e)
{
}

::ChaosMind.HooksMod.hook("scripts/entity/world/settlement", function(q)
{
    if (!q.contains("updateRoster", true))
    {
        ::logWarning("Chaos Mind: settlement has no updateRoster; the extra recruits setting is off.");
        return;
    }

    // As if a recruiter follower added the setting to both ends of the roster size
    // (World.Assets.m.RosterSizeAdditionalMin / Max): raised for this call only and put back after,
    // the way Legends adds its Braggart bonus.
    q.updateRoster = @(__original) function( ... )
    {
        local args = [ this ];
        args.extend(vargv);
        local extra = ::ChaosMind.Settings.getExtraRecruits();
        local assets = ::World.Assets.m;

        if (extra <= 0 || !("RosterSizeAdditionalMin" in assets) || !("RosterSizeAdditionalMax" in assets))
        {
            return __original.acall(args);
        }

        local min = assets.RosterSizeAdditionalMin;
        local max = assets.RosterSizeAdditionalMax;
        assets.RosterSizeAdditionalMin = min + extra;
        assets.RosterSizeAdditionalMax = max + extra;
        local ret = null;

        try
        {
            ret = __original.acall(args);
        }
        catch (e)
        {
            assets.RosterSizeAdditionalMin = min;
            assets.RosterSizeAdditionalMax = max;
            throw e;
        }

        assets.RosterSizeAdditionalMin = min;
        assets.RosterSizeAdditionalMax = max;
        return ret;
    }
});

::ChaosMind.HooksMod.hook("scripts/entity/tactical/player", function(q)
{
    if (q.contains("updateLevel", true))
    {
        q.updateLevel = @(__original) function( ... )
        {
            local levelBefore = this.m.Level;
            local perkPointsBefore = this.m.PerkPoints;
            local levelUpsBefore = this.m.LevelUps;
            local args = [ this ];
            args.extend(vargv);
            local ret = __original.acall(args);

            if (this.m.Level > levelBefore)
            {
                try
                {
                    ::ChaosMind.Settings.onLevelsGained(this, levelBefore, perkPointsBefore, levelUpsBefore);
                }
                catch (e)
                {
                    ::logWarning("Chaos Mind: the leveling settings could not be applied (" + e + ").");
                }
            }

            return ret;
        }
    }
    else
    {
        ::logWarning("Chaos Mind: player has no updateLevel; the perk point and attribute settings are off.");
    }

    if (q.contains("addXP", true))
    {
        q.addXP = @(__original) function( _xp, ... )
        {
            local args = [ this, _xp * ::ChaosMind.Settings.getXPMult() ];
            args.extend(vargv);
            return __original.acall(args);
        }
    }
    else
    {
        ::logWarning("Chaos Mind: player has no addXP; the XP multiplier setting is off.");
    }
});
