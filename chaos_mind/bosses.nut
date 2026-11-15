// Ctrl+B on the world map (14 Nov, "use ctrl + B to get the positions of all the game bosses,
// vanilla + the mod ones"): one notice listing every boss, nearest first.
//  - The game's legendary locations, from World.EntityManager.getLocations() (as altar.find()
//    does), matched by TypeID (LegendaryTypeIDs; since 15 Nov, see isLegendary). Undiscovered ones
//    are listed too, marked "not found yet". The Frozen Eye is one of them until it's claimed.
//  - The window shows the nearest MaxLines; every boss goes to the log.
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

    KindsLogged = false,
    MaxLines = 12,
    LastCount = 0,

    // The game's legendary locations by TypeID (15 Nov). Reading a location's type flags from the
    // mod didn't work: in log.html every one of 188 locations, even this mod's altar, showed no
    // m.LocationType ("?"), so the flag tests found nothing. These TypeIDs are the one-per-world
    // sites in that same log; the flag test stays as a fallback for anything else.
    LegendaryTypeIDs = [
        "location.black_monolith", "location.goblin_city", "location.sunken_library",
        "location.kraken_cult", "location.icy_cave_location", "location.tundra_elk_location",
        "location.unhold_graveyard", "location.witch_hut", "location.land_ship",
        "location.waterwheel", "location.fountain_of_youth", "location.ancient_statue",
        "location.ancient_temple", "location.ancient_watchtower"
    ],
    // Prefixes: the three southern holy sites, and Legends' legendary locations if it's installed.
    LegendaryPrefixes = [ "location.holy_site.", "location.legend_" ],

    function readLocationType( _location )
    {
        try
        {
            return _location.m.LocationType;
        }
        catch (e)
        {
            return null;
        }
    }

    function isLegendary( _location, _unique )
    {
        local id = _location.getTypeID();

        if (this.LegendaryTypeIDs.find(id) != null)
        {
            return true;
        }

        foreach (prefix in this.LegendaryPrefixes)
        {
            if (id.find(prefix) == 0)
            {
                return true;
            }
        }

        if (_unique == null)
        {
            return false;
        }

        try
        {
            if (_location.isLocationType(_unique))
            {
                return true;
            }
        }
        catch (e)
        {
        }

        local t = this.readLocationType(_location);
        return typeof t == "integer" && (t & _unique) != 0;
    }

    // Once per session: how many locations of each kind the world has (TypeID, its LocationType
    // value), so a missing legendary site shows why in log.html.
    function logLocationKinds( _all, _unique )
    {
        if (this.KindsLogged)
        {
            return;
        }

        this.KindsLogged = true;
        local kinds = {};

        foreach (location in _all)
        {
            try
            {
                local t = this.readLocationType(location);
                local key = location.getTypeID() + " (" + (t == null ? "?" : t) + (this.isLegendary(location, _unique) ? ", listed" : "") + ")";
                kinds[key] <- (key in kinds) ? kinds[key] + 1 : 1;
            }
            catch (e)
            {
            }
        }

        local parts = [];

        foreach (key, n in kinds)
        {
            parts.push(key + " x" + n);
        }

        parts.sort();
        ::logInfo("Chaos Mind: Ctrl+B sees " + _all.len() + " locations; kinds: " + (parts.len() == 0 ? "none" : parts.reduce(@(a, b) a + ", " + b)));
    }

    // [ { Name, Tile, Note } ] for every boss in the world now.
    function collect()
    {
        local found = [];
        local unique = null;

        try
        {
            unique = ::Const.World.LocationType.Unique;
        }
        catch (e)
        {
        }

        local all = ::World.EntityManager.getLocations();
        this.logLocationKinds(all, unique);

        foreach (location in all)
        {
            try
            {
                if (!this.isLegendary(location, unique))
                {
                    continue;
                }

                try
                {
                    if (!location.isAlive())
                    {
                        continue;
                    }
                }
                catch (e)
                {
                }

                local note = "";

                if (location.getTypeID() == ::ChaosMind.Altar.TypeID)
                {
                    // The claimed altar is only an empty hollow.
                    if (::ChaosMind.Altar.isClaimed())
                    {
                        continue;
                    }

                    note = "this mod";
                }
                else
                {
                    try
                    {
                        if (!location.isDiscovered())
                        {
                            note = "not found yet";
                        }
                    }
                    catch (e)
                    {
                    }
                }

                found.push({ Name = location.getName(), Tile = location.getTile(), Note = note });
            }
            catch (e)
            {
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
        this.LastCount = found.len();
        local lines = [];

        foreach (boss in found)
        {
            lines.push(this.describe(boss.Name, boss.Tile, boss.Note, here));
        }

        foreach (line in lines)
        {
            ::logInfo("Chaos Mind: boss: " + line);
        }

        if (lines.len() > this.MaxLines)
        {
            local more = lines.len() - this.MaxLines;
            lines = lines.slice(0, this.MaxLines);
            lines.push("... and " + more + " more further away (all listed in log.html).");
        }

        if (lines.len() == 0)
        {
            lines.push("No bosses found in this world.");
        }

        return lines;
    }

    function show()
    {
        this.LastCount = 0;
        local lines = this.getLines();
        return ::ChaosMind.Notice.toggle("Bosses (" + this.LastCount + ")", lines);
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
