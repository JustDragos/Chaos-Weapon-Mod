// Saves that still load after the mod is removed (13 Nov). OFF by default since the evening of
// 13 Nov (Mod Settings -> Chaos Mind -> Saves; Dev / Game breaking since 14 Nov): its first version also took The Frozen Eye off the
// map during the save, which corrupted a save ("Corrupt data before FoW"). That part is gone; the
// rest stays opt-in until it is proven in play. Loading always brings back what an earlier save
// kept in flags.
// The game saves every item, perk and map location as the hash of its script file and rebuilds it
// from that script on load. With the mod removed the script is gone and the load crashes. So for
// the length of each save (world_state.saveCampaign, which MSU confirms runs the whole save at
// once) everything of this mod is taken out and written into plain flags, which the game saves
// without needing the mod, and is put straight back afterwards:
//  - items in brothers' slots and bags, in the stash and in shops: a record string in the owner's
//    flags (brother, world, settlement). They're blanked in place and put back at the same spot;
//  - this mod's perks: a list in the brother's flags. They're taken out of his skill list and put
//    back at the same index;
//  - this mod's events: left out of the event manager's list (the game keeps their saved state by
//    ID, since event mods can be added to running campaigns), nothing recorded;
//  - The Frozen Eye: not touched while saving (see above). Before the sword is claimed a save
//    needs the mod; once claimed, the altar is removed for good (::ChaosMind.Altar.removeClaimed);
//  - this mod's contracts: unaccepted ones are left out (a town offers them again), the accepted
//    one is recorded in a world flag and rebuilt on load (::ChaosMind.Contracts.restore).
// Loading with the mod (loadCampaign) rebuilds everything from the flags and clears them. Without
// the mod the save loads with them missing, and the flags stay in the save until the mod is back.
// Saves made before this still need the mod once: load them with it and save again.
::ChaosMind.SaveSafety <- {
    ItemsFlag = "ChaosMind.Saved.Items",
    PerksFlag = "ChaosMind.Saved.Perks",
    StashFlag = "ChaosMind.Saved.Stash",
    ShopFlagPrefix = "ChaosMind.Saved.Shop.",
    AltarFlag = "ChaosMind.Saved.Altar",
    // Items that had nowhere to go on load (stash full); retried every hour.
    PendingFlag = "ChaosMind.Saved.Pending",
    LastPendingHour = -1,

    Perks = [
        "perk.chaos_protection",
        "perk.vampire_allegiance",
        "perk.only_chaos_matters",
        "perk.troll_allegiance",
        "perk.used_to_it",
        "perk.chaos_armor",
        "perk.fatigue_transfer",
        "perk.chaos_circle"
    ],

    // All fired only by this mod's code, so they keep nothing in the save worth losing.
    Events = [
        "event.location.chaos_mind_altar",
        "event.chaos_mind_duel",
        "event.chaos_mind_quest",
        "event.chaos_mind_soul_arrow",
        "event.chaos_mind_aura"
    ],

    // What was taken out for the save in progress, to put back afterwards.
    Taken = null,
    ItemTypes = null,
    FirstSaveLogged = false,

    // Each item of this mod by ID: the script to rebuild it from, and how to save its own state as
    // a short string (never empty) and read it back.
    function getItemTypes()
    {
        if (this.ItemTypes != null)
        {
            return this.ItemTypes;
        }

        this.ItemTypes = {
            [::ChaosMind.SwordID] = {
                Script = "scripts/items/weapons/legendary/chaos_mind",
                save = function( _item )
                {
                    return "" + _item.m.Kills + "/" + ::Math.round(_item.getCondition());
                },
                load = function( _item, _data )
                {
                    local parts = split(_data, "/");
                    _item.m.Kills = parts[0].tointeger();

                    if (parts.len() > 1)
                    {
                        _item.setCondition(::Math.min(_item.getConditionMax(), parts[1].tofloat()));
                    }

                    _item.updateName();
                }
            },
            ["ammo.soul_arrow"] = {
                Script = ::ChaosMind.SoulArrow.Script,
                save = function( _item )
                {
                    return _item.m.IsCharged ? "1" : "0";
                },
                load = function( _item, _data )
                {
                    _item.m.IsCharged = _data == "1";
                    _item.updateIcons();
                }
            },
            [::ChaosMind.ArmorFixer.ItemID] = {
                Script = "scripts/items/misc/armor_fixer_item",
                save = @( _item ) "-",
                load = function( _item, _data ) {}
            },
            ["misc.chaos_guide"] = {
                Script = "scripts/items/misc/chaos_guide_item",
                save = @( _item ) "-",
                load = function( _item, _data ) {}
            },
            [::ChaosMind.Aura.ItemID] = {
                Script = ::ChaosMind.Aura.Script,
                save = @( _item ) "-",
                load = function( _item, _data ) {}
            }
        };
        return this.ItemTypes;
    }

    function isModItem( _item )
    {
        return typeof _item == "instance" && _item.getID() in this.getItemTypes();
    }

    // "id:slot:data" records joined by "|".
    function encodeItem( _item, _slot )
    {
        return _item.getID() + ":" + _slot + ":" + this.getItemTypes()[_item.getID()].save(_item);
    }

    function joinRecords( _records )
    {
        local text = "";

        foreach (i, r in _records)
        {
            text += (i == 0 ? "" : "|") + r;
        }

        return text;
    }

    // Rebuilds an item from its record: { Item, Slot }, or null if the record can't be read.
    function decodeItem( _record )
    {
        local parts = split(_record, ":");
        local types = this.getItemTypes();

        if (parts.len() < 3 || !(parts[0] in types))
        {
            ::logWarning("Chaos Mind: a saved item couldn't be read (\"" + _record + "\"); it's dropped.");
            return null;
        }

        local type = types[parts[0]];
        local item = ::new(type.Script);

        try
        {
            type.load(item, parts[2]);
        }
        catch (e)
        {
            ::logWarning("Chaos Mind: a saved " + parts[0] + " lost some of its state (" + e + ").");
        }

        return { Item = item, Slot = parts[1].tointeger() };
    }

    function readRecords( _flags, _key )
    {
        if (!_flags.has(_key))
        {
            return [];
        }

        local text = _flags.get(_key);
        _flags.remove(_key);
        return typeof text == "string" && text != "" ? split(text, "|") : [];
    }

    function writeRecords( _flags, _key, _records )
    {
        if (_records.len() != 0)
        {
            _flags.set(_key, this.joinRecords(_records));
        }
    }

    // ---- Saving ----

    // Takes every item, perk and location of this mod out of the world and writes them into flags.
    function takeOut()
    {
        this.Taken = { Slots = [], Removed = [], Flags = [], Contract = null };
        local count = 0;

        foreach (bro in ::World.getPlayerRoster().getAll())
        {
            local records = [];
            local slots = bro.getItems().m.Items;

            foreach (slot, list in slots)
            {
                foreach (i, item in list)
                {
                    if (this.isModItem(item))
                    {
                        records.push(this.encodeItem(item, slot));
                        this.Taken.Slots.push({ List = list, Index = i, Item = item });
                        list[i] = null;
                    }
                }
            }

            this.writeRecords(bro.getFlags(), this.ItemsFlag, records);
            this.Taken.Flags.push({ Flags = bro.getFlags(), Key = this.ItemsFlag });
            count += records.len();

            local perks = this.removeByID(bro.getSkills().m.Skills, this.Perks);
            this.writeRecords(bro.getFlags(), this.PerksFlag, perks);
            this.Taken.Flags.push({ Flags = bro.getFlags(), Key = this.PerksFlag });
            count += perks.len();
        }

        count += this.takeOutOfStash(::World.Assets.getStash(), ::World.Flags, this.StashFlag);

        foreach (shop in this.getShops())
        {
            count += this.takeOutOfStash(shop.Stash, shop.Flags, shop.Key);
        }

        this.removeByID(::World.Events.m.Events, this.Events);
        count += this.takeOutContracts();

        // The Frozen Eye is no longer taken off the map for the save (13 Nov): removing a location
        // (die()) while the game writes the save corrupted one ("Corrupt data before FoW"). A
        // claimed altar is removed for good instead, at a quiet moment (::ChaosMind.Altar).
        return count;
    }

    // This mod's contracts (chaos_mind/contracts.nut): unaccepted ones are left out of the save
    // (a town offers them again), the accepted one is recorded and rebuilt on load.
    function takeOutContracts()
    {
        local contracts = ::ChaosMind.Contracts;
        local open = ::World.Contracts.m.Open;
        local count = 0;

        for (local i = open.len() - 1; i >= 0; i--)
        {
            if (contracts.isModContract(open[i]))
            {
                this.Taken.Removed.push({ List = open, Index = i, Value = open[i] });
                open.remove(i);
                count += 1;
            }
        }

        local active = ::World.Contracts.m.Active;

        if (contracts.isModContract(active))
        {
            ::World.Flags.set(contracts.ActiveFlag, contracts.record(active));
            this.Taken.Flags.push({ Flags = ::World.Flags, Key = contracts.ActiveFlag });
            this.Taken.Contract = active;
            ::World.Contracts.m.Active = null;
            count += 1;
        }

        return count;
    }

    // Takes the entries whose ID is in _ids out of _list, noting where each was so putBack() can
    // insert them at the same index. Returns the removed IDs, in list order.
    function removeByID( _list, _ids )
    {
        local removed = [];

        for (local i = _list.len() - 1; i >= 0; i--)
        {
            if (_ids.find(_list[i].getID()) != null)
            {
                removed.insert(0, _list[i].getID());
                this.Taken.Removed.push({ List = _list, Index = i, Value = _list[i] });
                _list.remove(i);
            }
        }

        return removed;
    }

    // Every building with a shop stash, with the settlement flags its items are kept in.
    function getShops()
    {
        local shops = [];

        foreach (settlement in ::World.EntityManager.getSettlements())
        {
            if (!("Buildings" in settlement.m))
            {
                continue;
            }

            foreach (building in settlement.m.Buildings)
            {
                if (building != null && ("Stash" in building.m) && building.m.Stash != null)
                {
                    shops.push({ Stash = building.m.Stash, Flags = settlement.getFlags(), Key = this.ShopFlagPrefix + building.getID() });
                }
            }
        }

        return shops;
    }

    function takeOutOfStash( _stash, _flags, _key )
    {
        local records = [];
        local list = _stash.m.Items;

        foreach (i, item in list)
        {
            if (this.isModItem(item))
            {
                records.push(this.encodeItem(item, ::Const.ItemSlot.None));
                this.Taken.Slots.push({ List = list, Index = i, Item = item });
                list[i] = null;
            }
        }

        this.writeRecords(_flags, _key, records);
        this.Taken.Flags.push({ Flags = _flags, Key = _key });
        return records.len();
    }

    // Puts everything back exactly where it was, once the save is written.
    function putBack()
    {
        if (this.Taken == null)
        {
            return;
        }

        local taken = this.Taken;
        this.Taken = null;

        foreach (t in taken.Slots)
        {
            t.List[t.Index] = t.Item;
        }

        // Removed from the back of each list first, so put back in reverse order.
        for (local i = taken.Removed.len() - 1; i >= 0; i--)
        {
            local t = taken.Removed[i];
            t.List.insert(t.Index, t.Value);
        }

        if (taken.Contract != null)
        {
            ::World.Contracts.m.Active = taken.Contract;
        }

        foreach (t in taken.Flags)
        {
            if (t.Flags.has(t.Key))
            {
                t.Flags.remove(t.Key);
            }
        }
    }

    // ---- Loading ----

    // Rebuilds whatever a save made with this feature holds in flags. Called right after loading.
    function bringBack()
    {
        local restored = 0;
        local stash = ::World.Assets.getStash();
        local pending = this.readRecords(::World.Flags, this.PendingFlag);

        foreach (bro in ::World.getPlayerRoster().getAll())
        {
            foreach (record in this.readRecords(bro.getFlags(), this.ItemsFlag))
            {
                local r = this.decodeItem(record);

                if (r == null)
                {
                    continue;
                }

                local items = bro.getItems();
                local placed = false;

                // Back into his hands or bag if that place is still free; otherwise the stash.
                if (r.Slot == ::Const.ItemSlot.Bag)
                {
                    placed = items.addToBag(r.Item);
                }
                else if (items.getItemAtSlot(r.Slot) == null)
                {
                    placed = items.equip(r.Item);
                }

                if (!placed && stash.add(r.Item) == null)
                {
                    pending.push(record);
                    continue;
                }

                restored += 1;
            }

            foreach (id in this.readRecords(bro.getFlags(), this.PerksFlag))
            {
                if (bro.getSkills().hasSkill(id) || !(id in ::Const.Perks.LookupMap))
                {
                    continue;
                }

                bro.getSkills().add(::new(::Const.Perks.LookupMap[id].Script));
                restored += 1;
            }
        }

        foreach (record in this.readRecords(::World.Flags, this.StashFlag))
        {
            local r = this.decodeItem(record);

            if (r != null)
            {
                if (stash.add(r.Item) == null)
                {
                    pending.push(record);
                }
                else
                {
                    restored += 1;
                }
            }
        }

        // A shop with no room just loses the item, like any shop stock.
        foreach (shop in this.getShops())
        {
            foreach (record in this.readRecords(shop.Flags, shop.Key))
            {
                local r = this.decodeItem(record);

                if (r != null && shop.Stash.add(r.Item) != null)
                {
                    restored += 1;
                }
            }
        }

        // Saves from the first version (13 Nov) may still hold The Frozen Eye's tile. A claimed
        // altar isn't put back: it is removed for good now (::ChaosMind.Altar.removeClaimed).
        if (::World.Flags.has(this.AltarFlag))
        {
            local record = ::World.Flags.get(this.AltarFlag);
            ::World.Flags.remove(this.AltarFlag);

            if (::ChaosMind.Altar.find() == null && !::ChaosMind.Altar.isClaimed())
            {
                this.placeAltar(record);
                restored += 1;
            }
        }

        this.writeRecords(::World.Flags, this.PendingFlag, pending);

        if (::World.Flags.has(::ChaosMind.Contracts.ActiveFlag))
        {
            ::ChaosMind.Contracts.restore();
            restored += 1;
        }

        if (restored > 0 || pending.len() > 0)
        {
            ::logInfo("Chaos Mind: brought back " + restored + " thing(s) kept in the save's flags"
                + (pending.len() > 0 ? "; " + pending.len() + " item(s) wait for room in the stash." : "."));
        }
    }

    // Places The Frozen Eye back on its old tile ("squareX/squareY/discovered"), the same way
    // Altar.spawn() does. If something has taken that tile meanwhile, Altar.spawn() finds a new one.
    function placeAltar( _record )
    {
        local parts = split(_record, "/");
        local tile = ::World.getTileSquare(parts[0].tointeger(), parts[1].tointeger());

        if (tile.IsOccupied)
        {
            ::logWarning("Chaos Mind: The Frozen Eye's tile is taken; it will appear somewhere else.");
            return;
        }

        local altar = ::World.spawnEntity("scripts/entity/world/locations/chaos_mind_altar_location", tile.Coords.X, tile.Coords.Y);

        if (altar != null && parts.len() > 2 && parts[2] == "1" && ("setDiscovered" in altar))
        {
            altar.setDiscovered(true);
        }
    }

    // Items that found no room on load try the stash again once an hour.
    function retryPending()
    {
        if (!::World.Flags.has(this.PendingFlag) || ::ChaosMind.getHour() == this.LastPendingHour)
        {
            return;
        }

        this.LastPendingHour = ::ChaosMind.getHour();
        local stash = ::World.Assets.getStash();
        local left = [];

        foreach (record in this.readRecords(::World.Flags, this.PendingFlag))
        {
            local r = this.decodeItem(record);

            if (r != null && stash.add(r.Item) == null)
            {
                left.push(record);
            }
        }

        this.writeRecords(::World.Flags, this.PendingFlag, left);
    }
};

::ChaosMind.addWorldCheck("saved items check", function()
{
    ::ChaosMind.SaveSafety.putBack();
    ::ChaosMind.SaveSafety.retryPending();
});
