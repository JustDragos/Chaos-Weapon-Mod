// Granted by Chaos Mind. Strikes every brother in the cells around the wielder with a full
// Chaos Mind strike (as Brother Sacrifice) that always kills; all hitpoints they lose become energy.
this.mass_sacrifice_skill <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "actives.mass_sacrifice";
		this.m.Name = "Mass Sacrifice";
		this.m.Description = "Spin the blade through everyone who stands beside you. The eye drinks from every one of them at once.";
		this.m.Icon = "skills/chaos_mind/mass_sacrifice.png";
		this.m.IconDisabled = "skills/chaos_mind/mass_sacrifice_sw.png";
		this.m.Overlay = "active_175";
		this.m.SoundOnUse = [];
		this.m.Type = this.Const.SkillType.Active;
		this.m.Order = ("Any" in this.Const.SkillOrder) ? this.Const.SkillOrder.Any : this.Const.SkillOrder.Last;
		this.m.IsSerialized = false;
		this.m.IsActive = true;
		this.m.IsTargeted = false;
		this.m.IsStacking = false;
		this.m.IsAttack = false;
		this.m.ActionPointCost = 6;
		this.m.FatigueCost = 25;
		this.m.MinRange = 0;
		this.m.MaxRange = 0;
	}

	function getTooltip()
	{
		local cs = ::ChaosMind.CarnalStorage;
		local actor = this.getContainer().getActor();
		local count = cs.getAdjacentBrothers(actor).len();

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
				icon = "ui/icons/regular_damage.png",
				text = "Kills every adjacent brother. Nothing saves them"
			},
			{
				id = 11,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Every [color=" + this.Const.UI.Color.NegativeValue + "]" + cs.HitpointsPerEnergy + "[/color] hitpoints they lose become 1 energy"
			},
			{
				id = 12,
				type = "text",
				icon = "ui/tooltips/warning.png",
				text = "Slain brothers count as Chaos Mind kills"
			},
			{
				id = 13,
				type = "text",
				icon = "ui/icons/kills.png",
				text = count + (count == 1 ? " brother" : " brothers") + " in reach"
			}
		];
	}

	function isUsable()
	{
		return this.skill.isUsable() && ::ChaosMind.CarnalStorage.getAdjacentBrothers(this.getContainer().getActor()).len() > 0;
	}

	function onUse( _user, _targetTile )
	{
		local cs = ::ChaosMind.CarnalStorage;
		local brothers = cs.getAdjacentBrothers(_user);

		if (brothers.len() == 0)
		{
			return false;
		}

		local totalLost = 0;
		local deaths = 0;

		foreach (brother in brothers)
		{
			if (!brother.isAlive() || brother.isDying())
			{
				continue;
			}

			totalLost += cs.strikeBrother(_user, brother, this);

			if (!brother.isAlive() || brother.isDying())
			{
				deaths += 1;
			}
		}

		cs.addEnergy(_user, ::Math.floor(totalLost / cs.HitpointsPerEnergy),
			"sacrifices " + brothers.len() + (brothers.len() == 1 ? " brother" : " brothers")
				+ (deaths > 0 ? " (" + deaths + " slain)" : "") + ", " + totalLost + " hitpoints");
		::ChaosMind.OnlyChaos.onSacrifice(_user);

		return true;
	}

});
