// The Red Dragon's body (chaos_mind/dragon.nut): the centre of seven hexes. It holds the shared
// health, the AI and every attack; the head, tail and four wings around it are
// chaos_mind_red_dragon_part entities that pass their hits on to it. One sprite, cut from
// Used_photos/red_dragon.webp, covers all seven hexes.
// Built after the readable Legends legend_stollwurm (a body that spawns and owns its tail).
this.chaos_mind_red_dragon <- this.inherit("scripts/entity/tactical/actor", {
	m = {
		Parts = [],
		HeadDirection = 5,
		TurnCount = 0,
		HasActed = false,
		FledAtTwoThirds = false,
		FledAtOneThird = false
	},

	function getName()
	{
		return ::ChaosMind.Dragon.Name;
	}

	function getHeadDirection()
	{
		return this.m.HeadDirection;
	}

	function isAirborne()
	{
		return this.getSkills().hasSkill("effects.chaos_mind_dragon_airborne");
	}

	function setHeadDirection( _d )
	{
		this.m.HeadDirection = _d;

		try
		{
			this.getSprite("body").setHorizontalFlipping(!::ChaosMind.Dragon.isFacingRight(_d));
		}
		catch (e)
		{
		}
	}

	function create()
	{
		this.m.Type = this.Const.EntityType.ChaosMindRedDragon;
		this.m.BloodType = this.Const.BloodType.Red;
		this.m.XP = this.Const.Tactical.Actor.ChaosMindRedDragon.XP;
		this.m.BloodSplatterOffset = this.createVec(0, 0);
		this.m.DecapitateSplatterOffset = this.createVec(0, 0);
		this.m.DecapitateBloodAmount = 2.0;
		this.m.ConfidentMoraleBrush = "icon_confident_orcs";
		this.m.IsUsingZoneOfControl = false;
		this.m.Parts = [];
		this.actor.create();
		this.m.Name = ::ChaosMind.Dragon.Name;
		this.m.Sound[this.Const.Sound.ActorEvent.DamageReceived] = [
			"sounds/enemies/lindwurm_hurt_01.wav",
			"sounds/enemies/lindwurm_hurt_02.wav",
			"sounds/enemies/lindwurm_hurt_03.wav",
			"sounds/enemies/lindwurm_hurt_04.wav"
		];
		this.m.Sound[this.Const.Sound.ActorEvent.Death] = [
			"sounds/enemies/lindwurm_death_01.wav",
			"sounds/enemies/lindwurm_death_02.wav",
			"sounds/enemies/lindwurm_death_03.wav",
			"sounds/enemies/lindwurm_death_04.wav"
		];
		this.m.Sound[this.Const.Sound.ActorEvent.Idle] = [
			"sounds/enemies/lindwurm_idle_01.wav",
			"sounds/enemies/lindwurm_idle_02.wav",
			"sounds/enemies/lindwurm_idle_03.wav",
			"sounds/enemies/lindwurm_idle_04.wav"
		];
		this.m.Sound[this.Const.Sound.ActorEvent.Move] = this.m.Sound[this.Const.Sound.ActorEvent.Idle];
		this.m.SoundVolume[this.Const.Sound.ActorEvent.DamageReceived] = 1.5;
		this.m.SoundVolume[this.Const.Sound.ActorEvent.Death] = 2.0;
		this.m.SoundVolume[this.Const.Sound.ActorEvent.Idle] = 2.0;
		this.m.SoundPitch = 0.85;
		this.getFlags().add("chaos_mind_red_dragon");
		this.m.AIAgent = this.new("scripts/ai/tactical/agents/chaos_mind_red_dragon_agent");
		this.m.AIAgent.setActor(this);
	}

	function onInit()
	{
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

		if ("IsImmuneToFire" in b)
		{
			b.IsImmuneToFire = true;
		}

		if ("IsAffectedByRain" in b)
		{
			b.IsAffectedByRain = false;
		}

		this.m.ActionPoints = b.ActionPoints;
		this.m.Hitpoints = b.Hitpoints;
		this.m.CurrentProperties = clone b;
		this.m.ActionPointCosts = this.Const.DefaultMovementAPCost;
		this.m.FatigueCosts = this.Const.DefaultMovementFatigueCost;
		this.m.MoraleState = this.Const.MoraleState.Ignore;

		local body = this.addSprite("body");
		body.setBrush(::ChaosMind.Dragon.Brush);
		local head = this.addSprite("head");
		head.Visible = false;
		local injury = this.addSprite("injury");
		injury.Visible = false;
		local blood = this.addSprite("body_blood");
		blood.Visible = false;
		// Asked for by the game's placement and faction code (log: "Could not get Sprite with ID
		// 'socket'"); invisible, a base disc under a seven-hex dragon would look wrong.
		foreach (name in [ "socket", "arrow" ])
		{
			local s = this.addSprite(name);
			s.Visible = false;
		}
		this.addDefaultStatusSprites();
		this.setHeadDirection(this.m.HeadDirection);

		// Every battle starts with the dragon in the air; it lands on its first turn.
		::ChaosMind.Dragon.makeAirborne(this);
	}

	function onUpdateInjuryLayer()
	{
	}

	function onTurnStart()
	{
		this.actor.onTurnStart();
		this.m.TurnCount = this.m.TurnCount + 1;
		this.m.HasActed = false;
	}

	// Should it take off this turn? Every FlyEvery-th turn, and the first time it drops below 2/3
	// and 1/3 health.
	function wantsToFly()
	{
		local pct = this.getHitpoints() / (this.getHitpointsMax() * 1.0);

		if (!this.m.FledAtTwoThirds && pct < 0.667)
		{
			this.m.FledAtTwoThirds = true;
			return true;
		}

		if (!this.m.FledAtOneThird && pct < 0.334)
		{
			this.m.FledAtOneThird = true;
			return true;
		}

		return this.m.TurnCount % ::ChaosMind.Dragon.FlyEvery == 0;
	}

	function wantsToRoar()
	{
		return this.m.TurnCount % ::ChaosMind.Dragon.RoarEvery == 0;
	}

	// ---- The six parts ----

	function spawnParts()
	{
		this.removeParts();
		local layout = ::ChaosMind.Dragon.getLayout(this.m.HeadDirection);
		local roles = [ [ layout.Head, "head" ], [ layout.Tail, "tail" ] ];

		foreach (w in layout.Wings)
		{
			roles.push([ w, "wing" ]);
		}

		local tile = this.getTile();

		foreach (r in roles)
		{
			if (!tile.hasNextTile(r[0]))
			{
				continue;
			}

			local t = tile.getNextTile(r[0]);

			if (!t.IsEmpty)
			{
				continue;
			}

			try
			{
				local part = this.Tactical.spawnEntity(::ChaosMind.Dragon.PartScript, t.Coords.X, t.Coords.Y, this.getID());
				// Recorded first (15 Nov): setFaction used to throw, and the part stayed on the board
				// untracked, so the body could never take it off again.
				this.m.Parts.push(this.WeakTableRef(part));
				part.setRole(r[1]);
				part.setFaction(this.getFaction());
			}
			catch (e)
			{
				::logWarning("Chaos Mind: a Red Dragon " + r[1] + " could not be placed (" + e + ").");
			}
		}
	}

	// Takes the parts off the board without a death: no corpse, loot or experience.
	function removeParts()
	{
		foreach (p in this.m.Parts)
		{
			if (p != null && !p.isNull() && p.isAlive())
			{
				try
				{
					p.m.IsAlive = false;
					p.die();
				}
				catch (e)
				{
					::logWarning("Chaos Mind: a Red Dragon part could not be removed (" + e + ").");
				}
			}
		}

		this.m.Parts = [];
	}

	function getAliveParts()
	{
		local ret = [];

		foreach (p in this.m.Parts)
		{
			if (p != null && !p.isNull() && p.isAlive())
			{
				ret.push(p);
			}
		}

		return ret;
	}

	// ---- Linked to the parts, as legend_stollwurm is to its tail ----

	function kill( _killer = null, _skill = null, _fatalityType = this.Const.FatalityType.None, _silent = false )
	{
		this.m.IsDying = true;
		this.removeParts();
		this.actor.kill(_killer, _skill, _fatalityType, _silent);
	}

	function retreat()
	{
		this.removeParts();
		this.actor.retreat();
	}

	function setFaction( _f )
	{
		this.actor.setFaction(_f);

		foreach (p in this.getAliveParts())
		{
			p.setFaction(_f);
		}
	}

	function updateOverlay()
	{
		this.actor.updateOverlay();

		foreach (p in this.getAliveParts())
		{
			p.updateOverlay();
		}
	}

	function onDeath( _killer, _skill, _tile, _fatalityType )
	{
		if (_tile != null)
		{
			local flip = !::ChaosMind.Dragon.isFacingRight(this.m.HeadDirection);
			this.m.IsCorpseFlipped = flip;

			try
			{
				local decal = _tile.spawnDetail(::ChaosMind.Dragon.DeadBrush, this.Const.Tactical.DetailFlag.Corpse, flip);
				decal.Scale = 1.0;
			}
			catch (e)
			{
			}

			this.spawnTerrainDropdownEffect(_tile);

			// The hoard, and scales to work into armor.
			if (_killer == null || _killer.getFaction() == this.Const.Faction.Player || _killer.getFaction() == this.Const.Faction.PlayerAnimals)
			{
				foreach (script in [ "scripts/items/loot/lindwurm_hoard_item", "scripts/items/loot/lindwurm_hoard_item", "scripts/items/misc/lindwurm_scales_item", "scripts/items/misc/lindwurm_scales_item", "scripts/items/misc/lindwurm_blood_item" ])
				{
					try
					{
						this.new(script).drop(_tile);
					}
					catch (e)
					{
					}
				}
			}

			local corpse = clone this.Const.Corpse;
			corpse.CorpseName = "The Red Dragon";
			corpse.IsHeadAttached = true;
			corpse.Tile = _tile;
			_tile.Properties.set("Corpse", corpse);
			this.Tactical.Entities.addCorpse(_tile);
		}

		::logInfo("Chaos Mind: the Red Dragon is dead.");
		this.actor.onDeath(_killer, _skill, _tile, _fatalityType);
	}
});
