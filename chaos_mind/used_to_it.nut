// Used to It (tier 4 perk, perk.used_to_it):
//  - every attack, melee or ranged, that misses him gives +1 Melee and +1 Ranged Defense until the
//    battle ends, up to 10 stacks (shown as effects.used_to_it);
//  - dodging costs him no fatigue: his fatigue is noted when he's attacked (onBeingAttacked) and
//    put back if the attack missed (onMissed). If the game has a multiplier for that fatigue, it's
//    also set to 0. The names couldn't be confirmed in the encrypted scripts; the first refund is
//    logged so it can be checked.
::ChaosMind.UsedToIt <- {
    PerkID = "perk.used_to_it",
    EffectID = "effects.used_to_it",
    DefensePerStack = 1,
    MaxStacks = 10,
    FirstRefundLogged = false,

    function getPerk( _actor )
    {
        return _actor.getSkills().getSkillByID(this.PerkID);
    }
};

::Const.Strings.PerkName.UsedToIt <- "Used to It";
::Const.Strings.PerkDescription.UsedToIt <- "He has been swung at so often he barely notices anymore. Every attack, melee or ranged, that misses him gives [color="
    + ::Const.UI.Color.PositiveValue + "]+1[/color] Melee and Ranged Defense until the battle ends, up to [color=" + ::Const.UI.Color.PositiveValue
    + "]+10[/color]. Dodging attacks no longer costs him any fatigue.";

local usedToItPerk = {
    ID = "perk.used_to_it",
    Script = "scripts/skills/perks/perk_used_to_it",
    Name = ::Const.Strings.PerkName.UsedToIt,
    Tooltip = ::Const.Strings.PerkDescription.UsedToIt,
    Icon = "skills/chaos_mind/used_to_it_perk.png",
    IconDisabled = "skills/chaos_mind/used_to_it_perk_sw.png",
    Row = 3,
    Unlocks = 3
};
::Const.Perks.Perks[3].push(usedToItPerk);
::Const.Perks.LookupMap[usedToItPerk.ID] <- usedToItPerk;
