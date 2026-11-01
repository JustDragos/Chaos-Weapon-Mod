// Armor Fixer: a single-use bag item (scripts/items/misc/armor_fixer_item.nut) that grants
// actives.armor_fixer: 3 AP, repairs up to 50 armor (body armor first, the rest to the helmet,
// never above maximum), then is used up. Every armorer (north and south) stocks it, up to 3,
// each time its shop list refreshes (see the hook at the bottom).
::ChaosMind.ArmorFixer <- {
    ItemID = "misc.armor_fixer",
    Repair = 50,
    StockCount = 3,
    SetterWarningShown = false,
    // Each item gets its own tag so its skill can find and use up that exact item.
    NextTag = 0,

    // Body armor first, then the helmet.
    Parts = [
        { Slot = ::Const.ItemSlot.Body, Part = ::Const.BodyPart.Body },
        { Slot = ::Const.ItemSlot.Head, Part = ::Const.BodyPart.Head }
    ],

    function getMissing( _actor )
    {
        local missing = 0;

        foreach (p in this.Parts)
        {
            if (_actor.getItems().getItemAtSlot(p.Slot) != null)
            {
                missing += ::Math.max(0, _actor.getArmorMax(p.Part) - _actor.getArmor(p.Part));
            }
        }

        return missing;
    }

    // Returns how much armor was restored.
    function repair( _actor )
    {
        local left = this.Repair;
        local total = 0;

        foreach (p in this.Parts)
        {
            local item = _actor.getItems().getItemAtSlot(p.Slot);

            if (left <= 0 || item == null)
            {
                continue;
            }

            local before = _actor.getArmor(p.Part);
            local add = ::Math.min(left, _actor.getArmorMax(p.Part) - before);

            if (add <= 0)
            {
                continue;
            }

            this.setArmor(item, before + add);
            local gained = _actor.getArmor(p.Part) - before;

            if (gained <= 0 && !this.SetterWarningShown)
            {
                this.SetterWarningShown = true;
                ::logWarning("Chaos Mind: Armor Fixer could not change the armor of " + item.getName() + ".");
            }

            left -= add;
            total += ::Math.max(0, gained);
        }

        _actor.getSkills().update();
        _actor.setDirty(true);
        return total;
    }

    // The setter's name couldn't be confirmed in the encrypted scripts, so try the likely ones.
    function setArmor( _item, _value )
    {
        if ("setArmor" in _item)
        {
            _item.setArmor(_value);
        }
        else if ("setCondition" in _item)
        {
            _item.setCondition(_value);
        }
        else
        {
            _item.m.Condition = _value;
        }

        try
        {
            _item.updateAppearance();
        }
        catch (e)
        {
        }
    }

    // Tops a shop up to StockCount Armor Fixers.
    function stock( _building )
    {
        local stash = _building.m.Stash;
        local count = 0;

        foreach (item in stash.getItems())
        {
            if (item != null && item.getID() == this.ItemID)
            {
                count += 1;
            }
        }

        while (count < this.StockCount)
        {
            if (!stash.add(::new("scripts/items/misc/armor_fixer_item")))
            {
                break;
            }

            count += 1;
        }
    }
};


// Every armorer sells it. Both armorers build their stock from getDefaultShopList(), a list of
// { R = rarity, P = price mult, S = script } (confirmed in the Legends mod's copies). R = 0 always
// passes the rarity roll, and fillStash then adds up to 3 copies with the town's prices. If that
// function is missing, fall back to topping the shop up after onUpdateShopList; if both are
// missing, log a warning instead of breaking the game.
foreach (script in [
    "scripts/entity/world/settlements/buildings/armorsmith_building",
    "scripts/entity/world/settlements/buildings/armorsmith_oriental_building"
])
{
    ::ChaosMind.HooksMod.hook(script, function(q)
    {
        if (q.contains("getDefaultShopList", true))
        {
            q.getDefaultShopList = @(__original) function()
            {
                local list = __original();
                list.push({ R = 0, P = 1.0, S = "misc/armor_fixer_item" });
                return list;
            }
        }
        else if (q.contains("onUpdateShopList", true))
        {
            q.onUpdateShopList = @(__original) function()
            {
                __original();
                ::ChaosMind.ArmorFixer.stock(this);
            }
        }
        else
        {
            ::logWarning("Chaos Mind: an armorer has no shop list function; Armor Fixer won't be sold there.");
        }
    });
}
