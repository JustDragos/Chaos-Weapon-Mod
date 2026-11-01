// The Frozen Eye: legendary arctic location. Chaos Mind is claimed by sacrificing
// RequiredSacrifices brothers, chosen in a roster window (ui/mods/chaos_mind/altar.js).
::ChaosMind.Altar <- {
    TypeID = "location.chaos_mind_altar",
    ClaimedFlag = "ChaosMind.AltarClaimed",
    RequiredSacrifices = 8,
    MinSettlementDistance = 6,

    Screen = null,
    LastSacrificed = [],
    LastSword = null,
    LastGuide = null,

    // Screen the altar event opens on next ("Claimed", "StashFull"), set before firing it.
    PendingScreen = null,

    function fireEvent( _screen )
    {
        this.PendingScreen = _screen;
        ::World.Events.fire("event.location.chaos_mind_altar");
    }

    function isClaimed()
    {
        return ::World.Flags.has(this.ClaimedFlag) && ::World.Flags.get(this.ClaimedFlag);
    }

    function find()
    {
        foreach (location in ::World.EntityManager.getLocations())
        {
            if (location.getTypeID() == this.TypeID)
            {
                return location;
            }
        }

        return null;
    }

    // Arctic terrain first; snowy forest if a map has no open snow left.
    function getTerrainTypes()
    {
        local types = [];

        foreach (name in ["Snow", "SnowyForest"])
        {
            if (name in ::Const.World.TerrainType)
            {
                types.push(::Const.World.TerrainType[name]);
            }
        }

        return types;
    }

    function isGoodTile( _tile, _types, _settlements )
    {
        if (_tile.IsOccupied || _types.find(_tile.Type) == null)
        {
            return false;
        }

        local nearest = null;
        local nearestDistance = 9999;

        foreach (settlement in _settlements)
        {
            local d = _tile.getDistanceTo(settlement.getTile());

            if (d < this.MinSettlementDistance)
            {
                return false;
            }

            if (d < nearestDistance)
            {
                nearestDistance = d;
                nearest = settlement;
            }
        }

        // Must be reachable over land from the nearest settlement.
        if (nearest != null)
        {
            local nav = ::World.getNavigator().createSettings();
            nav.ActionPointCosts = ::Const.World.TerrainTypeNavCost_Flat;

            if (::World.getNavigator().findPath(_tile, nearest.getTile(), nav, 0).isEmpty())
            {
                return false;
            }
        }

        return true;
    }

    function findSpawnTile()
    {
        local types = this.getTerrainTypes();

        if (types.len() == 0)
        {
            ::logError("Chaos Mind: no snow terrain types found.");
            return null;
        }

        local settlements = ::World.EntityManager.getSettlements();
        local sizeX = ::Const.World.Settings.SizeX;
        local sizeY = ::Const.World.Settings.SizeY;

        for (local attempt = 0; attempt < 4000; ++attempt)
        {
            local x = ::Math.rand(2, sizeX - 3);
            local y = ::Math.rand(2, sizeY - 3);

            if (!::World.isValidTileSquare(x, y))
            {
                continue;
            }

            local tile = ::World.getTileSquare(x, y);

            if (this.isGoodTile(tile, types, settlements))
            {
                return tile;
            }
        }

        return null;
    }

    // Eight-way compass direction from one tile to another (north is up on the map).
    function getCompassDirection( _from, _to )
    {
        local dx = (_to.SquareCoords.X - _from.SquareCoords.X).tofloat();
        local dy = (_to.SquareCoords.Y - _from.SquareCoords.Y).tofloat();

        if (dx == 0 && dy == 0)
        {
            return "right here";
        }

        // tan(22.5 deg) ~ 0.414 splits the 8 compass sectors.
        local ns = dy > 0 ? "north" : "south";
        local ew = dx > 0 ? "east" : "west";
        local adx = dx < 0 ? -dx : dx;
        local ady = dy < 0 ? -dy : dy;

        if (adx < 0.414 * ady)
        {
            return ns;
        }

        if (ady < 0.414 * adx)
        {
            return ew;
        }

        return ns + "-" + ew;
    }

    // "at X, Y: 9 tiles north-east of Erlstadt; 23 tiles north of your company".
    function describeLocation( _tile )
    {
        local text = "at " + _tile.SquareCoords.X + ", " + _tile.SquareCoords.Y;

        local nearest = null;
        local nearestDistance = 9999;

        foreach (settlement in ::World.EntityManager.getSettlements())
        {
            local d = _tile.getDistanceTo(settlement.getTile());

            if (d < nearestDistance)
            {
                nearestDistance = d;
                nearest = settlement;
            }
        }

        if (nearest != null)
        {
            text += ": " + nearestDistance + " tiles " + this.getCompassDirection(nearest.getTile(), _tile) + " of " + nearest.getName();
        }

        local player = ::World.State.getPlayer();

        if (player != null)
        {
            local here = player.getTile();
            text += "; " + here.getDistanceTo(_tile) + " tiles " + this.getCompassDirection(here, _tile) + " of your company";
        }

        return text;
    }

    // One line for hotkeys and the log: where The Frozen Eye is from the company right now.
    function getDirectionText()
    {
        local altar = this.find();

        if (altar == null)
        {
            return "The Frozen Eye: not in this world yet.";
        }

        return "The Frozen Eye is " + this.describeLocation(altar.getTile()) + (this.isClaimed() ? " (claimed)" : "") + ".";
    }

    // Ctrl+F on the world map (rebindable): log and show where The Frozen Eye is.
    // Pressing it again closes the notice. Once the sword is claimed the hotkey does nothing
    // (returns false so the key is passed on).
    function showDirection()
    {
        // Once claimed, the key shows the Black Skull's marked party instead, if one is being hunted.
        if (this.isClaimed())
        {
            return ::ChaosMind.Quest.showDirection();
        }

        local text = this.getDirectionText();
        ::logInfo("Chaos Mind: " + text);
        return ::ChaosMind.Notice.toggle("The Frozen Eye", [ text ]);
    }

    // Called on new campaigns and on every load; only spawns if the altar is missing.
    function spawn()
    {
        local existing = this.find();

        if (existing != null)
        {
            ::logInfo("Chaos Mind: The Frozen Eye is " + this.describeLocation(existing.getTile()) + (this.isClaimed() ? " (claimed)" : ""));
            return;
        }

        local tile = this.findSpawnTile();

        if (tile == null)
        {
            ::logError("Chaos Mind: could not find an arctic tile for The Frozen Eye.");
            return;
        }

        ::World.spawnEntity("scripts/entity/world/locations/chaos_mind_altar_location", tile.Coords.X, tile.Coords.Y);
        ::logInfo("Chaos Mind: The Frozen Eye spawned " + this.describeLocation(tile));
    }

    // The company's own character (Lone Wolf and similar origins) can never be offered.
    function isEligible( _bro )
    {
        return _bro.isAlive() && !(_bro.getFlags().has("IsPlayerCharacter") && _bro.getFlags().get("IsPlayerCharacter"));
    }

    function getEligible()
    {
        local result = [];

        foreach (bro in ::World.getPlayerRoster().getAll())
        {
            if (this.isEligible(bro))
            {
                result.push(bro);
            }
        }

        return result;
    }

    // At least RequiredSacrifices eligible brothers, and someone must remain afterwards.
    function canOffer()
    {
        return this.getEligible().len() >= this.RequiredSacrifices
            && ::World.getPlayerRoster().getAll().len() > this.RequiredSacrifices;
    }

    function getUIData()
    {
        local brothers = [];

        foreach (bro in this.getEligible())
        {
            brothers.push({
                ID = bro.getID(),
                Name = bro.getName(),
                Level = bro.getLevel(),
                Background = bro.getBackground().getName()
            });
        }

        return {
            Required = this.RequiredSacrifices,
            Brothers = brothers
        };
    }

    function openPicker()
    {
        if (this.Screen == null)
        {
            ::logError("Chaos Mind: altar window was never created.");
            return;
        }

        this.Screen.show(this.getUIData());
    }

    function closePicker()
    {
        if (this.Screen != null)
        {
            this.Screen.hide();
        }
    }

    // Adds a sacrificed brother to the company's fallen list (obituary). The game's function
    // signature couldn't be read (encrypted scripts) and (bro, text) is rejected with "wrong
    // number of parameters", so the other likely forms are tried in turn.
    function recordFallen( _bro )
    {
        local text = "Sacrificed to Chaos Mind";
        local attempts = [
            [ ::World.Statistics, _bro ],
            [ ::World.Statistics, _bro, text, 0 ],
            [ ::World.Statistics, _bro, text, 0, 0 ],
            [ ::World.Statistics, _bro, text ]
        ];

        foreach (args in attempts)
        {
            try
            {
                ::World.Statistics.addFallen.acall(args);
                ::logInfo("Chaos Mind: recorded " + _bro.getName() + " as fallen (" + (args.len() - 1) + " argument(s)).");
                return;
            }
            catch (e)
            {
            }
        }

        ::logWarning("Chaos Mind: could not record " + _bro.getName() + " as fallen.");
    }

    function offer( _ids )
    {
        this.closePicker();

        if (this.isClaimed() || _ids == null || _ids.len() != this.RequiredSacrifices || !this.canOffer())
        {
            ::logError("Chaos Mind: offering refused.");
            return;
        }

        // IDs arrive from the interface as numbers that may be floats.
        local wanted = {};

        foreach (id in _ids)
        {
            wanted[id.tointeger()] <- true;
        }

        local chosen = [];

        foreach (bro in this.getEligible())
        {
            if (bro.getID() in wanted)
            {
                chosen.push(bro);
            }
        }

        if (chosen.len() != this.RequiredSacrifices)
        {
            ::logError("Chaos Mind: offering refused, some chosen brothers are no longer in the company.");
            return;
        }

        // The sword first, so a full stash cancels the offering before anyone dies.
        local stash = ::World.Assets.getStash();
        local sword = ::new("scripts/items/weapons/legendary/chaos_mind");

        if (!stash.add(sword))
        {
            this.fireEvent("StashFull");
            return;
        }

        // The offered souls count as the blade's first kills.
        sword.m.Kills = this.RequiredSacrifices;
        sword.updateName();
        this.LastSword = sword;

        // The book that explains it all. With no room, the blade's first kill brings it.
        this.LastGuide = ::ChaosMind.Guide.give("claimed at The Frozen Eye");

        this.LastSacrificed = [];

        foreach (bro in chosen)
        {
            this.LastSacrificed.push(bro.getName());
            bro.getItems().transferToStash(stash);

            this.recordFallen(bro);

            ::World.getPlayerRoster().remove(bro);
        }

        ::World.Flags.set(this.ClaimedFlag, true);
        ::logInfo("Chaos Mind: claimed at The Frozen Eye; sacrificed " + this.LastSacrificed.len() + " brothers.");
        this.fireEvent("Offered");
    }
};


// Ctrl+F on the world map: where is The Frozen Eye? Rebindable in Mod Settings.
::ChaosMind.Mod.Keybinds.addSQKeybind(
    "showFrozenEyeDirection",
    "ctrl+f",
    ::MSU.Key.State.World,
    function()
    {
        return ::ChaosMind.Altar.showDirection();
    },
    "Show where The Frozen Eye is"
);


// The roster window: Squirrel connection + JS/CSS for the interface.
::ChaosMind.Altar.Screen = ::new("scripts/mods/chaos_mind/altar_screen");
::MSU.UI.registerConnection(::ChaosMind.Altar.Screen);
::Hooks.registerJS("ui/mods/chaos_mind/altar.js");
::Hooks.registerCSS("ui/mods/chaos_mind/altar.css");
