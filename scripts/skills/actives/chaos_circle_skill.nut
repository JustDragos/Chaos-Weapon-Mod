// Granted by the Chaos Circle perk, usable only while wielding Chaos Mind. Up to 5 tiles away,
// opens a 7-tile circle for 3 rounds: everyone inside hears a Geist's Horrific Scream, and
// anyone standing in it is slowed (::ChaosMind.ChaosCircle). 3-turn cooldown.
this.chaos_circle_skill <- this.inherit("scripts/skills/skill", {
	m = {
		Cooldown = 3,
		TurnsLeft = 0
	},
	function create()
	{
		this.m.ID = "actives.chaos_circle";
		this.m.Name = "Chaos Circle";
		this.m.Description = "Drive the blade's hunger into the earth and tear it open. The dead claw up through the ring, and their wailing breaks the minds of all who stand in it.";
		this.m.Icon = "skills/chaos_mind/chaos_circle.png";
		this.m.IconDisabled = "skills/chaos_mind/chaos_circle_sw.png";
		this.m.Overlay = "active_118";
		this.m.SoundOnUse = [];
		this.m.Type = this.Const.SkillType.Active;
		this.m.Order = ("UtilityTargeted" in this.Const.SkillOrder) ? this.Const.SkillOrder.UtilityTargeted : this.Const.SkillOrder.Any;
		this.m.IsSerialized = false;
		this.m.IsActive = true;
		this.m.IsTargeted = true;
		this.m.IsTargetingActor = false;
		this.m.IsVisibleTileNeeded = true;
		this.m.IsStacking = false;
		this.m.IsAttack = false;
		this.m.ActionPointCost = 6;
		this.m.FatigueCost = 30;
		this.m.MinRange = 1;
		this.m.MaxRange = 5;
	}

	function isWieldingChaosMind()
	{
		if (this.getContainer() == null)
		{
			return false;
		}

		local weapon = this.getContainer().getActor().getMainhandItem();
		return weapon != null && weapon.getID() == ::ChaosMind.SwordID;
	}

	function getTooltip()
	{
		local cc = ::ChaosMind.ChaosCircle;
		local resolve = this.getContainer() != null ? "" + this.getContainer().getActor().getCurrentProperties().getBravery() : "?";
		local ret = [
			{
				id = 1,
				type = "title",
				text = this.getName()
			},
			{
				id = 2,
				type = "description",
				text = this.getDescription()
			},
			{
				id = 3,
				type = "text",
				text = this.getCostString()
			},
			{
				id = 10,
				type = "text",
				icon = "ui/icons/vision.png",
				text = "Range of [color=" + this.Const.UI.Color.PositiveValue + "]" + this.m.MaxRange + "[/color] tiles; the circle covers the target tile and the 6 around it for " + cc.Rounds + " rounds"
			},
			{
				id = 11,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Everyone inside, friend or foe, hears the Horrific Scream of a Geist. Those less resolute than you ([color=" + this.Const.UI.Color.PositiveValue + "]" + resolve + "[/color]) resist it worse, by the gap between you: the full gap in the centre, half on the ring"
			},
			{
				id = 12,
				type = "text",
				icon = "ui/icons/action_points.png",
				text = "Anyone standing in it pays [color=" + this.Const.UI.Color.NegativeValue + "]+" + cc.MoveAPCost + "[/color] AP and [color=" + this.Const.UI.Color.NegativeValue + "]+" + cc.MoveFatigueCost + "[/color] fatigue per tile moved"
			},
			{
				id = 13,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Can be used once every " + this.m.Cooldown + " turns. Spares you and anyone with Chaos Protection"
			}
		];

		if (!this.isWieldingChaosMind())
		{
			ret.push({
				id = 14,
				type = "text",
				icon = "ui/tooltips/warning.png",
				text = "[color=" + this.Const.UI.Color.NegativeValue + "]Requires Chaos Mind in hand[/color]"
			});
		}

		if (this.m.TurnsLeft > 0)
		{
			ret.push({
				id = 15,
				type = "text",
				icon = "ui/tooltips/warning.png",
				text = "[color=" + this.Const.UI.Color.NegativeValue + "]Ready again in " + this.m.TurnsLeft + (this.m.TurnsLeft == 1 ? " turn" : " turns") + "[/color]"
			});
		}

		return ret;
	}

	function isUsable()
	{
		return this.skill.isUsable() && this.m.TurnsLeft == 0 && this.isWieldingChaosMind();
	}

	function onVerifyTarget( _originTile, _targetTile )
	{
		return true;
	}

	// Marks all 7 tiles while aiming.
	function onTargetSelected( _targetTile )
	{
		try
		{
			// "mortar_target_02" is a known overlay (the Legends mod marks knockback tiles with it).
			local icon = ("AreaOfEffectIcon" in this.Const.Tactical.Settings) ? this.Const.Tactical.Settings.AreaOfEffectIcon : "mortar_target_02";

			foreach (tile in ::ChaosMind.ChaosCircle.getTiles(_targetTile))
			{
				this.Tactical.getHighlighter().addOverlayIcon(icon, tile, tile.Pos.X, tile.Pos.Y);
			}
		}
		catch (e)
		{
		}
	}

	function onUse( _user, _targetTile )
	{
		::ChaosMind.ChaosCircle.cast(_user, _targetTile);
		this.m.TurnsLeft = this.m.Cooldown;
		return true;
	}

	function onTurnStart()
	{
		if (this.m.TurnsLeft > 0)
		{
			this.m.TurnsLeft -= 1;
		}
	}

	function onNewRound()
	{
		::ChaosMind.ChaosCircle.onNewRound(this.getContainer().getActor());
	}

	function onCombatStarted()
	{
		this.m.TurnsLeft = 0;
		::ChaosMind.ChaosCircle.reset();
	}

	function onCombatFinished()
	{
		this.m.TurnsLeft = 0;
		::ChaosMind.ChaosCircle.reset();
	}
});
