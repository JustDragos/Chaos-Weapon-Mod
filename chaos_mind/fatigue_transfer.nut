// Fatigue Transfer (tier 6 perk, perk.fatigue_transfer). Grants actives.fatigue_transfer.
::Const.Strings.PerkName.FatigueTransfer <- "Fatigue Transfer";
::Const.Strings.PerkDescription.FatigueTransfer <- "Unlocks the 'Fatigue Transfer' skill: for [color=" + ::Const.UI.Color.PositiveValue
    + "]1[/color] AP, move all of your fatigue onto an adjacent enemy, up to his maximum, and drop to [color="
    + ::Const.UI.Color.PositiveValue + "]0[/color] fatigue yourself. Can be used once every 3 turns.";

local fatigueTransferPerk = {
    ID = "perk.fatigue_transfer",
    Script = "scripts/skills/perks/perk_fatigue_transfer",
    Name = ::Const.Strings.PerkName.FatigueTransfer,
    Tooltip = ::Const.Strings.PerkDescription.FatigueTransfer,
    Icon = "skills/chaos_mind/fatigue_transfer_perk.png",
    IconDisabled = "skills/chaos_mind/fatigue_transfer_perk_sw.png",
    Row = 5,
    Unlocks = 5
};
::Const.Perks.Perks[5].push(fatigueTransferPerk);
::Const.Perks.LookupMap[fatigueTransferPerk.ID] <- fatigueTransferPerk;
