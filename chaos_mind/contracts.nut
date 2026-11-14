// This mod's hunts as real contracts (13 Nov): scripts/contracts/contracts/chaos_mind_*_contract.nut.
//  - Offered: when a hunt is open (the next Black Skull part, the next Army of the Past part, or
//    the Aura of 10 at 250 kills) and
//    the company comes to a town, the contract is added to that town, from its own faction and
//    employer, like the game's contracts. If an unaccepted one waits in another town, it moves to
//    this one, so the town you're in always has it. Once a hunt isn't open any more, an unaccepted
//    contract for it is removed.
//  - In the town's contract row they get a purple banner instead of the faction's
//    (ui/mods/chaos_mind/town_contracts.js), so they stand out as this mod's.
//  - The hunts' rules, parties and rewards are unchanged (chaos_mind/quest.nut, aura.nut); a hunt
//    run by a contract is finished by the contract, otherwise by the hourly checks and events.
//  - Saving (chaos_mind/save_safety.nut): the contracts are taken out of the save so it loads
//    without the mod. An accepted one is recorded in a world flag and rebuilt on load (restore()).
::ChaosMind.Contracts <- {
    // Icon: the banner in the town's contract row (+ .png, b.png, w.png in gfx/).
    Types = {
        BlackSkull = { Type = "contract.chaos_mind_black_skull", Script = "scripts/contracts/contracts/chaos_mind_black_skull_contract", Icon = "ui/chaos_mind/town_quest" },
        Aura = { Type = "contract.chaos_mind_aura", Script = "scripts/contracts/contracts/chaos_mind_aura_contract", Icon = "ui/chaos_mind/town_quest" },
        Army = { Type = "contract.chaos_mind_army", Script = "scripts/contracts/contracts/chaos_mind_army_contract", Icon = "ui/chaos_mind/army_quest" },
        Dragon = { Type = "contract.chaos_mind_dragon", Script = "scripts/contracts/contracts/chaos_mind_dragon_contract", Icon = "ui/chaos_mind/town_quest" }
    },
    ActiveFlag = "ChaosMind.Saved.Contract",
    IconScreen = null,
    LastSent = null,
    LastTime = -1.0,
    Interval = 1.0,

    // The key in Types ("BlackSkull", "Aura", "Army") of one of this mod's contracts, or null.
    function getKey( _contract )
    {
        if (_contract == null)
        {
            return null;
        }

        foreach (key, t in this.Types)
        {
            if (_contract.m.Type == t.Type)
            {
                return key;
            }
        }

        return null;
    }

    function isModContract( _contract )
    {
        return this.getKey(_contract) != null;
    }

    function getActive()
    {
        local c = ::World.Contracts.getActiveContract();
        return this.isModContract(c) ? c : null;
    }

    function isActive( _key )
    {
        local c = this.getActive();
        return c != null && c.m.Type == this.Types[_key].Type;
    }

    function findOpen( _key )
    {
        foreach (c in ::World.Contracts.m.Open)
        {
            if (c.m.Type == this.Types[_key].Type)
            {
                return c;
            }
        }

        return null;
    }

    function isOpen( _key )
    {
        if (_key == "BlackSkull")
        {
            local q = ::ChaosMind.Quest;
            return q.getActive() == 0 && q.isNextPartOpen();
        }

        if (_key == "Army")
        {
            return ::ChaosMind.Army.isOpen();
        }

        if (_key == "Dragon")
        {
            return ::ChaosMind.Dragon.isOpen();
        }

        return ::ChaosMind.Aura.isOpen();
    }

    // World map, every update (at most once per Interval): offers the open hunts in the town the
    // company is at, and tells the town screen which contracts are this mod's.
    function update()
    {
        local now = ::Time.getVirtualTimeF();

        if (this.LastTime >= 0 && now - this.LastTime < this.Interval && now >= this.LastTime)
        {
            return;
        }

        this.LastTime = now;
        this.callOffOrphans();
        this.offerAt(::ChaosMind.Quest.findNearTown());
        this.sendIcons();
    }

    // Entering a town (settlement.onEnter, hooked below), before the town screen reads its
    // contracts (14 Nov). The world check alone missed towns: it runs at most once a second while
    // within 1 tile, so walking straight in often skipped it, and inside the town the paused clock
    // holds it back (and the open town screen wouldn't show a contract added after it opened).
    function onEnterTown( _town )
    {
        this.callOffOrphans();
        this.offerAt(_town);
        this.sendIcons(true);
        ::logInfo("Chaos Mind: entered " + _town.getName() + "; hunts: " + this.describeAll() + ".");
    }

    // For the log: each hunt and why it is or isn't offered, e.g. "BlackSkull open, Aura needs 250 kills, Army part 2 needs 200 kills (blade kills 134)".
    function describeAll()
    {
        local sword = ::ChaosMind.findSword();
        local kills = sword != null ? sword.m.Kills : -1;
        local day = ::World.getTime().Days;
        local q = ::ChaosMind.Quest;
        local out = [];

        foreach (key, t in this.Types)
        {
            local why;

            if (this.isActive(key))
            {
                why = "active contract";
            }
            else if (this.isOpen(key))
            {
                why = "open";
            }
            else if (sword == null)
            {
                why = "no Chaos Mind in roster or stash";
            }
            else if (key == "BlackSkull")
            {
                local done = q.getDone();
                why = done >= q.Tiers.len() ? "all parts done"
                    : day <= q.getFlag(q.DeclinedDayFlag) ? "declined or failed, back after day " + q.getFlag(q.DeclinedDayFlag)
                    : "part " + (done + 1) + " needs " + q.Tiers[done].Kills + " kills";
            }
            else if (key == "Army")
            {
                local a = ::ChaosMind.Army;
                local done = a.getDone();
                why = done >= a.Tiers.len() ? "all parts done"
                    : day <= q.getFlag(a.DeclinedDayFlag) ? "declined or failed, back after day " + q.getFlag(a.DeclinedDayFlag)
                    : "part " + (done + 1) + " needs " + a.Tiers[done].Kills + " kills";
            }
            else if (key == "Dragon")
            {
                local a = ::ChaosMind.Dragon;
                why = !::ChaosMind.Settings.isRedDragonOn() ? "switched off in Mod Settings"
                    : a.getState() != 0 ? "already slain or hunted (state " + a.getState() + ")"
                    : day <= q.getFlag(a.DeclinedDayFlag) ? "declined, back after day " + q.getFlag(a.DeclinedDayFlag)
                    : "needs " + a.Kills + " kills";
            }
            else
            {
                local a = ::ChaosMind.Aura;
                why = a.getState() != 0 ? "already won or running (state " + a.getState() + ")"
                    : day <= q.getFlag(a.DeclinedDayFlag) ? "declined or failed, back after day " + q.getFlag(a.DeclinedDayFlag)
                    : "needs " + a.AuraKills + " kills";
            }

            out.push(key + " " + why);
        }

        local text = "";

        foreach (i, part in out)
        {
            text += (i == 0 ? "" : ", ") + part;
        }

        return text + " (blade kills " + kills + ")";
    }

    // Offers the open hunts in _town (null: only removes the ones that aren't open any more).
    function offerAt( _town )
    {
        local town = _town;

        foreach (key, t in this.Types)
        {
            local open = this.findOpen(key);

            if (!this.isOpen(key) || this.isActive(key))
            {
                if (open != null)
                {
                    ::World.Contracts.removeContract(open);
                }

                continue;
            }

            if (town == null)
            {
                continue;
            }

            if (open != null && open.m.Home != null && !open.m.Home.isNull() && open.m.Home.getID() == town.getID())
            {
                continue;
            }

            if (open != null)
            {
                ::World.Contracts.removeContract(open);
            }

            this.offer(key, town);
        }
    }

    // ---- A hunt only runs with its contract (14 Nov) ----
    // One whose contract is gone (cancelled, not rebuilt after loading, or started before the hunts
    // were contracts) is called off: its parties leave the map, nothing is done or failed, and the
    // next town offers the contract again. Before this, a cancelled contract left its hunt running,
    // which kept it from being offered, and the hourly fallback then marked Army of the Past part 1
    // done without a fight.

    function isHuntRunning( _key )
    {
        if (_key == "BlackSkull")
        {
            return ::ChaosMind.Quest.getActive() != 0;
        }

        if (_key == "Army")
        {
            return ::ChaosMind.Army.getActive() != 0;
        }

        if (_key == "Dragon")
        {
            return ::ChaosMind.Dragon.getState() == 1;
        }

        return ::ChaosMind.Aura.getState() == 1;
    }

    function getHuntParties( _key )
    {
        if (_key == "Army")
        {
            return ::ChaosMind.Army.getTargets();
        }

        local party = _key == "BlackSkull" ? ::ChaosMind.Quest.getTarget() : (_key == "Dragon" ? ::ChaosMind.Dragon.getTarget() : ::ChaosMind.Aura.getTarget());
        return party != null ? [ party ] : [];
    }

    function callOffOrphans()
    {
        foreach (key, t in this.Types)
        {
            if (this.isHuntRunning(key) && !this.isActive(key))
            {
                this.callOffHunt(key);
            }
        }
    }

    function callOffHunt( _key )
    {
        local parties = this.getHuntParties(_key);

        foreach (party in parties)
        {
            try
            {
                party.die();
            }
            catch (e)
            {
                ::logWarning("Chaos Mind: a " + _key + " party could not be taken off the map (" + e + ").");
            }
        }

        if (_key == "BlackSkull")
        {
            ::ChaosMind.Quest.clearHunt();
        }
        else if (_key == "Army")
        {
            ::ChaosMind.Army.clearHunt();
        }
        else if (_key == "Dragon")
        {
            ::ChaosMind.Dragon.clearHunt();
        }
        else
        {
            ::World.Flags.set(::ChaosMind.Aura.StateFlag, 0);
            ::World.Flags.set(::ChaosMind.Aura.TargetFlag, 0);
        }

        ::logInfo("Chaos Mind: the " + _key + " hunt had no contract (cancelled?); called off, " + parties.len() + " part" + (parties.len() == 1 ? "y" : "ies") + " removed. A town offers it again.");
    }

    function offer( _key, _town )
    {
        local faction = ::World.FactionManager.getFaction(_town.getFaction());

        if (faction == null)
        {
            return;
        }

        try
        {
            local contract = ::new(this.Types[_key].Script);
            contract.setFaction(faction.getID());
            contract.setHome(_town);
            contract.setEmployerID(faction.getRandomCharacter().getID());
            ::World.Contracts.addContract(contract);
            ::logInfo("Chaos Mind: the " + contract.getName() + " contract is offered in " + _town.getName() + ".");
        }
        catch (e)
        {
            ::logError("Chaos Mind: could not offer the " + _key + " contract in " + _town.getName() + " (" + e + ").");
        }
    }

    // This mod's contracts and their banners ([ { ID, Icon } ]), for the town's contract row.
    function sendIcons( _force = false )
    {
        if (this.IconScreen == null || !this.IconScreen.isConnected())
        {
            return;
        }

        local icons = [];
        local text = "";
        local all = clone ::World.Contracts.m.Open;

        if (this.getActive() != null)
        {
            all.push(this.getActive());
        }

        foreach (c in all)
        {
            local key = this.getKey(c);

            if (key != null)
            {
                icons.push({ ID = c.getID(), Icon = this.Types[key].Icon });
                text += c.getID() + key + "|";
            }
        }

        if (_force || text != this.LastSent)
        {
            this.LastSent = text;
            this.IconScreen.setIcons(icons);
        }
    }

    function reset()
    {
        this.LastSent = null;
        this.LastTime = -1.0;
    }

    // ---- Save safety (chaos_mind/save_safety.nut) ----

    // The accepted contract as "key|homeID|factionID|employerID|pool|completion|advance|state|tier".
    function record( _contract )
    {
        local key = this.getKey(_contract);
        local state = "Running";

        try
        {
            state = _contract.getActiveState().ID;
        }
        catch (e)
        {
        }

        local p = _contract.m.Payment;
        local tier = _contract.m.Flags.has("Tier") ? _contract.m.Flags.get("Tier") : 0;
        local employer = ("EmployerID" in _contract.m) ? _contract.m.EmployerID : 0;
        return key + "|" + _contract.m.Home.getID() + "|" + _contract.getFaction() + "|" + employer + "|"
            + p.Pool + "|" + p.Completion + "|" + p.Advance + "|" + state + "|" + tier;
    }

    // Rebuilds the accepted contract after loading. If anything fails, the hunt still runs without
    // it and ends with the old done / failed events.
    function restore()
    {
        if (!::World.Flags.has(this.ActiveFlag))
        {
            return;
        }

        local text = ::World.Flags.get(this.ActiveFlag);
        ::World.Flags.remove(this.ActiveFlag);

        if (::World.Contracts.getActiveContract() != null)
        {
            ::logWarning("Chaos Mind: another contract is active; the saved Chaos Mind contract is not rebuilt.");
            return;
        }

        try
        {
            local p = split(text, "|");
            local key = p[0];
            local home = ::World.getEntityByID(p[1].tointeger());
            local c = ::new(this.Types[key].Script);
            c.m.IsRestoring = true;
            c.setFaction(p[2].tointeger());

            if (home != null)
            {
                c.setHome(home);
            }

            local employer = p[3].tointeger();

            if (employer == 0)
            {
                employer = ::World.FactionManager.getFaction(p[2].tointeger()).getRandomCharacter().getID();
            }

            c.setEmployerID(employer);

            if (p[8].tointeger() != 0)
            {
                c.m.Flags.set("Tier", p[8].tointeger());
            }

            ::World.Contracts.addContract(c);
            c.start();
            c.m.Payment.Pool = p[4].tofloat();
            c.m.Payment.Completion = p[5].tofloat();
            c.m.Payment.Advance = p[6].tofloat();
            c.relinkTarget();
            c.setState(p[7]);
            c.setScreen("Overview");
            ::World.Contracts.setActiveContract(c);
            c.m.IsRestoring = false;
            ::logInfo("Chaos Mind: the " + c.getName() + " contract was rebuilt from the save (" + p[7] + ").");
        }
        catch (e)
        {
            ::logError("Chaos Mind: could not rebuild the saved Chaos Mind contract (" + e + "); the hunt goes on without it.");
        }
    }
};

::ChaosMind.Contracts.IconScreen = ::new("scripts/mods/chaos_mind/contract_icon_screen");
::MSU.UI.registerConnection(::ChaosMind.Contracts.IconScreen);
::Hooks.registerJS("ui/mods/chaos_mind/town_contracts.js");

::ChaosMind.addWorldCheck("Chaos Mind contracts", function()
{
    ::ChaosMind.Contracts.update();
});

// Offer on entering a town, before the original onEnter and the town screen read the contracts.
// (MSU hooks settlement.onEnter the same way.) A failure is logged and never blocks the town.
::ChaosMind.HooksMod.hook("scripts/entity/world/settlement", function(q)
{
    q.onEnter = @(__original) function()
    {
        try
        {
            ::ChaosMind.Contracts.onEnterTown(this);
        }
        catch (e)
        {
            ::logWarning("Chaos Mind: could not offer the hunts on entering " + this.getName() + " (" + e + ").");
        }

        return __original();
    }
});
