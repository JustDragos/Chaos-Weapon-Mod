// Chaos Armor: while wielding Chaos Mind, +1 Melee and +1 Ranged Defense for every +1% of the
// sword's kill bonus (one per 10 kills). No cap. Also doubles the sword's Melee Skill scaling
// to +1% per point (checked in chaos_mind.nut getMeleeSkillMult).
this.perk_chaos_armor <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "perk.chaos_armor";
		this.m.Name = this.Const.Strings.PerkName.ChaosArmor;
		this.m.Description = this.Const.Strings.PerkDescription.ChaosArmor;
		this.m.Icon = "skills/chaos_mind/chaos_armor.png";
		this.m.Type = this.Const.SkillType.Perk;
		this.m.Order = this.Const.SkillOrder.Perk;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsHidden = false;
	}

	function getBonus()
	{
		local weapon = this.getContainer().getActor().getMainhandItem();

		if (weapon == null || weapon.getID() != ::ChaosMind.SwordID)
		{
			return 0;
		}

		return weapon.getKillBonus();
	}

	function onUpdate( _properties )
	{
		local bonus = this.getBonus();

		if (bonus > 0)
		{
			_properties.MeleeDefense += bonus;
			_properties.RangedDefense += bonus;
		}
	}
});
