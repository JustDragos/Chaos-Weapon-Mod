// Used to It (tier 4 perk): +1 Melee and Ranged Defense per attack that misses him (max 10, until
// the battle ends), and no fatigue from dodging. See ::ChaosMind.UsedToIt.
this.perk_used_to_it <- this.inherit("scripts/skills/skill", {
	m = {
		Stacks = 0,
		FatigueBeforeAttack = null
	},
	function create()
	{
		this.m.ID = "perk.used_to_it";
		this.m.Name = this.Const.Strings.PerkName.UsedToIt;
		this.m.Description = this.Const.Strings.PerkDescription.UsedToIt;
		this.m.Icon = "skills/chaos_mind/used_to_it_perk.png";
		this.m.Type = this.Const.SkillType.Perk;
		this.m.Order = this.Const.SkillOrder.Perk;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsHidden = false;
	}

	function getStacks()
	{
		return this.m.Stacks;
	}

	function onUpdate( _properties )
	{
		local bonus = this.m.Stacks * ::ChaosMind.UsedToIt.DefensePerStack;
		_properties.MeleeDefense += bonus;
		_properties.RangedDefense += bonus;

		if ("FatigueLossOnBeingMissedMult" in _properties)
		{
			_properties.FatigueLossOnBeingMissedMult = 0.0;
		}
	}

	// Called just before an attack against him is rolled (MSU buildPropertiesForDefense).
	function onBeingAttacked( _attacker, _skill, _properties )
	{
		this.m.FatigueBeforeAttack = this.getContainer().getActor().getFatigue();
	}

	function onMissed( _attacker, _skill )
	{
		local actor = this.getContainer().getActor();
		local uti = ::ChaosMind.UsedToIt;

		if (this.m.FatigueBeforeAttack != null && actor.getFatigue() > this.m.FatigueBeforeAttack)
		{
			local refunded = actor.getFatigue() - this.m.FatigueBeforeAttack;
			actor.setFatigue(this.m.FatigueBeforeAttack);

			if (!uti.FirstRefundLogged)
			{
				uti.FirstRefundLogged = true;
				::logInfo("Chaos Mind: Used to It refunded " + refunded + " fatigue for " + actor.getName() + " dodging an attack.");
			}
		}

		this.m.FatigueBeforeAttack = null;

		if (_skill == null || !_skill.isAttack() || this.m.Stacks >= uti.MaxStacks)
		{
			return;
		}

		this.m.Stacks += 1;

		if (!this.getContainer().hasSkill(uti.EffectID))
		{
			this.getContainer().add(::new("scripts/skills/effects/used_to_it_effect"));
		}

		actor.setDirty(true);
	}

	function onCombatStarted()
	{
		this.m.Stacks = 0;
		this.m.FatigueBeforeAttack = null;
	}

	function onCombatFinished()
	{
		this.m.Stacks = 0;
		this.m.FatigueBeforeAttack = null;
	}
});
