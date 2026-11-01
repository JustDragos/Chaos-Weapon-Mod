// Granted by Chaos Mind. Cut an adjacent brother with a full Chaos Mind strike: the hitpoints
// he loses are stored as Carnal Storage energy. No hit roll, ignores armor, always kills (and the
// kill counts for Chaos Mind); no black cloud or curse.
this.brother_sacrifice_skill <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "actives.brother_sacrifice";
		this.m.Name = "Brother Sacrifice";
		this.m.Description = "Turn the blade on a brother-in-arms and let the eye drink. His blood becomes energy for Carnal Storage. Few forgive this, and none survive it.";
		this.m.Icon = "skills/chaos_mind/brother_sacrifice.png";
		this.m.IconDisabled = "skills/chaos_mind/brother_sacrifice_sw.png";
		this.m.Overlay = "active_175";
		this.m.SoundOnUse = [];
		this.m.Type = this.Const.SkillType.Active;
		this.m.Order = ("Any" in this.Const.SkillOrder) ? this.Const.SkillOrder.Any : this.Const.SkillOrder.Last;
		this.m.IsSerialized = false;
		this.m.IsActive = true;
		this.m.IsTargeted = true;
		this.m.IsStacking = false;
		this.m.IsAttack = false;
		this.m.ActionPointCost = 4;
		this.m.FatigueCost = 10;
		this.m.MinRange = 1;
		this.m.MaxRange = 1;
	}

	function getTooltip()
	{
		local per = ::ChaosMind.CarnalStorage.HitpointsPerEnergy;

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
				text = "Kills an adjacent brother. Nothing saves him"
			},
			{
				id = 11,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Every [color=" + this.Const.UI.Color.NegativeValue + "]" + per + "[/color] hitpoints he loses become 1 energy"
			},
			{
				id = 12,
				type = "text",
				icon = "ui/tooltips/warning.png",
				text = "A slain brother counts as a Chaos Mind kill"
			}
		];
	}

	function onVerifyTarget( _originTile, _targetTile )
	{
		if (!_targetTile.IsOccupiedByActor)
		{
			return false;
		}

		local user = this.getContainer().getActor();
		local target = _targetTile.getEntity();

		// Brothers with Chaos Protection can't be sacrificed.
		return target != null && target.getID() != user.getID() && target.isAlliedWith(user) && !::ChaosMind.isProtected(target);
	}

	function onUse( _user, _targetTile )
	{
		local cs = ::ChaosMind.CarnalStorage;
		local target = _targetTile.getEntity();

		if (target == null)
		{
			return false;
		}

		local name = target.getName();
		local lost = cs.strikeBrother(_user, target, this);
		local died = !target.isAlive() || target.isDying();

		cs.addEnergy(_user, ::Math.floor(lost / cs.HitpointsPerEnergy),
			"sacrifices " + name + (died ? ", who dies," : "") + " (" + lost + " hitpoints)");
		::ChaosMind.OnlyChaos.onSacrifice(_user);

		return true;
	}

});
