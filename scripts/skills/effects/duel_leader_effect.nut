// The duel leader's strength from his squad's armor (::ChaosMind.Duel): every combat stat
// multiplied by 1 + Buff. Only exists in the duel itself.
this.duel_leader_effect <- this.inherit("scripts/skills/skill", {
	m = {
		Buff = 0.0
	},
	function create()
	{
		this.m.ID = "effects.duel_leader";
		this.m.Name = "Champion of His Men";
		this.m.Icon = "skills/status_effect_14.png";
		this.m.IconMini = "";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsRemovedAfterBattle = true;
		this.m.IsSerialized = false;
	}

	function getName()
	{
		return this.m.Name + " (+" + (this.m.Buff * 100).tointeger() + "%)";
	}

	function getDescription()
	{
		return "Every man in his band stands behind him. He fights this duel with the strength of all of them.";
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
				icon = "ui/icons/special.png",
				text = "[color=" + this.Const.UI.Color.NegativeValue + "]+" + (this.m.Buff * 100).tointeger() + "%[/color] Hitpoints, Melee and Ranged Skill, Melee and Ranged Defense, Resolve and damage"
			}
		];
	}

	function onUpdate( _properties )
	{
		local mult = 1.0 + this.m.Buff;

		foreach (name in [ "MeleeSkillMult", "RangedSkillMult", "MeleeDefenseMult", "RangedDefenseMult", "BraveryMult", "DamageTotalMult" ])
		{
			if (name in _properties)
			{
				_properties[name] *= mult;
			}
		}

		// No mod in reach uses HitpointsMult, so scale the base Hitpoints (confirmed) if it's missing.
		if ("HitpointsMult" in _properties)
		{
			_properties.HitpointsMult *= mult;
		}
		else
		{
			_properties.Hitpoints = ::Math.floor(_properties.Hitpoints * mult);
		}
	}
});
