// Troll Allegiance (tier 3 perk): all his recovery is 20% stronger. The world-map part (hitpoints
// and injuries) runs in ::ChaosMind.TrollAllegiance.check; this raises fatigue recovery in battle.
this.perk_troll_allegiance <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "perk.troll_allegiance";
		this.m.Name = this.Const.Strings.PerkName.TrollAllegiance;
		this.m.Description = this.Const.Strings.PerkDescription.TrollAllegiance;
		this.m.Icon = "skills/chaos_mind/troll_allegiance.png";
		this.m.Type = this.Const.SkillType.Perk;
		this.m.Order = this.Const.SkillOrder.Perk;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsHidden = false;
	}

	// After every other skill's onUpdate, so their fatigue recovery bonuses are raised too.
	function onAfterUpdate( _properties )
	{
		if ("FatigueRecoveryRate" in _properties)
		{
			_properties.FatigueRecoveryRate = ::Math.round(_properties.FatigueRecoveryRate * ::ChaosMind.TrollAllegiance.RecoveryMult);
		}
	}
});
