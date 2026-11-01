// Given by the Soul Arrow for the rest of the turn: maximum AP +3, so the 3 points it grants
// fit even at full AP. The property name couldn't be confirmed in the encrypted scripts; the
// arrow's log line ("before -> after AP") shows whether it worked.
this.soul_arrow_effect <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "effects.soul_arrow";
		this.m.Name = "Soul Arrow";
		this.m.Icon = "skills/chaos_mind/soul_arrow.png";
		this.m.IconMini = "";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsRemovedAfterBattle = true;
		this.m.IsSerialized = false;
	}

	function getDescription()
	{
		return "Borrowed strength from the Soul Arrow. It fades when this turn ends.";
	}

	function getTooltip()
	{
		return [
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
				id = 10,
				type = "text",
				icon = "ui/icons/action_points.png",
				text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" + ::ChaosMind.SoulArrow.BonusAP + "[/color] Action Points this turn"
			}
		];
	}

	function onUpdate( _properties )
	{
		if ("ActionPoints" in _properties)
		{
			_properties.ActionPoints += ::ChaosMind.SoulArrow.BonusAP;
		}
	}

	function onTurnEnd()
	{
		this.removeSelf();
	}
});
