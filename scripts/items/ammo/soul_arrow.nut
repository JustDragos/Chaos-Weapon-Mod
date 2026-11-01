// OLD VERSION, kept only so saves that hold it still load: it was invisible in the stash.
// ::ChaosMind.SoulArrow.migrateOld swaps it for scripts/items/misc/soul_arrow_item.
//
// Soul Arrow (::ChaosMind.SoulArrow): sits in the ammo slot but holds no arrows, so no bow or
// crossbow can shoot it and the game's own ammo refill ignores it. Grants actives.soul_arrow:
// once per battle, +3 AP. Recharged after a battle for 15 ammo.
this.soul_arrow <- this.inherit("scripts/items/ammo/ammo", {
	m = {
		IsCharged = true
	},
	function create()
	{
		this.ammo.create();
		this.m.ID = "ammo.soul_arrow";
		this.m.Name = "Soul Arrow";
		this.m.Description = "A single arrow of pale violet light that was never fletched by any hand. The Devourer gave it up after its hundredth soul. Drawing it pulls something back out of the dark: breath, will, a few more heartbeats of strength.";
		this.m.Icon = "ammo/soul_arrow.png";
		this.m.IconEmpty = "ammo/soul_arrow.png";

		if ("None" in this.Const.Items.AmmoType)
		{
			this.m.AmmoType = this.Const.Items.AmmoType.None;
		}

		this.m.Ammo = 0;
		this.m.AmmoMax = 0;
		this.m.Value = 2000;
		this.m.IsDroppedAsLoot = true;
	}

	// The game draws an ammo item with IconEmpty whenever it holds no ammo, which this one never
	// does: both fields must follow the charge, or it shows with no picture (31 Oct bug).
	function updateIcons()
	{
		this.m.Icon = this.m.IsCharged ? "ammo/soul_arrow.png" : "ammo/soul_arrow_empty.png";
		this.m.IconEmpty = this.m.Icon;
	}

	function getIcon()
	{
		this.updateIcons();
		return this.m.Icon;
	}

	function getTooltip()
	{
		local sa = ::ChaosMind.SoulArrow;

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
				type = "image",
				image = this.getIcon()
			},
			{
				id = 10,
				type = "text",
				icon = "ui/icons/action_points.png",
				text = "Once per battle: [color=" + this.Const.UI.Color.PositiveValue + "]+" + sa.BonusAP + "[/color] Action Points, for [color=" + this.Const.UI.Color.NegativeValue + "]20[/color] fatigue"
			},
			{
				id = 11,
				type = "text",
				icon = "ui/icons/ammo.png",
				text = "Recharges after a battle for [color=" + this.Const.UI.Color.NegativeValue + "]" + sa.RefillCost + "[/color] ammo from the company's supplies"
			},
			{
				id = 12,
				type = "text",
				icon = this.m.IsCharged ? "ui/icons/special.png" : "ui/tooltips/warning.png",
				text = this.m.IsCharged ? "Charged" : "[color=" + this.Const.UI.Color.NegativeValue + "]Spent: recharges after the next battle[/color]"
			},
			{
				id = 13,
				type = "text",
				icon = "ui/tooltips/warning.png",
				text = "Holds no arrows or bolts: takes the place of a quiver"
			}
		];
	}

	function onEquip()
	{
		this.ammo.onEquip();
		this.addSkill(::new("scripts/skills/actives/soul_arrow_skill"));
	}

	function onSerialize( _out )
	{
		this.ammo.onSerialize(_out);
		_out.writeBool(this.m.IsCharged);
	}

	function onDeserialize( _in )
	{
		this.ammo.onDeserialize(_in);
		this.m.IsCharged = _in.readBool();
		this.updateIcons();
	}
});
