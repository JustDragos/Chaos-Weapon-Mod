// Only Chaos Matters (tier 3 perk, perk.only_chaos_matters):
//  - immune to a Hexe's Charm and a Geist's Horrific Scream,
//  - never loses morale when an ally dies (IsAffectedByDyingAllies off, in the perk's onUpdate),
//  - isolated: Rally the Troops and Inspiring Presence can't raise his morale.
//
// No hooks on actor itself: Modern Hooks' tree hooks on actor fail to compile ("expression
// expected") for functions like checkMorale, so morale is restored around the specific skills.
::ChaosMind.OnlyChaos <- {
    PerkID = "perk.only_chaos_matters",

    function has( _actor )
    {
        return _actor != null && _actor.getSkills().hasSkill(this.PerkID);
    }

    // Morale of everyone who must not be lifted by someone else's skill: Only Chaos Matters
    // holders (isolated) and brothers terrified by a sacrifice (must keep fleeing).
    function snapshotMorale()
    {
        local snapshot = [];

        foreach (faction in ::Tactical.Entities.getAllInstances())
        {
            foreach (actor in faction)
            {
                if (actor.isAlive() && (this.has(actor) || this.isTerrified(actor)))
                {
                    snapshot.push({ Actor = actor, State = actor.getMoraleState() });
                }
            }
        }

        return snapshot;
    }

    // Undo any morale raise the snapshot's actors got; _except is the skill's user.
    function restoreMorale( _snapshot, _except )
    {
        foreach (entry in _snapshot)
        {
            local actor = entry.Actor;

            if (!actor.isAlive() || actor.isDying() || (_except != null && actor.getID() == _except.getID()))
            {
                continue;
            }

            local target = this.isTerrified(actor) ? ::Const.MoraleState.Fleeing : entry.State;

            if (actor.getMoraleState() > target)
            {
                actor.setMoraleState(target);
            }
        }
    }

    // The other brothers hate him: their mood drops (shown in their mood tooltip with the reason).
    SacrificeHatred = 1.5,
    BattleHatred = 0.5,
    DailyHatred = 0.25,
    MoodWarningShown = false,

    function spreadHatred( _hated, _amount, _reason )
    {
        if (_hated == null || !this.has(_hated))
        {
            return;
        }

        foreach (bro in ::World.getPlayerRoster().getAll())
        {
            if (bro.getID() == _hated.getID() || !bro.isAlive())
            {
                continue;
            }

            try
            {
                bro.worsenMood(_amount, _reason);
            }
            catch (e)
            {
                if (!this.MoodWarningShown)
                {
                    this.MoodWarningShown = true;
                    ::logWarning("Chaos Mind: could not change brothers' mood (" + e + ").");
                }
            }
        }
    }

    function onSacrifice( _user )
    {
        // In its gorged form (500 kills) the blade rewards the wielder: sacrificing makes him
        // Confident, overriding the morale he lost watching the brother die.
        local weapon = _user.getMainhandItem();

        if (weapon != null && weapon.getID() == ::ChaosMind.SwordID && weapon.isAscended() && _user.isAlive() && !_user.isDying())
        {
            _user.setMoraleState(::Const.MoraleState.Confident);
        }

        this.terrifyAllies(_user);
        this.spreadHatred(_user, this.SacrificeHatred, "Watched " + _user.getName() + " butcher a brother for the blade");
    }

    // Every brother on the field who saw the sacrifice flees for the rest of the battle,
    // except the one who did it and anyone with Only Chaos Matters.
    TerrorEffectID = "effects.sacrifice_terror",

    function isTerrified( _actor )
    {
        return _actor.getSkills().hasSkill(this.TerrorEffectID);
    }

    function terrifyAllies( _user )
    {
        local count = 0;

        foreach (ally in ::Tactical.Entities.getInstancesOfFaction(_user.getFaction()))
        {
            if (ally.getID() == _user.getID() || !ally.isAlive() || ally.isDying() || !ally.isPlacedOnMap())
            {
                continue;
            }

            // Only Chaos Matters and Chaos Protection both keep a brother from breaking.
            if (this.has(ally) || ::ChaosMind.isProtected(ally) || this.isTerrified(ally))
            {
                continue;
            }

            ally.getSkills().add(::new("scripts/skills/effects/sacrifice_terror_effect"));
            count += 1;
        }

        if (count > 0)
        {
            ::logInfo("Chaos Mind: " + count + " brother(s) broke and fled after " + _user.getName() + "'s sacrifice.");
        }
    }

    function onBattleFinished( _actor )
    {
        this.spreadHatred(_actor, this.BattleHatred, "Saw what " + _actor.getName() + " became in battle");
    }

    function onNewDay( _actor )
    {
        this.spreadHatred(_actor, this.DailyHatred, "Can't stand being near " + _actor.getName());
    }
};


// Perk tree: tier 3 (row index 2), next to Iron Mind.
::Const.Strings.PerkName.OnlyChaosMatters <- "Only Chaos Matters";
::Const.Strings.PerkDescription.OnlyChaosMatters <- "Nothing reaches him but the eye. Immunity against being charmed by Hexen and against the Horrific Scream of Geists. "
    + "Never loses morale when an ally dies. Cut off from his brothers: other units can't raise his morale, not even with Rally the Troops.";

local onlyChaosPerk = {
    ID = "perk.only_chaos_matters",
    Script = "scripts/skills/perks/perk_only_chaos_matters",
    Name = ::Const.Strings.PerkName.OnlyChaosMatters,
    Tooltip = ::Const.Strings.PerkDescription.OnlyChaosMatters,
    Icon = "skills/chaos_mind/only_chaos_matters.png",
    IconDisabled = "skills/chaos_mind/only_chaos_matters_sw.png",
    Row = 2,
    Unlocks = 2
};
::Const.Perks.Perks[2].push(onlyChaosPerk);
::Const.Perks.LookupMap[onlyChaosPerk.ID] <- onlyChaosPerk;


local mod = ::ChaosMind.HooksMod;

// Charm and scream: the enemy can't target him...
foreach (script in ["scripts/skills/actives/charm_skill", "scripts/skills/actives/horrific_scream"])
{
    mod.hook(script, function(q)
    {
        q.onVerifyTarget = @(__original) function( _originTile, _targetTile )
        {
            if (_targetTile.IsOccupiedByActor && ::ChaosMind.OnlyChaos.has(_targetTile.getEntity()))
            {
                return false;
            }

            return __original(_originTile, _targetTile);
        }
    });
}

// ...and if the effect lands anyway, it's shaken off at once.
foreach (script in ["scripts/skills/effects/charmed_effect", "scripts/skills/effects/horrified_effect"])
{
    mod.hook(script, function(q)
    {
        q.onAdded = @(__original) function()
        {
            local actor = this.getContainer().getActor();

            if (::ChaosMind.OnlyChaos.has(actor))
            {
                ::logInfo("Chaos Mind: Only Chaos Matters kept " + actor.getName() + " from getting " + this.getName() + ".");
                this.removeSelf();
                return;
            }

            __original();
        }
    });
}

// Rally the Troops can't lift Only Chaos Matters holders or brothers terrified by a sacrifice.
mod.hook("scripts/skills/actives/rally_the_troops", function(q)
{
    q.onUse = @(__original) function( _user, _targetTile )
    {
        local oc = ::ChaosMind.OnlyChaos;
        local snapshot = oc.snapshotMorale();
        local result = __original(_user, _targetTile);
        oc.restoreMorale(snapshot, _user);
        return result;
    }
});

// Inspiring Presence comes from More Perks; only hook it if that mod is installed.
local hasInspiringPresence = false;

try
{
    hasInspiringPresence = ::IO.scriptFilenameExists("scripts/skills/perks/perk_inspiring_presence");
}
catch (e)
{
    foreach (file in ::IO.enumerateFiles("scripts/skills/perks/"))
    {
        if (file == "scripts/skills/perks/perk_inspiring_presence")
        {
            hasInspiringPresence = true;
        }
    }
}

if (hasInspiringPresence)
{
    mod.hook("scripts/skills/perks/perk_inspiring_presence", function(q)
    {
        q.onCombatStarted = @(__original) function()
        {
            local oc = ::ChaosMind.OnlyChaos;
            local snapshot = oc.snapshotMorale();
            __original();
            oc.restoreMorale(snapshot, this.getContainer().getActor());
        }
    });
}
