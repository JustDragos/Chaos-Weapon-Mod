// Energy fed to Chaos Mind's eye this battle, and how many times it has been unleashed.
this.carnal_storage_effect <- this.inherit("scripts/skills/skill", {
	m = {
		Energy = 0,
		Stacks = 0,
		Overflow = 0
	},
	function create()
	{
		this.m.ID = "effects.carnal_storage";
		this.m.Name = "Carnal Storage";
		this.m.Icon = "skills/chaos_mind/carnal_storage_effect.png";
		this.m.IconMini = "";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsRemovedAfterBattle = true;
		this.m.IsSerialized = false;
	}

	function getDescription()
	{
		return "The eye of Chaos Mind holds the offerings of this character's body, ready to be turned into destructive force.";
	}

	function getTooltip()
	{
		local cs = ::ChaosMind.CarnalStorage;
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
				id = 10,
				type = "text",
				icon = "ui/icons/special.png",
				text = "[color=" + this.Const.UI.Color.PositiveValue + "]" + this.m.Energy + "[/color] energy stored"
			}
		];

		if (this.m.Stacks > 0)
		{
			ret.push({
				id = 11,
				type = "text",
				icon = "ui/icons/regular_damage.png",
				text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" + (this.getDamageBonus() * 100).tointeger() + "%[/color] damage (unleashed " + this.m.Stacks + "/" + cs.MaxStacks
					+ (this.m.Overflow > 0 ? ", overflow +" + (this.m.Overflow * cs.OverflowDamage * 100).tointeger() + "%" : "") + ")"
			});
		}

		if (this.m.Stacks >= cs.MaxStacks)
		{
			ret.push({
				id = 12,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Every " + cs.OverflowCost + " energy adds +" + (cs.OverflowDamage * 100).tointeger() + "% damage (next in " + (cs.OverflowCost - this.m.Energy) + ")"
			});
		}

		return ret;
	}

	// Unleash stacks (+25% each) plus overflow (+1% per 150 energy once fully unleashed).
	function getDamageBonus()
	{
		local cs = ::ChaosMind.CarnalStorage;
		return this.m.Stacks * cs.DamagePerStack + this.m.Overflow * cs.OverflowDamage;
	}

	function onUpdate( _properties )
	{
		local bonus = this.getDamageBonus();

		if (bonus > 0)
		{
			_properties.DamageTotalMult *= 1.0 + bonus;
		}
	}

});
