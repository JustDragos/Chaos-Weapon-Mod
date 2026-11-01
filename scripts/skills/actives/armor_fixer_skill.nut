// Granted by an Armor Fixer in a bag slot. 3 AP: repairs up to 50 armor on the user (body
// armor first, then the helmet), then the Armor Fixer is used up. Stacks: each Armor Fixer in
// the bag has its own button and uses up its own item.
this.armor_fixer_skill <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "actives.armor_fixer";
		this.m.Name = "Use Armor Fixer";
		this.m.Description = "Hammer the worst dents out, lace the torn straps and rivet a patch over the gap. Not pretty, but it will hold.";
		this.m.Icon = "skills/chaos_mind/armor_fixer.png";
		this.m.IconDisabled = "skills/chaos_mind/armor_fixer_sw.png";
		this.m.Overlay = "active_118";
		this.m.SoundOnUse = [];
		this.m.Type = this.Const.SkillType.Active;
		this.m.Order = ("Any" in this.Const.SkillOrder) ? this.Const.SkillOrder.Any : this.Const.SkillOrder.Last;
		this.m.IsSerialized = false;
		this.m.IsActive = true;
		this.m.IsTargeted = false;
		this.m.IsStacking = true;
		this.m.IsAttack = false;
		this.m.ActionPointCost = 3;
		this.m.FatigueCost = 0;
		this.m.MinRange = 0;
		this.m.MaxRange = 0;
	}

	function getTooltip()
	{
		local actor = this.getContainer().getActor();
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
				type = "text",
				text = this.getCostString()
			},
			{
				id = 10,
				type = "text",
				icon = "ui/icons/armor_body.png",
				text = "Repairs up to [color=" + this.Const.UI.Color.PositiveValue + "]" + ::ChaosMind.ArmorFixer.Repair + "[/color] armor: body armor first, the rest to the helmet"
			},
			{
				id = 11,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Single use: the Armor Fixer is used up"
			}
		];

		if (::ChaosMind.ArmorFixer.getMissing(actor) == 0)
		{
			ret.push({
				id = 12,
				type = "text",
				icon = "ui/tooltips/warning.png",
				text = "[color=" + this.Const.UI.Color.NegativeValue + "]Nothing to repair[/color]"
			});
		}

		return ret;
	}

	function isUsable()
	{
		return this.skill.isUsable() && ::ChaosMind.ArmorFixer.getMissing(this.getContainer().getActor()) > 0;
	}

	// This skill's own Armor Fixer in the user's bag, found by its tag (getItem() is a weak
	// reference, which the item container can't match against the real item).
	function findBagItem( _user )
	{
		local mine = this.getItem();

		if (mine == null)
		{
			return null;
		}

		local tag = mine.m.Tag;

		foreach (item in _user.getItems().getAllItemsAtSlot(this.Const.ItemSlot.Bag))
		{
			if (item != null && item.getID() == ::ChaosMind.ArmorFixer.ItemID && item.m.Tag == tag)
			{
				return item;
			}
		}

		return null;
	}

	function onUse( _user, _targetTile )
	{
		local repaired = ::ChaosMind.ArmorFixer.repair(_user);
		local text = "uses an Armor Fixer and repairs " + repaired + " armor";
		::logInfo("Chaos Mind: " + _user.getName() + " " + text);

		try
		{
			::Tactical.EventLog.log(::Const.UI.getColorizedEntityName(_user) + " " + text);
		}
		catch (e)
		{
		}

		try
		{
			local item = this.findBagItem(_user);
			local items = _user.getItems();

			if (item == null)
			{
				::logWarning("Chaos Mind: the used Armor Fixer could not be found in " + _user.getName() + "'s bag.");
			}
			else if ("removeFromBag" in items)
			{
				items.removeFromBag(item);
			}
			else
			{
				items.unequip(item);
			}
		}
		catch (e)
		{
			::logWarning("Chaos Mind: the used Armor Fixer could not be removed (" + e + ").");
		}

		return true;
	}
});
