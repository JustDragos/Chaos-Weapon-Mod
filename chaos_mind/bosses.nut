// Ctrl+B on the world map (14 Nov, "use ctrl + B to get the positions of all the game bosses,
// vanilla + the mod ones"): one notice listing every boss, nearest first.
//  - The game's legendary locations: every world location whose m.LocationType is
//    Const.World.LocationType.Unique (the type the altar and Legends' legendary locations set),
//    found through World.EntityManager.getLocations() (as altar.find() does). Undiscovered ones are
//    listed too, marked "not found yet". The Frozen Eye is one of them until it's claimed.
//  - This mod's hunt targets while they run: the Black Skull party, The Ten, each Army of the Past
//    group, the Red Dragon.
//  - Each line: name, tiles and direction from the company, nearest town. Also written to the log.
//  - Rebindable in Mod Settings.
::ChaosMind.Bosses <- {
    function getNearestTown( _tile )
    {
        local nearest = null;
        local best = 9999;

        foreach (town in ::World.EntityManager.getSettlements())
        {
            local d = _tile.getDistanceTo(town.getTile());

            if (d < best)
            {
                best = d;
                nearest = town;
            }
        }

        return nearest;
    }

    // "Black Monolith: 34 tiles north-east (near Erlstadt), not found yet"
    function describe( _name, _tile, _note, _here )
    {
        local altar = ::ChaosMind.Altar;
        local text = _name + ": " + _here.getDistanceTo(_tile) + " tiles " + altar.getCompassDirection(_here, _tile);
        local town = this.getNearestTown(_tile);

        if (town != null)
        {
            text += " (" + _tile.getDistanceTo(town.getTile()) + " " + altar.getCompassDirection(town.getTile(), _tile) + " of " + town.getName() + ")";
        }

        if (_note != "")
        {
            text += ", " + _note;
        }

        return text;
    }

    // [ { Name, Tile, Note } ] for every boss in the world now.
    function collect()
    {
        local found = [];
        local unique = ("LocationType" in ::Const.World && "Unique" in ::Const.World.LocationType) ? ::Const.World.LocationType.Unique : null;

        if (unique == null)
        {
            ::logWarning("Chaos Mind: Const.World.LocationType.Unique not found; Ctrl+B lists only this mod's bosses.");
        }
        else
        {
            foreach (location in ::World.EntityManager.getLocations())
            {
                try
                {
                    if (!("LocationType" in location.m) || location.m.LocationType != unique || (("isAlive" in location) && !location.isAlive()))
                    {
                        continue;
                    }

                    local note = "";

                    if (location.getTypeID() == ::ChaosMind.Altar.TypeID)
                    {
                        note = "this mod";
                    }
                    else if (("isDiscovered" in location) && !location.isDiscovered())
                    {
                        note = "not found yet";
                    }

                    found.push({ Name = location.getName(), Tile = location.getTile(), Note = note });
                }
                catch (e)
                {
                }
            }
        }

        local parties = [];
        local skull = ::ChaosMind.Quest.getActive() != 0 ? ::ChaosMind.Quest.getTarget() : null;
        parties.push([ skull, "The Black Skull: " ]);
        parties.push([ ::ChaosMind.Aura.getTarget(), "" ]);
        parties.push([ ::ChaosMind.Dragon.getState() == 1 ? ::ChaosMind.Dragon.getTarget() : null, "" ]);

        foreach (group in ::ChaosMind.Army.getTargets())
        {
            parties.push([ group, "" ]);
        }

        foreach (p in parties)
        {
            try
            {
                if (p[0] != null && p[0].isAlive())
                {
                    found.push({ Name = p[1] + p[0].getName(), Tile = p[0].getTile(), Note = "this mod's hunt" });
                }
            }
            catch (e)
            {
            }
        }

        return found;
    }

    function getLines()
    {
        local player = ::World.State.getPlayer();

        if (player == null)
        {
            return [ "Your company isn't on the map." ];
        }

        local here = player.getTile();
        local found = this.collect();
        found.sort(@(a, b) here.getDistanceTo(a.Tile) <=> here.getDistanceTo(b.Tile));
        local lines = [];

        foreach (boss in found)
        {
            lines.push(this.describe(boss.Name, boss.Tile, boss.Note, here));
        }

        if (lines.len() == 0)
        {
            lines.push("No bosses found in this world.");
        }

        return lines;
    }

    function show()
    {
        local lines = this.getLines();

        foreach (line in lines)
        {
            ::logInfo("Chaos Mind: boss: " + line);
        }

        return ::ChaosMind.Notice.toggle("Bosses (" + lines.len() + ")", lines);
    }
};

::ChaosMind.Mod.Keybinds.addSQKeybind(
    "showBosses",
    "ctrl+b",
    ::MSU.Key.State.World,
    function()
    {
        return ::ChaosMind.Bosses.show();
    },
    "Show where every boss is (experimental)",
    ::MSU.Key.KeyState.Press
);
