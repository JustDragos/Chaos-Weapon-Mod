// Chaos Armor (tier 5 perk, perk.chaos_armor). The effect is in perk_chaos_armor.nut.
::Const.Strings.PerkName.ChaosArmor <- "Chaos Armor";
::Const.Strings.PerkDescription.ChaosArmor <- "The blade guards its wielder as jealously as it feeds on others. While wielding Chaos Mind, gain [color="
    + ::Const.UI.Color.PositiveValue + "]+1[/color] Melee Defense and [color=" + ::Const.UI.Color.PositiveValue
    + "]+1[/color] Ranged Defense for every +1% damage the blade has gained from kills, and the blade's Melee Skill scaling doubles from [color="
    + ::Const.UI.Color.PositiveValue + "]+0.5%[/color] to [color=" + ::Const.UI.Color.PositiveValue + "]+1%[/color] damage per point.";

local chaosArmorPerk = {
    ID = "perk.chaos_armor",
    Script = "scripts/skills/perks/perk_chaos_armor",
    Name = ::Const.Strings.PerkName.ChaosArmor,
    Tooltip = ::Const.Strings.PerkDescription.ChaosArmor,
    Icon = "skills/chaos_mind/chaos_armor.png",
    IconDisabled = "skills/chaos_mind/chaos_armor_sw.png",
    Row = 4,
    Unlocks = 4
};
::Const.Perks.Perks[4].push(chaosArmorPerk);
::Const.Perks.LookupMap[chaosArmorPerk.ID] <- chaosArmorPerk;
