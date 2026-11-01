// Fatigue Transfer (tier 6 perk): unlocks the Fatigue Transfer active skill.
this.perk_fatigue_transfer <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "perk.fatigue_transfer";
		this.m.Name = this.Const.Strings.PerkName.FatigueTransfer;
		this.m.Description = this.Const.Strings.PerkDescription.FatigueTransfer;
		this.m.Icon = "skills/chaos_mind/fatigue_transfer_perk.png";
		this.m.Type = this.Const.SkillType.Perk;
		this.m.Order = this.Const.SkillOrder.Perk;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsHidden = false;
	}

	function onAdded()
	{
		if (!this.getContainer().hasSkill("actives.fatigue_transfer"))
		{
			this.getContainer().add(::new("scripts/skills/actives/fatigue_transfer_skill"));
		}
	}

	function onRemoved()
	{
		this.getContainer().removeByID("actives.fatigue_transfer");
	}
});
