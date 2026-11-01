// Granted by Chaos Mind. Opens the Carnal Storage window; the sacrifices themselves
// happen in ::ChaosMind.CarnalStorage (chaos_mind/carnal_storage.nut).
this.carnal_storage_skill <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "actives.carnal_storage";
		this.m.Name = "Carnal Storage";
		this.m.Description = "The eye in the crossguard hungers. Feed it with your exhaustion, your blood or your flesh, and it stores the offering as energy that can be unleashed as raw destructive force.";
		this.m.Icon = "skills/chaos_mind/carnal_storage.png";
		this.m.IconDisabled = "skills/chaos_mind/carnal_storage_sw.png";
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
		this.m.FatigueCost = 0;
		this.m.MinRange = 0;
		this.m.MaxRange = 0;
	}

	function getTooltip()
	{
		local cs = ::ChaosMind.CarnalStorage;
		local effect = this.getContainer().getSkillByID("effects.carnal_storage");
		local energy = effect == null ? 0 : effect.m.Energy;
		local stacks = effect == null ? 0 : effect.m.Stacks;

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
				id = 3,
				type = "text",
				text = this.getCostString()
			},
			{
				id = 10,
				type = "text",
				icon = "ui/icons/fatigue.png",
				text = "Fatigue: [color=" + this.Const.UI.Color.NegativeValue + "]" + cs.FatiguePerEnergy + "[/color] fatigue per energy"
			},
			{
				id = 11,
				type = "text",
				icon = "ui/icons/health.png",
				text = "Blood: [color=" + this.Const.UI.Color.NegativeValue + "]" + cs.HitpointsPerEnergy + "[/color] hitpoints per energy"
			},
			{
				id = 12,
				type = "text",
				icon = "ui/icons/days_wounded.png",
				text = "Flesh: one minor injury for [color=" + this.Const.UI.Color.PositiveValue + "]" + cs.InjuryEnergy + "[/color] energy"
			},
			{
				id = 13,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Unleash: spend " + cs.UnleashCost + " energy for [color=" + this.Const.UI.Color.PositiveValue + "]+" + (cs.DamagePerStack * 100).tointeger() + "%[/color] damage until the end of the battle (up to " + cs.MaxStacks + " times)"
			},
			{
				id = 14,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Once fully unleashed, every " + cs.OverflowCost + " energy adds [color=" + this.Const.UI.Color.PositiveValue + "]+" + (cs.OverflowDamage * 100).tointeger() + "%[/color] damage"
			},
			{
				id = 15,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Stored: [color=" + this.Const.UI.Color.PositiveValue + "]" + energy + "[/color] energy, unleashed " + stacks + "/" + cs.MaxStacks
			}
		];
	}

	function onUse( _user, _targetTile )
	{
		::ChaosMind.CarnalStorage.open(_user);
		return true;
	}

});
