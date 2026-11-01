// The Black Skull: a three-part hunt that unlocks as Chaos Mind's kills grow (100, 200, 500).
//  - When the company's blade has enough kills for the next part and the company enters a town
//    (comes within NearTownDistance of it), the event event.chaos_mind_quest offers the hunt.
//  - Accepting spawns a marked party (black skull banner, selection ring on the map) a few tiles
//    from that town, led by a guaranteed champion. AI parties leave it alone (setAttackableByAI).
//  - The leader must die to Chaos Mind (its wielder's attacks, cloud or curse; chaos_mind_effect
//    calls onSwordKill). Once the party is gone, the part is done if he did, and failed if he
//    didn't: then it's offered again from the next day, with a new party.
//  - The reward: while wielding Chaos Mind, +Rate max fatigue (property Stamina) per +1% damage
//    the blade has from kills; Rate grows each part.
//  - Ctrl+F shows where the marked party is (::ChaosMind.Altar.showDirection hands over to it).
// Spawning follows the readable hunt contracts in the open-source Legends mod (spawnEntity,
// addTroop with a minibossify bonus, setAttackableByAI, the banner and selection sprites, roam_order).
::ChaosMind.Quest <- {
    EventID = "event.chaos_mind_quest",
    DoneFlag = "ChaosMind.QuestDone",
    ActiveFlag = "ChaosMind.QuestActive",
    TargetFlag = "ChaosMind.QuestTargetID",
    DeclinedDayFlag = "ChaosMind.QuestDeclinedDay",
    LeaderNameFlag = "ChaosMind.QuestLeaderName",
    LeaderSlainFlag = "ChaosMind.QuestLeaderSlain",
    LeaderClassFlag = "ChaosMind.QuestLeaderClass",
    // Black with a white skull. Needs a UI picture (gfx/ui/banners/<name>.png) as well as a map
    // sprite: banner_undead_02 had none, and the duel window logged it missing.
    Banner = "banner_orcs_01",
    // At the gates or inside: checked on every world update, not once an hour, so a short visit
    // isn't missed.
    NearTownDistance = 1,
    MinSpawnDistance = 5,
    MaxSpawnDistance = 9,
    // A champion leader is guaranteed: addTroop keeps the champion roll if rand(1, 100) <= Variant + this.
    LeaderMinibossify = 1000,

    Tiers = [
        {
            Kills = 100, Rate = 0.1, Name = "Black Skull Brigands", Faction = "Bandits",
            Template = "BanditRaiders", Leader = "BanditLeader", Resources = 260,
            Description = "Brigands marching under a black skull. Their leader has sworn to take the blade that devours."
        },
        {
            Kills = 200, Rate = 0.25, Name = "Black Skull Reavers", Faction = "Barbarians",
            Template = "Barbarians", Leader = "BarbarianChampion", Resources = 450,
            Description = "Northern reavers under a black skull, come south for the blade they call the Hungry Iron."
        },
        {
            Kills = 500, Rate = 0.5, Name = "Black Skull Warband", Faction = "Orcs",
            Template = "OrcRaiders", Leader = "OrcWarlord", Resources = 700,
            Description = "An orc warband under a black skull. Its warlord wants to feed the blade to his own gods."
        }
    ],

    // Set before the event fires: the town it happens in, the screen to open, the party spawned.
    Town = null,
    PartyName = "",
    PendingScreen = null,
    LastTarget = null,
    LastHourChecked = -1,
    // Whether the next part is open (enough kills, nothing running, not turned down today);
    // worked out once an hour, so the per-update town check stays cheap.
    IsOpen = false,
    StaminaWarningShown = false,

    function getFlag( _name )
    {
        return ::World.Flags.has(_name) ? ::World.Flags.get(_name) : 0;
    }

    // Parts finished so far (0 to 3).
    function getDone()
    {
        return this.getFlag(this.DoneFlag);
    }

    // Part being hunted now (1 to 3), or 0.
    function getActive()
    {
        return this.getFlag(this.ActiveFlag);
    }

    function getTarget()
    {
        local id = this.getFlag(this.TargetFlag);

        if (id == 0)
        {
            return null;
        }

        local party = ::World.getEntityByID(id);
        return (party != null && party.isAlive()) ? party : null;
    }

    // While wielding Chaos Mind: +Rate max fatigue per +1% kill bonus, Rate of the last part done.
    function getStaminaBonus( _weapon )
    {
        local done = this.getDone();

        if (done == 0)
        {
            return 0;
        }

        return ::Math.floor(this.Tiers[done - 1].Rate * _weapon.getKillBonus());
    }

    function addStamina( _properties, _weapon )
    {
        local bonus = this.getStaminaBonus(_weapon);

        if (bonus <= 0)
        {
            return;
        }

        if ("Stamina" in _properties)
        {
            _properties.Stamina += bonus;
        }
        else if (!this.StaminaWarningShown)
        {
            this.StaminaWarningShown = true;
            ::logWarning("Chaos Mind: the Black Skull reward found no Stamina property; max fatigue unchanged.");
        }
    }

    function findNearTown()
    {
        local here = ::World.State.getPlayer().getTile();

        foreach (town in ::World.EntityManager.getSettlements())
        {
            if (town != null && town.isAlive() && here.getDistanceTo(town.getTile()) <= this.NearTownDistance)
            {
                return town;
            }
        }

        return null;
    }

    // World map, on every update with a clear screen (a world check, see chaos_mind/common.nut).
    // The running hunt and whether a part is open are checked once an hour; the town every time.
    function check()
    {
        if (!::ChaosMind.SoulArrow.canShowEvent())
        {
            return;
        }

        local hour = ::ChaosMind.getHour();

        if (hour != this.LastHourChecked)
        {
            this.LastHourChecked = hour;

            if (this.getActive() != 0)
            {
                this.IsOpen = false;
                this.checkActive();
                return;
            }

            this.IsOpen = this.isNextPartOpen();
        }

        if (!this.IsOpen)
        {
            return;
        }

        local town = this.findNearTown();

        if (town == null)
        {
            return;
        }

        local done = this.getDone();
        this.IsOpen = false;
        this.Town = town;
        this.PartyName = this.Tiers[done].Name;
        ::logInfo("Chaos Mind: the Black Skull (part " + (done + 1) + ") is offered at " + town.getName() + ".");
        this.fireEvent("Offer");
    }

    function isNextPartOpen()
    {
        local done = this.getDone();

        if (done >= this.Tiers.len() || ::World.getTime().Days <= this.getFlag(this.DeclinedDayFlag))
        {
            return false;
        }

        local sword = ::ChaosMind.findSword();
        return sword != null && sword.m.Kills >= this.Tiers[done].Kills;
    }

    // The script's file name of a troop ("bandit_leader"), which ::isKindOf matches.
    function getClassName( _troop )
    {
        local parts = split(_troop.Script, "/");
        return parts.len() != 0 ? parts[parts.len() - 1] : "";
    }

    function recordLeader( _troop )
    {
        ::World.Flags.set(this.LeaderNameFlag, ::ChaosMind.Duel.getLeaderName(_troop));
        ::World.Flags.set(this.LeaderClassFlag, this.getClassName(_troop));
    }

    // The leader the blade has to kill: { Name, Class }. Parties spawned before this was recorded
    // get it from their troops, the way the duel finds a leader.
    function getLeader( _target )
    {
        local name = ::World.Flags.has(this.LeaderNameFlag) ? ::World.Flags.get(this.LeaderNameFlag) : "";

        if (name == "" && _target != null)
        {
            local leader = ::ChaosMind.Duel.findLeader(_target);

            if (leader != null)
            {
                this.recordLeader(leader);
                name = ::World.Flags.get(this.LeaderNameFlag);
            }
        }

        local cls = ::World.Flags.has(this.LeaderClassFlag) ? ::World.Flags.get(this.LeaderClassFlag) : "";
        return { Name = name, Class = cls };
    }

    // Is _actor the marked leader? By name; or, in case a champion's name isn't his troop's in
    // battle (couldn't be confirmed), a champion of the leader's type from the party's faction.
    function isLeader( _actor, _leader, _target )
    {
        if (_leader.Name != "" && _actor.getName() == _leader.Name)
        {
            return true;
        }

        // In a leader duel he fights for the built-in enemy faction instead (chaos_mind/duel.nut).
        local faction = _actor.getFaction();

        if (_leader.Class == "" || _target == null || (faction != _target.getFaction() && faction != ::Const.Faction.Enemy))
        {
            return false;
        }

        local isChampion = ("IsMiniboss" in _actor.m) && _actor.m.IsMiniboss;
        return isChampion && ::isKindOf(_actor, _leader.Class);
    }

    // Chaos Mind killed someone (chaos_mind_effect.onTargetKilled): was it the marked leader?
    function onSwordKill( _user, _target )
    {
        if (this.getActive() == 0 || _target.isAlliedWith(_user))
        {
            return;
        }

        local party = this.getTarget();
        local leader = this.getLeader(party);

        if (!this.isLeader(_target, leader, party))
        {
            return;
        }

        ::World.Flags.set(this.LeaderSlainFlag, true);
        ::logInfo("Chaos Mind: " + _target.getName() + ", the Black Skull's leader, was slain by the blade.");

        try
        {
            ::Tactical.EventLog.log(::Const.UI.getColorizedEntityName(_target) + " falls to Chaos Mind. The black skull is broken");
        }
        catch (e)
        {
        }
    }

    function clearHunt()
    {
        ::World.Flags.set(this.ActiveFlag, 0);
        ::World.Flags.set(this.TargetFlag, 0);
        ::World.Flags.set(this.LeaderNameFlag, "");
        ::World.Flags.set(this.LeaderClassFlag, "");
        ::World.Flags.set(this.LeaderSlainFlag, false);
    }

    function checkActive()
    {
        local target = this.getTarget();

        if (target != null)
        {
            // The ring isn't saved; mark it again after loading. The banner too, for parties
            // spawned before it changed.
            try
            {
                target.getSprite("selection").Visible = true;
                target.getSprite("banner").setBrush(this.Banner);
            }
            catch (e)
            {
            }

            this.getLeader(target);
            return;
        }

        local tier = this.getActive();
        local slain = ::World.Flags.has(this.LeaderSlainFlag) && ::World.Flags.get(this.LeaderSlainFlag);
        this.PartyName = this.Tiers[tier - 1].Name;
        this.clearHunt();

        if (!slain)
        {
            ::World.Flags.set(this.DeclinedDayFlag, ::World.getTime().Days);
            ::logInfo("Chaos Mind: the Black Skull (part " + tier + ") failed: the party is gone, but its leader didn't die to the blade.");
            this.fireEvent("Failed");
            return;
        }

        ::World.Flags.set(this.DoneFlag, tier);
        ::logInfo("Chaos Mind: the Black Skull (part " + tier + ") is done; max fatigue rate now " + this.Tiers[tier - 1].Rate + " per +1% damage.");
        this.fireEvent("Done");
    }

    function fireEvent( _screen )
    {
        this.PendingScreen = _screen;
        ::World.Events.fire(this.EventID);
    }

    function decline()
    {
        ::World.Flags.set(this.DeclinedDayFlag, ::World.getTime().Days);
    }

    function isGoodSpawnTile( _tile, _from )
    {
        local t = ::Const.World.TerrainType;

        if (_tile.IsOccupied || _tile.Type == t.Ocean || _tile.Type == t.Shore || _tile.Type == t.Mountains)
        {
            return false;
        }

        local d = _tile.getDistanceTo(_from);

        if (d < this.MinSpawnDistance || d > this.MaxSpawnDistance)
        {
            return false;
        }

        local nav = ::World.getNavigator().createSettings();
        nav.ActionPointCosts = ::Const.World.TerrainTypeNavCost_Flat;
        return !::World.getNavigator().findPath(_tile, _from, nav, 0).isEmpty();
    }

    function findSpawnTile( _town )
    {
        local from = _town.getTile();
        local cx = from.SquareCoords.X;
        local cy = from.SquareCoords.Y;

        for (local attempt = 0; attempt < 300; ++attempt)
        {
            local x = cx + ::Math.rand(-this.MaxSpawnDistance, this.MaxSpawnDistance);
            local y = cy + ::Math.rand(-this.MaxSpawnDistance, this.MaxSpawnDistance);

            if (!::World.isValidTileSquare(x, y))
            {
                continue;
            }

            local tile = ::World.getTileSquare(x, y);

            if (this.isGoodSpawnTile(tile, from))
            {
                return tile;
            }
        }

        return null;
    }

    function getFaction( _type )
    {
        local types = [ _type, "Bandits" ];

        foreach (name in types)
        {
            if (name in ::Const.FactionType)
            {
                local faction = ::World.FactionManager.getFactionOfType(::Const.FactionType[name]);

                if (faction != null)
                {
                    return faction;
                }
            }
        }

        return null;
    }

    // Accepting the hunt: spawns the marked party near this.Town. Returns it, or null.
    // The hunt is recorded as soon as the party exists; every later step is guarded, so a failure
    // can't leave an unrecorded party behind (and a second one spawned the next time).
    function spawnTarget()
    {
        local tier = this.getDone() + 1;
        local def = this.Tiers[tier - 1];

        if (this.Town == null || !this.Town.isAlive())
        {
            ::logError("Chaos Mind: the Black Skull has no town to start from.");
            return null;
        }

        local tile = null;

        try
        {
            tile = this.findSpawnTile(this.Town);
        }
        catch (e)
        {
            ::logError("Chaos Mind: the Black Skull could not look for a tile (" + e + ").");
        }

        local faction = this.getFaction(def.Faction);
        local template = (def.Template in ::Const.World.Spawn) ? ::Const.World.Spawn[def.Template] : ::Const.World.Spawn.BanditRaiders;

        if (tile == null || faction == null)
        {
            ::logError("Chaos Mind: the Black Skull could not spawn (" + (tile == null ? "no free tile near " + this.Town.getName() : "no " + def.Faction + " faction") + ").");
            return null;
        }

        local party = faction.spawnEntity(tile, def.Name, false, template, def.Resources);

        if (party == null)
        {
            ::logError("Chaos Mind: the Black Skull party could not be created.");
            return null;
        }

        this.clearHunt();
        ::World.Flags.set(this.ActiveFlag, tier);
        ::World.Flags.set(this.TargetFlag, party.getID());
        this.LastTarget = party;

        local steps = [
            [ "its look", function( _party, _def )
            {
                _party.setDescription(_def.Description);
                _party.getSprite("banner").setBrush(this.Banner);
                _party.getSprite("selection").Visible = true;
            } ],
            [ "protection from other parties", function( _party, _def )
            {
                _party.setAttackableByAI(false);
            } ],
            // A champion at its head: the one the blade has to kill.
            [ "a champion leader", function( _party, _def )
            {
                local key = (_def.Leader in ::Const.World.Spawn.Troops) ? _def.Leader : "BanditLeader";
                local leader = ::Const.World.Common.addTroop(_party, { Type = ::Const.World.Spawn.Troops[key] }, true, this.LeaderMinibossify);
                this.recordLeader(leader);
                local name = ::World.Flags.get(this.LeaderNameFlag);
                ::logInfo("Chaos Mind: the Black Skull is led by " + (leader.Variant != 0 ? "the champion " : "") + name
                    + (leader.Variant != 0 ? "." : " (no champion roll: is Warriors of the North missing?)."));
            } ],
            // It stays around the town.
            [ "a roaming order", function( _party, _def )
            {
                local roam = ::new("scripts/ai/world/orders/roam_order");
                roam.setPivot(this.Town);
                roam.setMinRange(this.MinSpawnDistance);
                roam.setMaxRange(this.MaxSpawnDistance);
                roam.setAllTerrainAvailable();
                roam.setTerrain(::Const.World.TerrainType.Ocean, false);
                roam.setTerrain(::Const.World.TerrainType.Shore, false);
                roam.setTerrain(::Const.World.TerrainType.Mountains, false);
                _party.getController().addOrder(roam);
            } ]
        ];

        foreach (step in steps)
        {
            try
            {
                step[1].call(this, party, def);
            }
            catch (e)
            {
                ::logWarning("Chaos Mind: the Black Skull party got no " + step[0] + " (" + e + ").");
            }
        }

        ::logInfo("Chaos Mind: the Black Skull (part " + tier + ") spawned: " + this.describeTarget(party) + ".");
        return party;
    }

    function describeTarget( _party )
    {
        return _party.getName() + " " + ::ChaosMind.Altar.describeLocation(_party.getTile());
    }

    // Ctrl+F once the sword is claimed: where the marked party is. False when there's none.
    function showDirection()
    {
        local target = this.getActive() != 0 ? this.getTarget() : null;

        if (target == null)
        {
            ::ChaosMind.Notice.close();
            return false;
        }

        local text = "The " + this.describeTarget(target) + ".";
        ::logInfo("Chaos Mind: " + text);
        return ::ChaosMind.Notice.toggle("The Black Skull", [ text ]);
    }
};


::ChaosMind.addWorldCheck("Black Skull check", function()
{
    ::ChaosMind.Quest.check();
});
