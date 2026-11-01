// Hidden effect added by the Chaos Mind greatsword while it is equipped.
this.chaos_mind_effect <- this.inherit("scripts/skills/skill", {
	m = {
		TargetTile = null,
		MoodWarningShown = false,
		// Hitpoints each victim had just before a Chaos Mind hit (by actor ID), so a kill can
		// be paid out in Carnal Storage energy like a sacrifice: hitpoints lost / 4.
		HitpointsBefore = {}
	},
	function create()
	{
		this.m.ID = "effects.chaos_mind";
		this.m.Name = "Chaos Mind";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.IsActive = false;
		this.m.IsHidden = true;
		this.m.IsSerialized = false;
	}

	function isChaosMindAttack( _skill )
	{
		if (_skill == null || !_skill.isAttack() || _skill.isRanged())
		{
			return false;
		}

		local weapon = this.getContainer().getActor().getMainhandItem();
		return weapon != null && weapon.getID() == ::ChaosMind.SwordID;
	}

	// A leader duel (::ChaosMind.Duel) is already a champion's fight: the blade draws none there.
	// Making the duel's leader a champion a second time was one suspect in the 1 Nov duel crash.
	function isDuel()
	{
		try
		{
			local p = ::Tactical.State.getStrategicProperties();
			return p != null && p.CombatID == ::ChaosMind.Duel.CombatID;
		}
		catch (e)
		{
			return false;
		}
	}

	// The blade draws champions: at the start of each battle the wielder fights in, every enemy
	// that can be a champion gets an extra getChampionBonus()% chance to become one.
	function onCombatStarted()
	{
		this.skill.onCombatStarted();
		this.m.HitpointsBefore = {};

		local user = this.getContainer().getActor();
		local weapon = user.getMainhandItem();

		if (weapon == null || weapon.getID() != ::ChaosMind.SwordID)
		{
			return;
		}

		local chance = weapon.getChampionBonus();

		if (chance <= 0 || this.isDuel())
		{
			return;
		}

		local eligible = 0;
		local made = 0;

		foreach (faction in this.Tactical.Entities.getAllInstances())
		{
			foreach (actor in faction)
			{
				if (actor.isAlliedWith(user) || !actor.isAlive() || !("makeMiniboss" in actor))
				{
					continue;
				}

				if ("IsMiniboss" in actor.m && actor.m.IsMiniboss)
				{
					continue;
				}

				eligible += 1;

				if (::Math.rand(1, 100) > chance)
				{
					continue;
				}

				try
				{
					if (actor.makeMiniboss() != false)
					{
						actor.getSkills().update();
						made += 1;
					}
				}
				catch (e)
				{
					::logWarning("Chaos Mind: could not make " + actor.getName() + " a champion (" + e + ").");
				}
			}
		}

		::logInfo("Chaos Mind: drew " + made + " champion(s) from " + eligible + " eligible enemies (" + chance + "% each).");
	}

	// The Black Skull's reward: more max fatigue while wielding the blade (::ChaosMind.Quest).
	function onUpdate( _properties )
	{
		local weapon = this.getContainer().getActor().getMainhandItem();

		if (weapon != null && weapon.getID() == ::ChaosMind.SwordID)
		{
			::ChaosMind.Quest.addStamina(_properties, weapon);
		}
	}

	// +0.5% damage per point of melee skill (+1% with Chaos Armor), and +1% for every 10 kills
	// the blade has taken.
	function onAnySkillUsed( _skill, _targetEntity, _properties )
	{
		if (this.isChaosMindAttack(_skill))
		{
			local actor = this.getContainer().getActor();
			local weapon = actor.getMainhandItem();
			_properties.DamageTotalMult *= weapon.getMeleeSkillMult(actor, _properties.getMeleeSkill());
			_properties.DamageTotalMult *= 1.0 + weapon.getKillBonus() / 100.0;
		}
	}

	// Every death Chaos Mind causes feeds its permanent damage bonus: its attacks, the black
	// cloud and curse (this effect), and Brother / Mass Sacrifice. Friend or foe alike.
	function onTargetKilled( _targetEntity, _skill )
	{
		local user = this.getContainer().getActor();
		local weapon = user.getMainhandItem();

		if (weapon == null || weapon.getID() != ::ChaosMind.SwordID || _targetEntity == null)
		{
			return;
		}

		local bySword = _skill != null && (_skill.getID() == this.getID()
			|| _skill.getID() == "actives.brother_sacrifice" || _skill.getID() == "actives.mass_sacrifice");

		if (!bySword && !this.isChaosMindAttack(_skill))
		{
			return;
		}

		local milestone = weapon.addKill();

		try
		{
			::ChaosMind.Quest.onSwordKill(user, _targetEntity);
		}
		catch (e)
		{
			::logWarning("Chaos Mind: could not check the kill against the Black Skull (" + e + ").");
		}

		// Lost, sold or never received: every kill brings the Chaos Guide back to the stash.
		try
		{
			::ChaosMind.Guide.onSwordKill(user);
		}
		catch (e)
		{
			::logWarning("Chaos Mind: could not give the Chaos Guide back (" + e + ").");
		}

		// An enemy killed by the blade or its cloud gives energy like a sacrificed brother:
		// the hitpoints he lost to the killing blow / 4. (Sacrificed brothers already pay out
		// through the sacrifice itself.)
		if (!_targetEntity.isAlliedWith(user))
		{
			local id = _targetEntity.getID();
			local lost = (id in this.m.HitpointsBefore) ? this.m.HitpointsBefore[id] : 0;
			local cs = ::ChaosMind.CarnalStorage;
			local energy = ::Math.floor(lost / cs.HitpointsPerEnergy);

			if (energy > 0)
			{
				cs.addEnergy(user, energy, "devours " + _targetEntity.getName() + " (" + lost + " hitpoints)");
			}
		}

		// In its gorged form (500+ kills, counting this one) every kill lifts the wielder's
		// mood (the world-map mood in his roster tooltip) by 1.
		if (weapon.isAscended())
		{
			try
			{
				user.improveMood(1.0, "Fed Chaos Mind");
			}
			catch (e)
			{
				if (!this.m.MoodWarningShown)
				{
					this.m.MoodWarningShown = true;
					::logWarning("Chaos Mind: could not improve the wielder's mood (" + e + ").");
				}
			}
		}

		if (milestone != null)
		{
			local text = "Chaos Mind grows stronger: +" + weapon.getKillBonus() + "% damage after " + weapon.m.Kills + " kills";

			if (milestone == "devourer")
			{
				text = "blade awakens as Chaos Mind, the Devourer, after " + weapon.m.Kills + " kills (+" + weapon.getKillBonus() + "% damage)";
			}
			else if (milestone == "ascended")
			{
				text = "blade has gorged on " + weapon.m.Kills + " souls and changes its form (+" + weapon.getKillBonus() + "% damage)";
			}
			::logInfo("Chaos Mind: " + text);

			try
			{
				::Tactical.EventLog.log(::Const.UI.getColorizedEntityName(user) + "'s " + text);
			}
			catch (e)
			{
			}

			user.getSkills().update();
		}
	}

	// Remember where the target stands, since it may be dead by the time onTargetHit runs.
	function onBeforeTargetHit( _skill, _targetEntity, _hitInfo )
	{
		if (this.isChaosMindAttack(_skill) && _targetEntity.isPlacedOnMap())
		{
			this.m.TargetTile = _targetEntity.getTile();
			this.m.HitpointsBefore[_targetEntity.getID()] <- _targetEntity.getHitpoints();
		}
	}

	function onTargetHit( _skill, _targetEntity, _bodyPart, _damageInflictedHitpoints, _damageInflictedArmor )
	{
		if (!this.isChaosMindAttack(_skill) || this.m.TargetTile == null)
		{
			return;
		}

		local targetTile = this.m.TargetTile;
		this.m.TargetTile = null;

		local total = _damageInflictedHitpoints + _damageInflictedArmor;

		if (total <= 0)
		{
			return;
		}

		local user = this.getContainer().getActor();
		local userTile = user.getTile();

		this.spawnCloud(targetTile);

		// Collect first, then apply, so deaths during the loop don't disturb it.
		local victims = [];

		foreach (faction in this.Tactical.Entities.getAllInstances())
		{
			foreach (actor in faction)
			{
				if (actor.getID() == user.getID() || actor.getID() == _targetEntity.getID())
				{
					continue;
				}

				// Chaos Protection: untouched by the black cloud and the curse.
				if (::ChaosMind.isProtected(actor))
				{
					continue;
				}

				if (!actor.isAlive() || actor.isDying() || !actor.isPlacedOnMap())
				{
					continue;
				}

				local tile = actor.getTile();
				local damage = 0.0;

				// Black cloud: everyone near the target, friend or foe.
				local cloudDistance = tile.getDistanceTo(targetTile);

				if (cloudDistance == 1)
				{
					damage += total * 0.5;
				}
				else if (cloudDistance == 2)
				{
					damage += total * 0.25;
				}

				// Curse: the wielder's own allies near him.
				if (actor.isAlliedWith(user) && tile.getDistanceTo(userTile) <= 2)
				{
					damage += total * 2.0;
				}

				if (damage >= 1.0)
				{
					victims.push({ Actor = actor, Damage = this.Math.floor(damage) });
				}
			}
		}

		foreach (v in victims)
		{
			if (!v.Actor.isAlive() || v.Actor.isDying())
			{
				continue;
			}

			this.m.HitpointsBefore[v.Actor.getID()] <- v.Actor.getHitpoints();

			local hitInfo = clone this.Const.Tactical.HitInfo;
			hitInfo.DamageRegular = v.Damage;
			hitInfo.DamageArmor = v.Damage;
			hitInfo.DamageDirect = 0.0;
			hitInfo.BodyPart = this.Const.BodyPart.Body;
			hitInfo.BodyDamageMult = 1.0;
			hitInfo.FatalityChanceMult = 0.0;
			v.Actor.onDamageReceived(user, this, hitInfo);
		}
	}

	function spawnCloud( _centerTile )
	{
		local particles = ::ChaosMind.getCloudParticles();

		if (particles == null)
		{
			return;
		}

		// The target's tile plus every tile up to 2 steps away.
		local tiles = [ _centerTile ];
		local seen = {};
		seen[_centerTile.SquareCoords.X + "," + _centerTile.SquareCoords.Y] <- true;
		local frontier = [ _centerTile ];

		for (local ring = 0; ring < 2; ++ring)
		{
			local next = [];

			foreach (tile in frontier)
			{
				for (local dir = 0; dir < 6; ++dir)
				{
					if (!tile.hasNextTile(dir))
					{
						continue;
					}

					local n = tile.getNextTile(dir);
					local key = n.SquareCoords.X + "," + n.SquareCoords.Y;

					if (key in seen)
					{
						continue;
					}

					seen[key] <- true;
					tiles.push(n);
					next.push(n);
				}
			}

			frontier = next;
		}

		try
		{
			foreach (tile in tiles)
			{
				foreach (p in particles)
				{
					this.Tactical.spawnParticleEffect(false, p.Brushes, tile, p.Delay, p.Quantity, p.LifeTimeQuantity, p.SpawnRate, p.Stages, this.createVec(0, 0));
				}
			}
		}
		catch (e)
		{
			::logWarning("Chaos Mind: Chaos Mind cloud could not be drawn (" + e + ").");
		}
	}

});
