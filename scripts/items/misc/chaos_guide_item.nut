// Chaos Guide (::ChaosMind.Guide): a book that explains every item and perk of this mod in full.
// Given with Chaos Mind, and given back whenever the blade kills and the company has none.
// Stash only. Right-click it (with a brother selected) or press Ctrl+G to read it; neither uses it up.
this.chaos_guide_item <- this.inherit("scripts/items/item", {
	m = {},
	function create()
	{
		this.item.create();
		this.m.ID = "misc.chaos_guide";
		this.m.Name = "Chaos Guide";
		this.m.Description = "A violet-bound book that was never written by any hand. Its pages fill themselves with everything the blade is, and everything it asks.";
		this.m.Icon = "misc/chaos_guide.png";
		// Stash only: it can't be equipped or carried in a bag.
		if ("None" in this.Const.ItemSlot)
		{
			this.m.SlotType = this.Const.ItemSlot.None;
		}
		this.m.ItemType = ("Misc" in this.Const.Items.ItemType) ? this.Const.Items.ItemType.Misc : this.Const.Items.ItemType.Tool;
		this.m.Value = 0;

		// Right-clicking a usable item in the stash calls onUse. Guarded: the name couldn't be
		// confirmed in the encrypted scripts; Ctrl+G opens the guide either way.
		if ("IsUsable" in this.m)
		{
			this.m.IsUsable = true;
		}
	}

	function getTooltip()
	{
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
				type = "image",
				image = this.getIcon()
			},
			{
				id = 10,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Explains Chaos Mind, its skills, the Soul Arrow, the Armor Fixer and every Chaos perk in full"
			},
			{
				id = 11,
				type = "text",
				icon = "ui/icons/mouse_right_button.png",
				text = "Right-click to read, or press [color=" + this.Const.UI.Color.PositiveValue + "]" + ::ChaosMind.getGuideKey() + "[/color] on the map or in battle"
			},
			{
				id = 12,
				type = "text",
				icon = "ui/icons/kills.png",
				text = "Lost or sold, it returns to the stash with Chaos Mind's next kill"
			}
		];

		return ret;
	}

	// Reading doesn't use it up.
	function onUse( _actor, _item = null )
	{
		::ChaosMind.Guide.open();
		return false;
	}
});
