// Aura of 10 (::ChaosMind.Aura): the reward for hunting The Ten. While a brother wears it, the
// company counts as a company of ten on the world map, so weak parties keep away.
this.aura_of_10_item <- this.inherit("scripts/items/accessory/accessory", {
	m = {},
	function create()
	{
		this.accessory.create();
		this.m.ID = "accessory.aura_of_10";
		this.m.Name = "Aura of 10";
		this.m.Description = "A gold medallion taken from The Ten. Whoever wears it never walks alone: ten pale spirits march at his back, and from afar every eye counts them as men.";
		this.m.SlotType = this.Const.ItemSlot.Accessory;
		this.m.IsDroppedAsLoot = true;
		this.m.ShowOnCharacter = false;
		this.m.IconLarge = "";
		this.m.Icon = "accessory/aura_of_10.png";
		this.m.Value = 5000;
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
				id = 66,
				type = "text",
				text = this.getValueString()
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
				text = "On the world map the company counts as at least a company of ten seasoned men (strength [color=" + this.Const.UI.Color.PositiveValue + "]" + ::ChaosMind.Aura.CompanyStrength + "[/color]), so small and weak parties don't attack and keep away"
			},
			{
				id = 11,
				type = "text",
				icon = "ui/icons/warning.png",
				text = "Only while a brother wears it"
			}
		];

		return ret;
	}
});
