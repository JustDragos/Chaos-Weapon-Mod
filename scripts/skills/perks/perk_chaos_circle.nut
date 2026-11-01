// Chaos Circle (tier 7 perk): unlocks the Chaos Circle active skill (usable with Chaos Mind only).
this.perk_chaos_circle <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "perk.chaos_circle";
		this.m.Name = this.Const.Strings.PerkName.ChaosCircle;
		this.m.Description = this.Const.Strings.PerkDescription.ChaosCircle;
		this.m.Icon = "skills/chaos_mind/chaos_circle_perk.png";
		this.m.Type = this.Const.SkillType.Perk;
		this.m.Order = this.Const.SkillOrder.Perk;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsHidden = false;
	}

	function onAdded()
	{
		if (!this.getContainer().hasSkill("actives.chaos_circle"))
		{
			this.getContainer().add(::new("scripts/skills/actives/chaos_circle_skill"));
		}
	}

	function onRemoved()
	{
		this.getContainer().removeByID("actives.chaos_circle");
	}
});
