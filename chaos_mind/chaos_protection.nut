// Chaos Protection (tier 1 perk, perk.chaos_protection): immune to Chaos Mind's black cloud and
// curse, can't be sacrificed (Brother / Mass Sacrifice), doesn't flee from sacrifice terror.
// Costs -20 Resolve (perk_chaos_protection.nut).
::ChaosMind.ChaosProtectionResolvePenalty <- 20;

::ChaosMind.isProtected <- function( _actor )
{
    return _actor != null && _actor.getSkills().hasSkill("perk.chaos_protection");
};

::Const.Strings.PerkName.ChaosProtection <- "Chaos Protection";
::Const.Strings.PerkDescription.ChaosProtection <- "A ward of runes keeps the blade's hunger at bay. Immune to Chaos Mind's black cloud and its curse, "
    + "can't be sacrificed with Brother Sacrifice or Mass Sacrifice, and never flees from seeing a sacrifice. "
    + "Holding the ward weighs on the mind: [color=" + ::Const.UI.Color.NegativeValue + "]-" + ::ChaosMind.ChaosProtectionResolvePenalty + "[/color] Resolve.";

local chaosProtectionPerk = {
    ID = "perk.chaos_protection",
    Script = "scripts/skills/perks/perk_chaos_protection",
    Name = ::Const.Strings.PerkName.ChaosProtection,
    Tooltip = ::Const.Strings.PerkDescription.ChaosProtection,
    Icon = "skills/chaos_mind/chaos_protection.png",
    IconDisabled = "skills/chaos_mind/chaos_protection_sw.png",
    Row = 0,
    Unlocks = 0
};
::Const.Perks.Perks[0].push(chaosProtectionPerk);
::Const.Perks.LookupMap[chaosProtectionPerk.ID] <- chaosProtectionPerk;
