// Vampire Allegiance (tier 2 perk, perk.vampire_allegiance): every kill he makes heals him for 5%
// of the victim's max hitpoints (at least 1), never above his own max. Any weapon, any kill.
::ChaosMind.VampireAllegiance <- {
    PerkID = "perk.vampire_allegiance",
    HealPercent = 5,
    FirstHealLogged = false,

    // Hitpoints a kill of _target gives back.
    function getHeal( _target )
    {
        return ::Math.max(1, ::Math.round(_target.getHitpointsMax() * this.HealPercent / 100.0));
    }
};

::Const.Strings.PerkName.VampireAllegiance <- "Vampire Allegiance";
::Const.Strings.PerkDescription.VampireAllegiance <- "He has sworn himself to something that drinks the dead. Every kill he makes heals him for [color="
    + ::Const.UI.Color.PositiveValue + "]" + ::ChaosMind.VampireAllegiance.HealPercent + "%[/color] of the victim's maximum hitpoints, "
    + "never above his own maximum. Works with any weapon.";

local vampireAllegiancePerk = {
    ID = "perk.vampire_allegiance",
    Script = "scripts/skills/perks/perk_vampire_allegiance",
    Name = ::Const.Strings.PerkName.VampireAllegiance,
    Tooltip = ::Const.Strings.PerkDescription.VampireAllegiance,
    Icon = "skills/chaos_mind/vampire_allegiance.png",
    IconDisabled = "skills/chaos_mind/vampire_allegiance_sw.png",
    Row = 1,
    Unlocks = 1
};
::Const.Perks.Perks[1].push(vampireAllegiancePerk);
::Const.Perks.LookupMap[vampireAllegiancePerk.ID] <- vampireAllegiancePerk;
