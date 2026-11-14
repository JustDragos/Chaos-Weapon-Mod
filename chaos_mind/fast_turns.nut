// Fast enemy turns (14 Nov), every battle. Asked for as "skip the not seen adversaries and just
// teleport them... maybe a 1k% speedup", then "make it 20-30x, I don't care if I see what it does".
//  - An enemy out of the player's sight when its turn starts (a silhouette in the turn bar) plays
//    that whole turn at Mod Settings -> Gameplay -> "Hidden enemy turn speed" (default 25x), with
//    the game's "Faster AI Movement" on. It stays fast even if it walks into view and attacks.
//  - Not a teleport: the navigator's walk charges AP and fatigue per tile and runs the step hooks
//    (zone of control, the Chaos Circle's slow zone), and the AI waits for it to end.
//  - Enemies in sight play at "Normal enemy turn speed" (default 1x; Army of the Past skeletons at
//    the hidden speed); the brothers' turns and allies at normal speed. The player's own "Faster AI Movement" choice is put back on
//    normal turns and when the battle ends.
//  - Speed call from Legends' tactical_state (its battle-speed buttons): ::Time.setVirtualSpeed.
//  - Hooks on skill_container (onTurnStart, onResumeTurn, onCombatFinished): every unit has one, so
//    reinforcements and summoned units are covered too; no actor hooks (see 4.6 in the spec).
::ChaosMind.FastTurns <- {
    InBattle = false,
    UserFasterAI = null,
    HiddenTurns = 0,
    SpeedWarningShown = false,
    HiddenWarningShown = false,

    // Out of the player's sight: isHiddenToPlayer() if the game has it, else the unit's tile.
    function isHidden( _actor )
    {
        try
        {
            if ("isHiddenToPlayer" in _actor)
            {
                return _actor.isHiddenToPlayer();
            }

            if (_actor.isPlacedOnMap())
            {
                return !_actor.getTile().IsVisibleForPlayer;
            }
        }
        catch (e)
        {
            if (!this.HiddenWarningShown)
            {
                this.HiddenWarningShown = true;
                ::logWarning("Chaos Mind: could not tell whether an enemy is out of sight (" + e + "); hidden enemies play at normal speed.");
            }
        }

        return false;
    }

    function getSpeed( _actor )
    {
        if (_actor == null || _actor.isPlayerControlled())
        {
            return 1.0;
        }

        local hidden = ::ChaosMind.Settings.getHiddenEnemySpeed();

        if (hidden > 1.0 && this.isHidden(_actor))
        {
            this.HiddenTurns += 1;
            return hidden;
        }

        // Army of the Past skeletons (14 Nov, "make it x25 even if I see the enemy"): the hidden
        // speed in sight too.
        if (::ChaosMind.Army.isSkeleton(_actor))
        {
            return hidden;
        }

        // Enemies in sight (14 Nov): Mod Settings -> Gameplay -> "Normal enemy turn speed". Allies the
        // AI moves (caravan guards, militia) stay at normal speed.
        try
        {
            if (("isAlliedWithPlayer" in _actor) && _actor.isAlliedWithPlayer())
            {
                return 1.0;
            }
        }
        catch (e)
        {
        }

        return ::ChaosMind.Settings.getNormalEnemySpeed();
    }

    function setSpeed( _speed )
    {
        try
        {
            ::Time.setVirtualSpeed(_speed);
        }
        catch (e)
        {
            if (!this.SpeedWarningShown)
            {
                this.SpeedWarningShown = true;
                ::logWarning("Chaos Mind: enemy turns could not be sped up (" + e + ").");
            }
        }

        try
        {
            local settings = ::Settings.getTempGameplaySettings();

            if (this.UserFasterAI == null)
            {
                this.UserFasterAI = settings.FasterAIMovement;
            }

            settings.FasterAIMovement = _speed > 1.0 ? true : this.UserFasterAI;
        }
        catch (e)
        {
        }
    }

    function onTurnStart( _actor )
    {
        this.setSpeed(this.getSpeed(_actor));
    }

    // The battle's units are placed: normal speed, the player's Faster AI Movement noted.
    function onBattleStart()
    {
        this.InBattle = true;
        this.UserFasterAI = null;
        this.HiddenTurns = 0;
        this.setSpeed(1.0);
    }

    // Called once per unit at the end of a battle; only the first call does anything.
    function onBattleEnd()
    {
        if (!this.InBattle)
        {
            return;
        }

        this.setSpeed(1.0);
        ::logInfo("Chaos Mind: " + this.HiddenTurns + " enemy turn(s) out of sight played at " + ::ChaosMind.Settings.getHiddenEnemySpeed() + "x this battle.");
        this.InBattle = false;
        this.UserFasterAI = null;
        this.HiddenTurns = 0;
    }
};

::ChaosMind.HooksMod.hook("scripts/skills/skill_container", function(q)
{
    foreach (name in [ "onTurnStart", "onResumeTurn" ])
    {
        if (!q.contains(name, true))
        {
            if (name == "onTurnStart")
            {
                ::logWarning("Chaos Mind: skill_container has no onTurnStart; enemy turns are never sped up.");
            }

            continue;
        }

        q[name] = @(__original) function( ... )
        {
            try
            {
                ::ChaosMind.FastTurns.onTurnStart(this.getActor());
            }
            catch (e)
            {
            }

            local args = [ this ];
            args.extend(vargv);
            return __original.acall(args);
        }
    }

    if (q.contains("onCombatFinished", true))
    {
        q.onCombatFinished = @(__original) function( ... )
        {
            try
            {
                ::ChaosMind.FastTurns.onBattleEnd();
            }
            catch (e)
            {
            }

            local args = [ this ];
            args.extend(vargv);
            return __original.acall(args);
        }
    }
});

::ChaosMind.HooksMod.hook("scripts/entity/tactical/tactical_entity_manager", function(q)
{
    if (!q.contains("spawn", true))
    {
        return;
    }

    q.spawn = @(__original) function( _properties )
    {
        try
        {
            ::ChaosMind.FastTurns.onBattleStart();
        }
        catch (e)
        {
        }

        return __original(_properties);
    }
});
