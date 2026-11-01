// Chaos Protection: -20 Resolve. The immunities (black cloud, curse, Brother / Mass Sacrifice,
// sacrifice terror) are checked by those effects through ::ChaosMind.isProtected.
this.perk_chaos_protection <- this.inherit("scripts/skills/skill", {
	m = {
		ResolvePenalty = 20
	},
	function create()
	{
		this.m.ID = "perk.chaos_protection";
		this.m.ResolvePenalty = ::ChaosMind.ChaosProtectionResolvePenalty;
		this.m.Name = this.Const.Strings.PerkName.ChaosProtection;
		this.m.Description = this.Const.Strings.PerkDescription.ChaosProtection;
		this.m.Icon = "skills/chaos_mind/chaos_protection.png";
		this.m.Type = this.Const.SkillType.Perk;
		this.m.Order = this.Const.SkillOrder.Perk;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsHidden = false;
	}

	function onUpdate( _properties )
	{
		_properties.Bravery -= this.m.ResolvePenalty;
	}
});
