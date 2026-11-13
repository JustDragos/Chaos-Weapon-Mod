// Vampire Allegiance (tier 2 perk): every kill heals him for 5% of the victim's max hitpoints.
// See ::ChaosMind.VampireAllegiance.
this.perk_vampire_allegiance <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "perk.vampire_allegiance";
		this.m.Name = this.Const.Strings.PerkName.VampireAllegiance;
		this.m.Description = this.Const.Strings.PerkDescription.VampireAllegiance;
		this.m.Icon = "skills/chaos_mind/vampire_allegiance.png";
		this.m.Type = this.Const.SkillType.Perk;
		this.m.Order = this.Const.SkillOrder.Perk;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsHidden = false;
	}

	function onTargetKilled( _targetEntity, _skill )
	{
		local actor = this.getContainer().getActor();

		if (_targetEntity == null || actor == null || !actor.isAlive() || actor.getHitpoints() >= actor.getHitpointsMax())
		{
			return;
		}

		local va = ::ChaosMind.VampireAllegiance;
		local before = actor.getHitpoints();
		local heal = ::ChaosMind.TrollAllegiance.boostHeal(actor, va.getHeal(_targetEntity));
		actor.setHitpoints(::Math.min(actor.getHitpointsMax(), before + heal));
		actor.setDirty(true);
		local healed = actor.getHitpoints() - before;

		if (!va.FirstHealLogged)
		{
			va.FirstHealLogged = true;
			::logInfo("Chaos Mind: Vampire Allegiance healed " + actor.getName() + " for " + healed + " from a kill.");
		}

		try
		{
			::Tactical.EventLog.log(::Const.UI.getColorizedEntityName(actor) + " drinks " + healed + " hitpoints from " + ::Const.UI.getColorizedEntityName(_targetEntity));
		}
		catch (e)
		{
		}
	}
});
