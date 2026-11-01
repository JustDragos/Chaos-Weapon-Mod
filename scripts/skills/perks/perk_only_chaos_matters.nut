// Only Chaos Matters. Charm / scream immunity and the Rally the Troops / Inspiring Presence
// isolation live in chaos_mind/only_chaos_matters.nut. This skill ignores dying allies,
// and makes the other brothers hate him after battles and every day.
this.perk_only_chaos_matters <- this.inherit("scripts/skills/skill", {
	m = {
		HasDyingAlliesProperty = null
	},
	function create()
	{
		this.m.ID = "perk.only_chaos_matters";
		this.m.Name = this.Const.Strings.PerkName.OnlyChaosMatters;
		this.m.Description = this.Const.Strings.PerkDescription.OnlyChaosMatters;
		this.m.Icon = "skills/chaos_mind/only_chaos_matters.png";
		this.m.Type = this.Const.SkillType.Perk;
		this.m.Order = this.Const.SkillOrder.Perk;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsHidden = false;
	}

	// Never loses morale when an ally dies. The property name couldn't be confirmed in the
	// encrypted game scripts, so it's only set if it exists (reported once per battle).
	function onUpdate( _properties )
	{
		if ("IsAffectedByDyingAllies" in _properties)
		{
			_properties.IsAffectedByDyingAllies = false;
			this.m.HasDyingAlliesProperty = true;
		}
		else
		{
			this.m.HasDyingAlliesProperty = false;
		}
	}

	function onCombatStarted()
	{
		this.skill.onCombatStarted();
		::logInfo("Chaos Mind: Only Chaos Matters on " + this.getContainer().getActor().getName()
			+ (this.m.HasDyingAlliesProperty == false ? ": IsAffectedByDyingAllies NOT FOUND, ally deaths still affect him." : ": ignores dying allies."));
	}

	function onCombatFinished()
	{
		this.skill.onCombatFinished();
		::ChaosMind.OnlyChaos.onBattleFinished(this.getContainer().getActor());
	}

	function onNewDay()
	{
		this.skill.onNewDay();
		::ChaosMind.OnlyChaos.onNewDay(this.getContainer().getActor());
	}
});
