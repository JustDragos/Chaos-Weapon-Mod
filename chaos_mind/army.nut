// Army of the Past (13 Nov): a three-part contract against hosts of plain, weak skeletons.
//  - Part 1 at 100 Chaos Mind kills: 50 skeletons; part 2 at 200: 100; part 3 at 500: 150.
//  - Offered as a real contract by the town the company comes to (chaos_mind/contracts.nut,
//    scripts/contracts/contracts/chaos_mind_army_contract.nut), with a purple banner and a white skull.
//  - The host is split into groups of GroupSize (one battle each), spawned at least
//    MinGroupDistance tiles apart and kept from wandering or attacking, so two groups never end up
//    in the same battle. The part is done once every group is gone.
//  - The skeletons are Ancient Auxiliaries (the weakest), never champions (the blade's champion
//    roll is skipped in these battles) and frailer than usual (army_of_the_past_effect). Their
//    turns run FastSpeed times faster, so their moves play almost at once; the brothers' turns run
//    at normal speed.
::ChaosMind.Army <- {
    PartyFlag = "ChaosMind.ArmyParty",
    DoneFlag = "ChaosMind.ArmyDone",
    ActiveFlag = "ChaosMind.ArmyActive",
    TargetsFlag = "ChaosMind.ArmyTargets",
    DeclinedDayFlag = "ChaosMind.ArmyDeclinedDay",
    Name = "Army of the Past",
    Description = "The dead of an old war, marching again in their thousands. These are the least of them, but there are very many.",
    Troop = "SkeletonLight",
    GroupSize = 50,
    MinGroupDistance = 5,
    // The skeletons' hitpoints are multiplied by this.
    HitpointsMult = 0.5,
    // Game speed during the skeletons' turns (1.0 is normal).
    FastSpeed = 6.0,

    // Count: skeletons in all. Pay and DifficultyMult: the contract's crowns before haggling, and
    // its skulls in town.
    Tiers = [
        { Kills = 100, Count = 50, Pay = 600, DifficultyMult = 0.85 },
        { Kills = 200, Count = 100, Pay = 1000, DifficultyMult = 1.05 },
        { Kills = 500, Count = 150, Pay = 1600, DifficultyMult = 1.35 }
    ],

    Town = null,
    LastHourChecked = -1,
    SpeedWarningShown = false,

    function getDone()
    {
        return ::ChaosMind.Quest.getFlag(this.DoneFlag);
    }

    // Part being fought now (1 to 3), or 0.
    function getActive()
    {
        return ::ChaosMind.Quest.getFlag(this.ActiveFlag);
    }

    // The groups still alive.
    function getTargets()
    {
        local targets = [];
        local text = ::World.Flags.has(this.TargetsFlag) ? ::World.Flags.get(this.TargetsFlag) : "";

        if (typeof text != "string" || text == "")
        {
            return targets;
        }

        foreach (id in split(text, ","))
        {
            local party = ::World.getEntityByID(id.tointeger());

            if (party != null && party.isAlive())
            {
                targets.push(party);
            }
        }

        return targets;
    }

    function isOpen()
    {
        local done = this.getDone();

        if (done >= this.Tiers.len() || this.getActive() != 0 || ::World.getTime().Days <= ::ChaosMind.Quest.getFlag(this.DeclinedDayFlag))
        {
            return false;
        }

        local sword = ::ChaosMind.findSword();
        return sword != null && sword.m.Kills >= this.Tiers[done].Kills;
    }

    // One-time repair (14 Nov): the old hourly fallback marked part 1 done after a cancelled
    // contract, without a fight. On loading a save once, "part 1 done, nothing running" goes back
    // to not done. Army of the Past came on 13 Nov and wasn't won by contract in that campaign.
    function repairWrongDone()
    {
        local fixFlag = "ChaosMind.ArmyFix14Nov";

        if (::World.Flags.has(fixFlag))
        {
            return;
        }

        ::World.Flags.set(fixFlag, true);

        if (this.getDone() == 1 && this.getActive() == 0)
        {
            ::World.Flags.set(this.DoneFlag, 0);
            ::logInfo("Chaos Mind: Army of the Past part 1 was marked done without a fight; it's open again.");
        }
    }

    function decline()
    {
        ::World.Flags.set(this.DeclinedDayFlag, ::World.getTime().Days);
    }

    function clearHunt()
    {
        ::World.Flags.set(this.ActiveFlag, 0);
        ::World.Flags.set(this.TargetsFlag, "");
    }

    // Hourly: every group shown through the fog (older saves too).
    function check()
    {
        local hour = ::ChaosMind.getHour();

        if (hour == this.LastHourChecked)
        {
            return;
        }

        this.LastHourChecked = hour;

        foreach (group in this.getTargets())
        {
            ::ChaosMind.markTarget(group);
        }

        // No fallback any more (14 Nov): it marked part 1 done after a cancelled contract. A hunt
        // only runs with its contract, which finishes it; without one it's called off
        // (::ChaosMind.Contracts.callOffOrphans).
    }

    // A tile for the next group: near the town, and far enough from the groups already placed.
    function findGroupTile( _town, _placed )
    {
        local q = ::ChaosMind.Quest;
        local from = _town.getTile();

        for (local attempt = 0; attempt < 400; ++attempt)
        {
            local x = from.SquareCoords.X + ::Math.rand(-q.MaxSpawnDistance - 3, q.MaxSpawnDistance + 3);
            local y = from.SquareCoords.Y + ::Math.rand(-q.MaxSpawnDistance - 3, q.MaxSpawnDistance + 3);

            if (!::World.isValidTileSquare(x, y))
            {
                continue;
            }

            local tile = ::World.getTileSquare(x, y);
            local tooClose = false;

            foreach (t in _placed)
            {
                if (tile.getDistanceTo(t) < this.MinGroupDistance)
                {
                    tooClose = true;
                    break;
                }
            }

            if (!tooClose && q.isGoodSpawnTile(tile, from))
            {
                return tile;
            }
        }

        return null;
    }

    // A plain Ancient Auxiliary that never rolls a champion.
    function getSkeletonType()
    {
        local troops = ::Const.World.Spawn.Troops;
        local type = clone troops[(this.Troop in troops) ? this.Troop : "SkeletonMedium"];
        type.Variant <- 0;
        return type;
    }

    // Accepting the contract: spawns the host near this.Town. Returns the groups (may be empty).
    function spawnTargets()
    {
        local tier = this.getDone() + 1;
        local def = this.Tiers[tier - 1];
        local groups = [];
        local faction = ::ChaosMind.Quest.getFaction("Undead");

        if (this.Town == null || !this.Town.isAlive() || faction == null)
        {
            ::logError("Chaos Mind: the Army of the Past could not spawn (" + (faction == null ? "no undead faction" : "no town") + ").");
            return groups;
        }

        local template = ("UndeadArmy" in ::Const.World.Spawn) ? ::Const.World.Spawn.UndeadArmy : null;
        local placed = [];
        local ids = "";

        for (local g = 0; g < def.Count / this.GroupSize; ++g)
        {
            local tile = this.findGroupTile(this.Town, placed);

            if (tile == null)
            {
                ::logWarning("Chaos Mind: no room near " + this.Town.getName() + " for another group of the Army of the Past.");
                break;
            }

            local party = faction.spawnEntity(tile, this.Name, false, template, 100);

            if (party == null)
            {
                continue;
            }

            placed.push(tile);
            groups.push(party);
            ids += (ids == "" ? "" : ",") + party.getID();
            this.setupGroup(party);
        }

        if (groups.len() != 0)
        {
            ::World.Flags.set(this.ActiveFlag, tier);
            ::World.Flags.set(this.TargetsFlag, ids);
        }

        ::logInfo("Chaos Mind: the Army of the Past (part " + tier + ") spawned " + groups.len() + " group(s) of " + this.GroupSize + " near " + this.Town.getName() + ".");
        return groups;
    }

    function setupGroup( _party )
    {
        _party.getFlags().set(this.PartyFlag, true);

        local steps = [
            [ "its skeletons", function( _p )
            {
                _p.getTroops().clear();
                local type = this.getSkeletonType();

                for (local i = 0; i < this.GroupSize; ++i)
                {
                    ::Const.World.Common.addTroop(_p, { Type = type }, i == this.GroupSize - 1, 0);
                }
            } ],
            [ "its look", function( _p )
            {
                _p.setDescription(this.Description);
                ::ChaosMind.markTarget(_p);
            } ],
            [ "protection from other parties", function( _p )
            {
                _p.setAttackableByAI(false);
            } ],
            // It stays where it is: two groups in reach of each other would join one battle.
            [ "orders to hold", function( _p )
            {
                local c = _p.getController();
                local ids = ::Const.World.AI.Behavior.ID;

                foreach (name in [ "Attack", "Flee", "Roam" ])
                {
                    if (name in ids && c.getBehavior(ids[name]) != null)
                    {
                        c.getBehavior(ids[name]).setEnabled(false);
                    }
                }
            } ]
        ];

        foreach (step in steps)
        {
            try
            {
                step[1].call(this, _party);
            }
            catch (e)
            {
                ::logWarning("Chaos Mind: an Army of the Past group got no " + step[0] + " (" + e + ").");
            }
        }
    }

    function isArmyParty( _party )
    {
        return _party != null && !::MSU.isNull(_party) && _party.getFlags().has(this.PartyFlag);
    }

    // In battle: is this fight against a group of the Army of the Past?
    function isArmyBattle()
    {
        try
        {
            local p = ::Tactical.State.getStrategicProperties();

            if (p == null || !("Parties" in p))
            {
                return false;
            }

            foreach (party in p.Parties)
            {
                if (this.isArmyParty(party))
                {
                    return true;
                }
            }
        }
        catch (e)
        {
        }

        return false;
    }

    // Normal speed for the brothers' turns, FastSpeed for the skeletons'.
    function setFast( _fast )
    {
        try
        {
            ::Time.setVirtualSpeed(_fast ? this.FastSpeed : 1.0);
        }
        catch (e)
        {
            if (!this.SpeedWarningShown)
            {
                this.SpeedWarningShown = true;
                ::logWarning("Chaos Mind: the Army of the Past's turns could not be sped up (" + e + ").");
            }
        }

        try
        {
            ::Settings.getTempGameplaySettings().FasterAIMovement = _fast;
        }
        catch (e)
        {
        }
    }

    // After the battle's units are placed: the skeletons get frailer and fast, the brothers keep
    // normal speed on their turns.
    function onBattleSpawned()
    {
        if (!this.isArmyBattle())
        {
            return;
        }

        local skeletons = 0;

        foreach (faction in ::Tactical.Entities.getAllInstances())
        {
            foreach (actor in faction)
            {
                if (!actor.isAlive())
                {
                    continue;
                }

                local effect = ::new("scripts/skills/effects/army_of_the_past_effect");
                effect.m.IsSkeleton = !actor.isPlayerControlled();
                actor.getSkills().add(effect);

                if (effect.m.IsSkeleton)
                {
                    skeletons += 1;
                    actor.getSkills().update();
                    actor.setHitpoints(actor.getHitpointsMax());
                }
            }
        }

        ::logInfo("Chaos Mind: Army of the Past battle, " + skeletons + " skeletons (frail, fast turns).");
    }
};

::ChaosMind.HooksMod.hook("scripts/entity/tactical/tactical_entity_manager", function(q)
{
    if (!q.contains("spawn", true))
    {
        return;
    }

    q.spawn = @(__original) function( _properties )
    {
        local ret = __original(_properties);

        try
        {
            ::ChaosMind.Army.onBattleSpawned();
        }
        catch (e)
        {
            ::logWarning("Chaos Mind: the Army of the Past battle setup failed (" + e + ").");
        }

        return ret;
    }
});

::ChaosMind.addWorldCheck("Army of the Past check", function()
{
    ::ChaosMind.Army.check();
});
