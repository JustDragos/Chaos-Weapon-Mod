// Leader duels. When the company is about to fight a party that has a leader (a champion, or a
// unit like a brigand leader, warlord, chieftain or knight), that leader may step forward and
// demand a duel before the battle (event.chaos_mind_duel).
//  - His squad's armor makes him stronger in the duel: +BuffPerStep to all his combat stats for
//    every ArmorPerStep armor (head + body) his whole party wears, up to MaxBuff.
//  - The chance he challenges grows with that buff: BaseChance + buff% * ChancePerBuff, up to
//    MaxChance. Each party challenges at most once.
//  - Accept: one brother fights him alone (a scripted combat on the same terrain). Refuse: the
//    normal battle, no duel and no buff.
//  - Win: he is taken out of his party, and the main battle starts with his men Breaking.
//    Lose: the main battle starts with them Confident.
//
// The combat plumbing (showCombatDialog, startScriptedCombat, CombatInfo fields,
// registerToShowAfterCombat, tactical_entity_manager.spawn) follows the readable copies of these
// vanilla functions in the open-source Legends mod.
::ChaosMind.Duel <- {
    EventID = "event.chaos_mind_duel",
    CombatID = "ChaosMind.Duel",
    OfferedFlag = "ChaosMind.DuelOffered",

    ArmorPerStep = 300,
    BuffPerStep = 0.2,
    MaxBuff = 3.0,
    BaseChance = 49,
    ChancePerBuff = 0.5,
    MaxChance = 95,
    // A troop's estimated head + body armor: its strength times this.
    ArmorPerStrength = 8,

    LeaderWords = [ "leader", "warlord", "chieftain", "champion", "king", "knight", "commander", "captain", "boss" ],
    MaxCandidates = 5,

    // The challenge being handled (see challenge()).
    Current = null,
    // Morale the next main battle starts with: { Faction, State, Day }.
    PendingMorale = null,
    // While set, showCombatDialog runs untouched (resuming the battle after the event).
    Bypass = false,

    function isLeaderTroop( _t )
    {
        if (_t.Variant != 0)
        {
            return true;
        }

        local script = _t.Script.tolower();

        foreach (word in this.LeaderWords)
        {
            if (script.find(word) != null)
            {
                return true;
            }
        }

        return false;
    }

    function getStrength( _t )
    {
        return ("Strength" in _t) ? _t.Strength : 10;
    }

    // The party's leader troop: a champion first, else the strongest leader-type unit.
    function findLeader( _party )
    {
        local best = null;

        foreach (t in _party.getTroops())
        {
            if (t.Script == "" || !this.isLeaderTroop(t))
            {
                continue;
            }

            if (best == null || (t.Variant != 0 && best.Variant == 0)
                || ((t.Variant != 0) == (best.Variant != 0) && this.getStrength(t) > this.getStrength(best)))
            {
                best = t;
            }
        }

        return best;
    }

    function getLeaderName( _t )
    {
        if (_t.Variant != 0 && ("Name" in _t) && _t.Name != null && _t.Name != "")
        {
            return _t.Name;
        }

        return ::Const.Strings.EntityName[_t.ID];
    }

    // Head + body armor of the whole party, estimated from each troop's strength.
    // It used to build every troop as a battle unit in the temporary roster and measure its gear,
    // but enemy units can't be built on the world map: their onInit needs Tactical.State ("the
    // index 'State' does not exist", once per troop), and the half-built units were left behind
    // right before the duel started. The duel then crashed the game ("Class/Structure with key ""
    // is not registered", 1 Nov).
    function estimateArmor( _party )
    {
        local total = 0;

        foreach (t in _party.getTroops())
        {
            if (t.Script != "")
            {
                total += this.getStrength(t) * this.ArmorPerStrength;
            }
        }

        return total;
    }

    function getBuff( _armor )
    {
        return ::Math.minf(this.MaxBuff, (_armor / this.ArmorPerStep) * this.BuffPerStep);
    }

    function getChance( _buff )
    {
        return ::Math.min(this.MaxChance, (this.BaseChance + _buff * 100 * this.ChancePerBuff).tointeger());
    }

    // The first hostile party at _pos that has a leader and hasn't challenged before.
    function findParty( _pos )
    {
        foreach (party in ::World.getAllEntitiesAtPos(_pos, ::Const.World.CombatSettings.CombatPlayerDistance))
        {
            if (!party.isAlive() || party.isPlayerControlled() || party.isLocation() || party.isAlliedWithPlayer())
            {
                continue;
            }

            if (!party.isAttackable() || party.getFaction() == 0 || party.getTroops().len() == 0)
            {
                continue;
            }

            if (party.getFlags().has(this.OfferedFlag))
            {
                continue;
            }

            if (this.findLeader(party) != null)
            {
                return party;
            }
        }

        return null;
    }

    // Called instead of the engage dialog. Returns true if a challenge was issued.
    function challenge( _isPlayerInitiated, _pos )
    {
        if (_pos == null)
        {
            _pos = ::World.State.getPlayer().getPos();
        }

        local party = this.findParty(_pos);

        if (party == null)
        {
            return false;
        }

        party.getFlags().set(this.OfferedFlag, true);

        local leader = this.findLeader(party);
        local armor = this.estimateArmor(party);
        local buff = this.getBuff(armor);
        local chance = this.getChance(buff);
        local roll = ::Math.rand(1, 100);

        ::logInfo("Chaos Mind: " + this.getLeaderName(leader) + " (" + party.getName() + "): squad armor " + armor + ", +"
            + (buff * 100).tointeger() + "% stats, " + chance + "% to challenge, rolled " + roll + ".");

        if (roll > chance)
        {
            return false;
        }

        this.Current = {
            Party = ::WeakTableRef(party),
            Leader = leader,
            LeaderName = this.getLeaderName(leader),
            Armor = armor,
            Buff = buff,
            Pos = _pos,
            IsPlayerInitiated = _isPlayerInitiated,
            Candidates = this.getCandidates(),
            Duelist = null
        };

        ::World.Events.fire(this.EventID);
        return true;
    }

    // Brothers offered as duelists: the Chaos Mind wielder first, then the highest level.
    function getCandidates()
    {
        local bros = [];

        foreach (bro in ::World.getPlayerRoster().getAll())
        {
            if (bro.isAlive())
            {
                bros.push(bro);
            }
        }

        bros.sort(function( _a, _b )
        {
            local wa = _a.getMainhandItem() != null && _a.getMainhandItem().getID() == ::ChaosMind.SwordID;
            local wb = _b.getMainhandItem() != null && _b.getMainhandItem().getID() == ::ChaosMind.SwordID;

            if (wa != wb)
            {
                return wa ? -1 : 1;
            }

            return _b.getLevel() <=> _a.getLevel();
        });

        return bros.len() > this.MaxCandidates ? bros.slice(0, this.MaxCandidates) : bros;
    }

    function startDuel( _event, _index )
    {
        local c = this.Current;

        if (c == null || ::MSU.isNull(c.Party) || _index >= c.Candidates.len())
        {
            return "Gone";
        }

        local bro = c.Candidates[_index];
        c.Duelist = bro.getName();

        local tile = ::World.getTile(::World.worldToTile(c.Pos));
        local p = ::Const.Tactical.CombatInfo.getClone();
        p.Tile = tile;
        p.TerrainTemplate = ::Const.World.TerrainTacticalTemplate[tile.TacticalType];
        p.CombatID = this.CombatID;
        p.Music = ::Const.Music.BattleTracks;
        p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.Line;
        p.EnemyDeploymentType = ::Const.Tactical.DeploymentType.Line;
        p.IsPlayerInitiated = true;
        p.IsUsingSetPlayers = true;
        p.Players = [ bro ];
        p.IsFleeingProhibited = true;
        p.IsAutoAssigningBases = false;
        p.Entities = [];

        // The leader fights for the built-in enemy faction, unlinked from his world party, the way
        // events build their enemies (e.g. Legends' religious_peasants_event): with
        // IsAutoAssigningBases off, a world faction (Bandits, Barbarians...) gets no battlefield
        // setup, and the game crashed at round start and at his turn ("Class/Structure with key
        // "" is not registered", 1 Nov, twice). His troop keeps its name and champion roll.
        local t = clone c.Leader;
        t.Faction <- ::Const.Faction.Enemy;

        if ("Party" in t)
        {
            delete t.Party;
        }

        p.Entities.push(t);

        p.AfterDeploymentCallback = function()
        {
            ::ChaosMind.Duel.onDuelDeployed();
        };

        ::logInfo("Chaos Mind: " + bro.getName() + " duels " + c.LeaderName + ".");
        _event.registerToShowAfterCombat("Won", "Lost");
        ::World.State.startScriptedCombat(p, false, false, false);
        return 0;
    }

    // In the duel: the only enemy on the field is the leader; give him his squad's strength.
    function onDuelDeployed()
    {
        local c = this.Current;

        if (c == null || c.Buff <= 0)
        {
            return;
        }

        foreach (faction in ::Tactical.Entities.getAllInstances())
        {
            foreach (actor in faction)
            {
                if (actor.isAlive() && !actor.isPlayerControlled())
                {
                    local effect = ::new("scripts/skills/effects/duel_leader_effect");
                    effect.m.Buff = c.Buff;
                    actor.getSkills().add(effect);
                    actor.getSkills().update();
                    actor.setHitpoints(actor.getHitpointsMax());
                    actor.setDirty(true);
                }
            }
        }
    }

    // After the duel was won: the leader leaves his party for good.
    function removeLeader()
    {
        local c = this.Current;

        if (c == null || ::MSU.isNull(c.Party))
        {
            return;
        }

        local troops = c.Party.getTroops();

        foreach (i, t in troops)
        {
            if (t == c.Leader)
            {
                troops.remove(i);
                break;
            }
        }

        try
        {
            c.Party.updateStrength();
        }
        catch (e)
        {
        }
    }

    function hasMenLeft()
    {
        local c = this.Current;
        return c != null && !::MSU.isNull(c.Party) && c.Party.isAlive() && c.Party.getTroops().len() != 0;
    }

    // The main battle: back to the game's own engage dialog, with the outcome's morale queued.
    // Opened a moment later, once the event window has closed (MSU uses scheduleEvent the same way).
    function resumeBattle( _morale )
    {
        local c = this.Current;

        if (c == null)
        {
            return;
        }

        if (_morale != null && !::MSU.isNull(c.Party))
        {
            this.PendingMorale = { Faction = c.Party.getFaction(), State = _morale, Day = ::World.getTime().Days };
        }

        this.Current = null;
        ::Time.scheduleEvent(::TimeUnit.Real, 300, function( _c )
        {
            ::ChaosMind.Duel.showBattle(_c);
        }, c);
    }

    function showBattle( _c )
    {
        // An attacking party may already have reopened the engage dialog by itself.
        if (::World.State.m.EngageCombatPos != null)
        {
            return;
        }

        this.Bypass = true;

        try
        {
            ::World.State.showCombatDialog(_c.IsPlayerInitiated, true, true, null, _c.Pos);
        }
        catch (e)
        {
            ::logError("Chaos Mind: could not return to the battle after the duel (" + e + ").");
        }

        this.Bypass = false;
    }

    // The leader fell and he had no men: his party is beaten.
    function endWithoutBattle()
    {
        local c = this.Current;
        this.Current = null;

        if (c != null && !::MSU.isNull(c.Party) && c.Party.isAlive())
        {
            try
            {
                c.Party.onCombatLost();
            }
            catch (e)
            {
                ::logWarning("Chaos Mind: the beaten leader's party could not be removed (" + e + ").");
            }
        }
    }

    // Main battle spawned: his men start Breaking (duel won) or Confident (duel lost).
    function onBattleSpawned( _properties )
    {
        local pending = this.PendingMorale;
        this.PendingMorale = null;

        if (pending == null || _properties.CombatID == this.CombatID || pending.Day != ::World.getTime().Days)
        {
            return;
        }

        local count = 0;

        foreach (actor in ::Tactical.Entities.getInstancesOfFaction(pending.Faction))
        {
            if (actor.isAlive())
            {
                actor.setMoraleState(pending.State);
                count += 1;
            }
        }

        ::logInfo("Chaos Mind: " + count + " of the leader's men start the battle "
            + (pending.State == ::Const.MoraleState.Confident ? "Confident" : "Breaking") + ".");
    }
};


::ChaosMind.HooksMod.hook("scripts/states/world_state", function(q)
{
    q.showCombatDialog = @(__original) function( _isPlayerInitiated = true, _isCombatantsVisible = true, _allowFormationPicking = true, _properties = null, _pos = null )
    {
        local duel = ::ChaosMind.Duel;

        if (!duel.Bypass && _properties == null)
        {
            try
            {
                if (duel.challenge(_isPlayerInitiated, _pos))
                {
                    return;
                }
            }
            catch (e)
            {
                ::logWarning("Chaos Mind: duel check failed (" + e + ").");
            }
        }

        return __original(_isPlayerInitiated, _isCombatantsVisible, _allowFormationPicking, _properties, _pos);
    }
});

::ChaosMind.HooksMod.hook("scripts/entity/tactical/tactical_entity_manager", function(q)
{
    if (!q.contains("spawn", true))
    {
        ::logWarning("Chaos Mind: tactical_entity_manager has no spawn; the duel's effect on the main battle's morale is off.");
        return;
    }

    q.spawn = @(__original) function( _properties )
    {
        local ret = __original(_properties);

        try
        {
            ::ChaosMind.Duel.onBattleSpawned(_properties);
        }
        catch (e)
        {
            ::logWarning("Chaos Mind: duel morale could not be applied (" + e + ").");
        }

        return ret;
    }
});
