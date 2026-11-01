// Granted by the Soul Arrow in the ammo slot. Once per battle, 0 AP and 20 fatigue: +3 AP this turn
// (effects.soul_arrow raises the maximum so the extra points aren't cut off).
this.soul_arrow_skill <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "actives.soul_arrow";
		this.m.Name = "Soul Arrow";
		this.m.Description = "Draw the Soul Arrow and drink what it carries. Strength floods back into tired limbs, for a moment.";
		this.m.Icon = "skills/chaos_mind/soul_arrow.png";
		this.m.IconDisabled = "skills/chaos_mind/soul_arrow_sw.png";
		this.m.Overlay = "active_118";
		this.m.SoundOnUse = [];
		this.m.Type = this.Const.SkillType.Active;
		this.m.Order = ("Any" in this.Const.SkillOrder) ? this.Const.SkillOrder.Any : this.Const.SkillOrder.Last;
		this.m.IsSerialized = false;
		this.m.IsActive = true;
		this.m.IsTargeted = false;
		this.m.IsStacking = false;
		this.m.IsAttack = false;
		this.m.ActionPointCost = 0;
		this.m.FatigueCost = ::ChaosMind.SoulArrow.FatigueCost;
		this.m.MinRange = 0;
		this.m.MaxRange = 0;
	}

	function getArrow()
	{
		local item = this.getItem();
		return (item != null && item.getID() == "ammo.soul_arrow") ? item : null;
	}

	function getTooltip()
	{
		local arrow = this.getArrow();
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
				icon = "ui/icons/action_points.png",
				text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" + ::ChaosMind.SoulArrow.BonusAP + "[/color] Action Points this turn"
			},
			{
				id = 11,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Once per battle. Recharges after the battle for " + ::ChaosMind.SoulArrow.RefillCost + " ammo"
			}
		];

		if (arrow != null && !arrow.m.IsCharged)
		{
			ret.push({
				id = 12,
				type = "text",
				icon = "ui/tooltips/warning.png",
				text = "[color=" + this.Const.UI.Color.NegativeValue + "]Spent[/color]"
			});
		}

		return ret;
	}

	function isUsable()
	{
		local arrow = this.getArrow();
		return this.skill.isUsable() && arrow != null && arrow.m.IsCharged;
	}

	function onUse( _user, _targetTile )
	{
		local arrow = this.getArrow();

		if (arrow == null || !arrow.m.IsCharged)
		{
			return false;
		}

		arrow.m.IsCharged = false;
		arrow.updateIcons();

		local before = _user.getActionPoints();
		_user.getSkills().add(::new("scripts/skills/effects/soul_arrow_effect"));
		_user.setActionPoints(before + ::ChaosMind.SoulArrow.BonusAP);
		_user.setDirty(true);

		local text = "draws the Soul Arrow: " + before + " -> " + _user.getActionPoints() + " AP";
		::logInfo("Chaos Mind: " + _user.getName() + " " + text);

		try
		{
			::Tactical.EventLog.log(::Const.UI.getColorizedEntityName(_user) + " " + text);
		}
		catch (e)
		{
		}

		return true;
	}

	function onCombatFinished()
	{
		::ChaosMind.SoulArrow.refill(this.getArrow());
	}
});
