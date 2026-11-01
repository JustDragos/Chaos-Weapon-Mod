// Armor Fixer (::ChaosMind.ArmorFixer): carried in a bag slot, grants actives.armor_fixer.
// Single use: 3 AP to repair up to 50 armor. Sold by every armorer.
this.armor_fixer_item <- this.inherit("scripts/items/item", {
	m = {
		Tag = 0
	},
	function create()
	{
		this.item.create();
		this.m.ID = "misc.armor_fixer";
		this.m.Name = "Armor Fixer";
		this.m.Description = "A pouch of rivets, leather straps, a hammer and a few patches of plate, packed by an armorer for mending on the field. Enough for one hasty repair in the thick of battle.";
		this.m.Icon = "misc/armor_fixer.png";
		this.m.SlotType = this.Const.ItemSlot.Bag;
		// Usable if the game has it; otherwise Tool (confirmed: carried in bags, like fire pots).
		this.m.ItemType = ("Usable" in this.Const.Items.ItemType) ? this.Const.Items.ItemType.Usable : this.Const.Items.ItemType.Tool;
		this.m.IsDroppedAsLoot = true;
		this.m.Value = 300;
		::ChaosMind.ArmorFixer.NextTag += 1;
		this.m.Tag = ::ChaosMind.ArmorFixer.NextTag;
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
		ret.push({
			id = 10,
			type = "text",
			icon = "ui/icons/armor_body.png",
			text = "Repairs up to [color=" + this.Const.UI.Color.PositiveValue + "]" + ::ChaosMind.ArmorFixer.Repair + "[/color] armor: body armor first, the rest to the helmet"
		});
		ret.push({
			id = 11,
			type = "text",
			icon = "ui/icons/action_points.png",
			text = "Costs [color=" + this.Const.UI.Color.NegativeValue + "]3[/color] AP to use in battle. Single use"
		});
		ret.push({
			id = 12,
			type = "text",
			icon = "ui/icons/bag.png",
			text = "Must be carried in a bag slot"
		});

		return ret;
	}

	function onEquip()
	{
		this.item.onEquip();
		this.addSkill(::new("scripts/skills/actives/armor_fixer_skill"));
	}
});
