// A Red Dragon part (head, tail or wing) on one of the six hexes around the body
// (chaos_mind_red_dragon). It has no picture or attacks of its own: it borrows the body's stats and
// health, and every hit on it is a hit on the body. Spawned and removed by the body; it ends its
// own turns at once. Built after the readable Legends legend_stollwurm_tail.
this.chaos_mind_red_dragon_part <- this.inherit("scripts/entity/tactical/actor", {
	m = {
		Body = null,
		Role = "wing"
	},

	function hasBody()
	{
		// Crash fix (15 Nov): Tactical.getEntityByID returns the body itself, not a weak reference,
		// so Body.isNull() threw on every lookup and the game crashed when a part was attacked.
		// ::MSU.isNull handles both.
		return !::MSU.isNull(this.m.Body) && this.m.Body.isAlive();
	}

	function getBody()
	{
		return this.m.Body;
	}

	function setRole( _r )
	{
		this.m.Role = _r;
	}

	function getName()
	{
		local names = { head = "Red Dragon's Head", tail = "Red Dragon's Tail", wing = "Red Dragon's Wing" };
		return (this.m.Role in names) ? names[this.m.Role] : ::ChaosMind.Dragon.Name;
	}

	// ---- Everything about its state is the body's ----

	function getBaseProperties()
	{
		return this.hasBody() ? this.m.Body.m.BaseProperties : this.m.BaseProperties;
	}

	function getCurrentProperties()
	{
		return this.hasBody() ? this.m.Body.m.CurrentProperties : this.m.CurrentProperties;
	}

	function getHitpoints()
	{
		return this.hasBody() ? this.m.Body.getHitpoints() : 0;
	}

	function getHitpointsMax()
	{
		return this.hasBody() ? this.m.Body.getHitpointsMax() : 1;
	}

	function getHitpointsPct()
	{
		return this.hasBody() ? this.m.Body.getHitpointsPct() : 0.0;
	}

	function setHitpoints( _h )
	{
		if (this.hasBody())
		{
			this.m.Body.setHitpoints(_h);
		}
	}

	function getMoraleState()
	{
		return this.hasBody() ? this.m.Body.getMoraleState() : this.Const.MoraleState.Ignore;
	}

	function getBravery()
	{
		return this.hasBody() ? this.m.Body.getBravery() : 0;
	}

	function getFatigue()
	{
		return 0;
	}

	function getArmor( _bodyPart )
	{
		return this.hasBody() ? this.m.Body.getArmor(_bodyPart) : 0;
	}

	function getArmorMax( _bodyPart )
	{
		return this.hasBody() ? this.m.Body.getArmorMax(_bodyPart) : 0;
	}

	function getXPValue()
	{
		return 0;
	}

	function getInitiative()
	{
		return 0;
	}

	function checkMorale( _change, _difficulty, _type = this.Const.MoraleCheckType.Default, _showIconBeforeMoraleIcon = "", _noNewLine = false )
	{
	}

	// Every hit on a part is a hit on the body.
	function onDamageReceived( _attacker, _skill, _hitInfo )
	{
		if (!this.isAlive() || !this.hasBody())
		{
			return 0;
		}

		return this.m.Body.onDamageReceived(_attacker, _skill, _hitInfo);
	}

	// Killed by anything: the body dies. Removed by the body: nothing more.
	function kill( _killer = null, _skill = null, _fatalityType = this.Const.FatalityType.None, _silent = false )
	{
		local body = this.hasBody() ? this.m.Body : null;
		this.m.IsAlive = false;
		this.die();

		if (body != null && !body.isDying())
		{
			body.kill(_killer, _skill, _fatalityType, _silent);
		}
	}

	function onUpdateInjuryLayer()
	{
	}

	function onTurnStart()
	{
		this.actor.onTurnStart();
		this.m.ActionPoints = 0;
	}

	function create()
	{
		this.m.Type = this.Const.EntityType.ChaosMindRedDragon;
		this.m.BloodType = this.Const.BloodType.Red;
		this.m.XP = 0;
		this.m.BloodSplatterOffset = this.createVec(0, 0);
		this.m.DecapitateSplatterOffset = this.createVec(0, 0);
		this.m.DecapitateBloodAmount = 1.0;
		this.m.IsUsingZoneOfControl = false;
		this.actor.create();
		this.m.Name = ::ChaosMind.Dragon.Name;
		this.m.Sound[this.Const.Sound.ActorEvent.DamageReceived] = [
			"sounds/enemies/lindwurm_hurt_01.wav",
			"sounds/enemies/lindwurm_hurt_02.wav",
			"sounds/enemies/lindwurm_hurt_03.wav",
			"sounds/enemies/lindwurm_hurt_04.wav"
		];
		this.m.SoundVolume[this.Const.Sound.ActorEvent.DamageReceived] = 1.5;
		this.getFlags().add("chaos_mind_red_dragon");
		this.getFlags().add("chaos_mind_red_dragon_part");
		this.m.AIAgent = this.new("scripts/ai/tactical/agents/chaos_mind_red_dragon_part_agent");
		this.m.AIAgent.setActor(this);
	}

	function onInit()
	{
		if (this.m.ParentID != 0)
		{
			// Already a weak reference, as in legend_stollwurm_tail.
			this.m.Body = this.Tactical.getEntityByID(this.m.ParentID);
		}

		this.actor.onInit();
		local b = this.m.BaseProperties;
		b.setValues(this.Const.Tactical.Actor.ChaosMindRedDragon);
		b.IsAffectedByNight = false;
		b.IsAffectedByInjuries = false;
		b.IsMovable = false;
		b.IsImmuneToKnockBackAndGrab = true;
		b.IsImmuneToStun = true;
		b.IsImmuneToRoot = true;
		b.IsImmuneToDisarm = true;
		b.IsImmuneToBleeding = true;
		b.IsImmuneToPoison = true;
		this.m.ActionPoints = 0;
		this.m.Hitpoints = b.Hitpoints;
		this.m.CurrentProperties = clone b;
		this.m.ActionPointCosts = this.Const.DefaultMovementAPCost;
		this.m.FatigueCosts = this.Const.DefaultMovementFatigueCost;
		this.m.MoraleState = this.Const.MoraleState.Ignore;

		// No picture of its own: the body's sprite covers all seven hexes.
		local body = this.addSprite("body");
		body.Visible = false;
		local head = this.addSprite("head");
		head.Visible = false;
		local injury = this.addSprite("injury");
		injury.Visible = false;
		local blood = this.addSprite("body_blood");
		blood.Visible = false;
		// The game's own placement and faction code asks for these (log: "Could not get Sprite with
		// ID 'arrow'" / "'socket'"); invisible, as the body's sprite covers the hex.
		foreach (name in [ "socket", "arrow" ])
		{
			local s = this.addSprite(name);
			s.Visible = false;
		}
		this.addDefaultStatusSprites();
	}
});
