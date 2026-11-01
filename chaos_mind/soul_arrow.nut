// Soul Arrow: once a Chaos Mind reaches 100 kills (the Devourer), an event gives the company a
// Soul Arrow (scripts/items/misc/soul_arrow_item.nut), once per campaign. It sits in the ammo slot
// and grants actives.soul_arrow: once per battle, +3 AP. Recharging it after a battle costs 15
// ammo from the company's supplies; with less, it stays empty until a later battle ends.
//
// The event is fired from the world map (asset_manager.update), and only while no event or menu
// is on screen: firing it while a contract's result event was showing (31 Oct) swallowed it.
// The gift counts as delivered only once its event screen has actually been shown
// (DeliveredFlag). Until then the company is checked for a Soul Arrow; if it has none, it gets one.
// The world checks below also run ::ChaosMind.CarnalStorage.checkSurvivors (sacrificed brothers who lived).
::ChaosMind.SoulArrow <- {
    EventID = "event.chaos_mind_soul_arrow",
    GivenFlag = "ChaosMind.SoulArrowGiven",
    DeliveredFlag = "ChaosMind.SoulArrowDelivered",
    ItemID = "ammo.soul_arrow",
    Script = "scripts/items/misc/soul_arrow_item",
    LastMigrateHour = -1,
    BonusAP = 3,
    FatigueCost = 20,
    RefillCost = 15,

    LastHourChecked = -1,
    LastFireHour = -1,
    StashFullDay = -1,
    PendingScreen = null,
    LastArrow = null,
    AmmoWarningShown = false,

    function isGiven()
    {
        return ::World.Flags.has(this.GivenFlag) && ::World.Flags.get(this.GivenFlag);
    }

    function isDelivered()
    {
        return ::World.Flags.has(this.DeliveredFlag) && ::World.Flags.get(this.DeliveredFlag);
    }

    // No event, menu or town screen in the way (the checks vanilla's world_state uses itself).
    function canShowEvent()
    {
        try
        {
            local state = ::World.State;

            if (state.m.EventScreen.isVisible() || state.m.EventScreen.isAnimating() || state.m.MenuStack.hasBacksteps())
            {
                return false;
            }
        }
        catch (e)
        {
        }

        return true;
    }

    // A Soul Arrow the company already owns: in the stash, or carried by a brother.
    function findArrow()
    {
        foreach (item in ::World.Assets.getStash().getItems())
        {
            if (item != null && item.getID() == this.ItemID)
            {
                return item;
            }
        }

        foreach (bro in ::World.getPlayerRoster().getAll())
        {
            local ammo = bro.getItems().getItemAtSlot(::Const.ItemSlot.Ammo);

            if (ammo != null && ammo.getID() == this.ItemID)
            {
                return ammo;
            }
        }

        return null;
    }

    function isOld( _item )
    {
        return _item != null && _item.getID() == this.ItemID && ::isKindOf(_item, "ammo");
    }

    function stashHas( _stash, _item )
    {
        foreach (item in _stash.getItems())
        {
            if (item == _item)
            {
                return true;
            }
        }

        return false;
    }

    // Older saves hold the ammo-based Soul Arrow (scripts/items/ammo/soul_arrow), which the stash
    // shows with no picture. Swap each one for the plain item, keeping its charge.
    function migrateOld()
    {
        local stash = ::World.Assets.getStash();
        local old = [];

        foreach (item in stash.getItems())
        {
            if (this.isOld(item))
            {
                old.push(item);
            }
        }

        foreach (item in old)
        {
            local fresh = ::new(this.Script);
            fresh.m.IsCharged = item.m.IsCharged;

            foreach (key in [ item, item.getInstanceID() ])
            {
                if (!this.stashHas(stash, item))
                {
                    break;
                }

                try
                {
                    stash.remove(key);
                }
                catch (e)
                {
                }
            }

            local removed = !this.stashHas(stash, item);
            stash.add(fresh);
            local added = this.stashHas(stash, fresh);
            ::logInfo("Chaos Mind: old Soul Arrow in the stash replaced (old one " + (removed ? "removed" : "could not be removed")
                + ", new one " + (added ? "added" : "NOT added: stash full") + ").");
        }

        foreach (bro in ::World.getPlayerRoster().getAll())
        {
            local items = bro.getItems();
            local item = items.getItemAtSlot(::Const.ItemSlot.Ammo);

            if (!this.isOld(item))
            {
                continue;
            }

            try
            {
                local fresh = ::new(this.Script);
                fresh.m.IsCharged = item.m.IsCharged;
                items.unequip(item);
                items.equip(fresh);
                ::logInfo("Chaos Mind: old Soul Arrow on " + bro.getName() + " replaced.");
            }
            catch (e)
            {
                ::logWarning("Chaos Mind: old Soul Arrow on " + bro.getName() + " could not be replaced (" + e + ").");
            }
        }
    }

    // Called by the event's first screen: the gift has been seen.
    function onShown()
    {
        ::World.Flags.set(this.DeliveredFlag, true);
    }

    // A Chaos Mind that has reached the Devourer, carried by a brother or in the stash.
    function findDevourer()
    {
        return ::ChaosMind.findSword(@(_s) _s.isDevourer());
    }

    function check()
    {
        if (!this.canShowEvent())
        {
            return;
        }

        local time = ::World.getTime();
        local hour = ::ChaosMind.getHour();

        if (hour != this.LastMigrateHour)
        {
            this.LastMigrateHour = hour;
            this.migrateOld();
        }

        if (this.isDelivered())
        {
            return;
        }

        if (this.isGiven())
        {
            // Given before, but its event was never seen: show it now (at most once an hour,
            // in case firing keeps failing), with a new arrow if the company has none.
            if (hour == this.LastFireHour || time.Days <= this.StashFullDay)
            {
                return;
            }

            this.LastFireHour = hour;
            local arrow = this.findArrow();

            if (arrow == null)
            {
                arrow = ::new(this.Script);

                if (!::World.Assets.getStash().add(arrow))
                {
                    this.StashFullDay = time.Days;
                    this.fireEvent("StashFull");
                    return;
                }

                ::logInfo("Chaos Mind: the Soul Arrow's event was never shown and the company has none; a new one was given.");
            }

            this.LastArrow = arrow;
            this.fireEvent("A");
            return;
        }

        if (hour == this.LastHourChecked)
        {
            return;
        }

        this.LastHourChecked = hour;

        // A full stash is retried the next day, not every hour.
        if (time.Days <= this.StashFullDay || this.findDevourer() == null)
        {
            return;
        }

        local arrow = ::new(this.Script);

        if (!::World.Assets.getStash().add(arrow))
        {
            this.StashFullDay = time.Days;
            this.fireEvent("StashFull");
            return;
        }

        ::World.Flags.set(this.GivenFlag, true);
        this.LastArrow = arrow;
        ::logInfo("Chaos Mind: the Devourer gave the company a Soul Arrow.");
        this.fireEvent("A");
    }

    function fireEvent( _screen )
    {
        this.PendingScreen = _screen;
        ::World.Events.fire(this.EventID);
    }

    // After a battle: an empty Soul Arrow takes RefillCost ammo from the supplies to recharge.
    function refill( _arrow )
    {
        if (_arrow == null || _arrow.m.IsCharged)
        {
            return;
        }

        try
        {
            local ammo = ::World.Assets.getAmmo();

            if (ammo < this.RefillCost)
            {
                ::logInfo("Chaos Mind: Soul Arrow stays empty, it needs " + this.RefillCost + " ammo and the company has " + ammo + ".");
                return;
            }

            ::World.Assets.addAmmo(-this.RefillCost);
            _arrow.m.IsCharged = true;
            _arrow.updateIcons();
            ::logInfo("Chaos Mind: Soul Arrow recharged for " + this.RefillCost + " ammo (" + (ammo - this.RefillCost) + " left).");
        }
        catch (e)
        {
            if (!this.AmmoWarningShown)
            {
                this.AmmoWarningShown = true;
                ::logWarning("Chaos Mind: Soul Arrow could not take ammo from the supplies (" + e + ").");
            }
        }
    }
};


// Once an hour on the world map (chaos_mind/common.nut runs these).
::ChaosMind.addWorldCheck("Soul Arrow check", function()
{
    ::ChaosMind.SoulArrow.check();
});
::ChaosMind.addWorldCheck("sacrifice survivor check", function()
{
    ::ChaosMind.CarnalStorage.checkSurvivors();
});
