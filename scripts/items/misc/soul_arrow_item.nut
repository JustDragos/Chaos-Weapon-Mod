// Soul Arrow (::ChaosMind.SoulArrow): goes in the ammo (quiver) slot and grants actives.soul_arrow:
// once per battle, +3 AP. Recharged after a battle for 15 ammo.
//
// A plain item, not a vanilla ammo item: built on scripts/items/ammo/ammo with 0 arrows it was
// invisible in the stash (1 Nov), however its icons were set. The ammo functions a bow or the
// game might call on whatever sits in the quiver slot are stubbed here: it holds no arrows, has
// no ammo type a bow accepts, and is never refilled by the game.
// The old ammo-based version (scripts/items/ammo/soul_arrow.nut) stays only so older saves load;
// ::ChaosMind.SoulArrow swaps it for this one.
this.soul_arrow_item <- this.inherit("scripts/items/item", {
	m = {
		IsCharged = true
	},
	function create()
	{
		this.item.create();
		this.m.ID = "ammo.soul_arrow";
		this.m.Name = "Soul Arrow";
		this.m.Description = "An arrow of pale violet light, the Devourer's gift for its hundredth soul.";
		this.m.Icon = "ammo/soul_arrow.png";
		this.m.SlotType = this.Const.ItemSlot.Ammo;
		this.m.ItemType = this.Const.Items.ItemType.Tool;
		this.m.Value = 2000;
		this.m.IsDroppedAsLoot = true;
	}

	function getIcon()
	{
		return this.m.IsCharged ? "ammo/soul_arrow.png" : "ammo/soul_arrow_empty.png";
	}

	// Kept so code shared with the old version can call it.
	function updateIcons()
	{
		this.m.Icon = this.getIcon();
	}

	// What a bow or the game may ask of the quiver slot: no arrows, nothing to refill.
	function getAmmo()
	{
		return 0;
	}

	function getAmmoMax()
	{
		return 0;
	}

	function getAmmoType()
	{
		return ("None" in this.Const.Items.AmmoType) ? this.Const.Items.AmmoType.None : -1;
	}

	function setAmmo( _a )
	{
	}

	function consumeAmmo()
	{
	}

	function getTooltip()
	{
		local sa = ::ChaosMind.SoulArrow;
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
			}
		];

		if ("getValueString" in this)
		{
			ret.push({
				id = 66,
				type = "text",
				text = this.getValueString()
			});
		}

		ret.push({
			id = 3,
			type = "image",
			image = this.getIcon()
		});
		// Kept short: the Chaos Guide explains recharging and the quiver slot.
		ret.push({
			id = 10,
			type = "text",
			icon = "ui/icons/action_points.png",
			text = "Once per battle: [color=" + this.Const.UI.Color.PositiveValue + "]+" + sa.BonusAP + "[/color] Action Points"
		});
		ret.push({
			id = 11,
			type = "text",
			icon = this.m.IsCharged ? "ui/icons/special.png" : "ui/tooltips/warning.png",
			text = this.m.IsCharged ? "Charged" : "[color=" + this.Const.UI.Color.NegativeValue + "]Spent: recharges after the next battle for " + sa.RefillCost + " ammo[/color]"
		});
		ret.push({
			id = 12,
			type = "text",
			icon = "ui/icons/special.png",
			text = "More in the Chaos Guide ([color=" + this.Const.UI.Color.PositiveValue + "]" + ::ChaosMind.getGuideKey() + "[/color])"
		});

		return ret;
	}

	function onEquip()
	{
		this.item.onEquip();
		this.addSkill(::new("scripts/skills/actives/soul_arrow_skill"));
	}

	function onSerialize( _out )
	{
		this.item.onSerialize(_out);
		_out.writeBool(this.m.IsCharged);
	}

	function onDeserialize( _in )
	{
		this.item.onDeserialize(_in);
		this.m.IsCharged = _in.readBool();
	}
});
