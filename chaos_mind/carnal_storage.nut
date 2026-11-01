// Carnal Storage: Chaos Mind's wielder sacrifices fatigue, hitpoints or a minor injury
// for energy, and spends energy to raise his damage until the end of the battle.
::ChaosMind.CarnalStorage <- {
    FatiguePerEnergy = 12,
    HitpointsPerEnergy = 4,
    InjuryEnergy = 20,
    UnleashCost = 20,
    DamagePerStack = 0.25,
    MaxStacks = 3,

    // Once fully unleashed, every OverflowCost stored energy turns into OverflowDamage more damage.
    OverflowCost = 150,
    OverflowDamage = 0.01,

    // Light, temporary injuries the Flesh sacrifice picks from.
    MinorInjuries = [
        "bruised_leg_injury",
        "cut_arm_injury",
        "split_nose_injury",
        "pierced_cheek_injury",
        "ripped_ear_injury",
        "crushed_finger_injury",
        "split_hand_injury",
        "pierced_hand_injury",
        "sprained_ankle_injury",
        "grazed_neck_injury"
    ],
    InjuryIDs = null,

    // Sacrificed brothers must really die (see strikeBrother).
    SacrificedFlag = "ChaosMind.Sacrificed",
    SurvivorMoodPenalty = 4.0,
    IsSacrificing = false,
    Fatality = null,
    LastSurvivorHour = -1,

    Screen = null,
    Actor = null,

    // Effects created while the skill container was busy (e.g. a kill inside a hit): the game
    // only adds them once it's done, so until then they're handed out from here, by actor ID.
    // Looking it up again right after add() returned null there, and the error left the
    // container stuck mid-update: nothing more could be added to the wielder (1 Nov).
    PendingEffects = {},

    function getEffect( _actor, _create )
    {
        local skills = _actor.getSkills();
        local id = _actor.getID();
        local effect = skills.getSkillByID("effects.carnal_storage");

        if (effect != null)
        {
            if (id in this.PendingEffects)
            {
                delete this.PendingEffects[id];
            }

            return effect;
        }

        if (id in this.PendingEffects && !this.PendingEffects[id].isGarbage())
        {
            return this.PendingEffects[id];
        }

        if (_create != true)
        {
            return null;
        }

        effect = ::new("scripts/skills/effects/carnal_storage_effect");
        skills.add(effect);

        if (skills.getSkillByID("effects.carnal_storage") == null)
        {
            this.PendingEffects[id] <- effect;
        }

        return effect;
    }

    // A minor injury script the actor doesn't already have, or null.
    function pickInjury( _actor )
    {
        if (this.InjuryIDs == null)
        {
            this.InjuryIDs = {};

            foreach (name in this.MinorInjuries)
            {
                this.InjuryIDs[name] <- ::new("scripts/skills/injury/" + name).getID();
            }
        }

        local free = [];

        foreach (name in this.MinorInjuries)
        {
            if (!_actor.getSkills().hasSkill(this.InjuryIDs[name]))
            {
                free.push(name);
            }
        }

        return free.len() == 0 ? null : free[::Math.rand(0, free.len() - 1)];
    }

    function getMaxEnergy( _actor, _mode )
    {
        if (_mode == "Fatigue")
        {
            local fatigueRoom = ::Math.max(0, _actor.getFatigueMax() - _actor.getFatigue());
            return ::Math.floor(fatigueRoom / this.FatiguePerEnergy);
        }

        if (_mode == "Blood")
        {
            // Always leave at least 1 hitpoint.
            local hitpointRoom = ::Math.max(0, _actor.getHitpoints() - 1);
            return ::Math.floor(hitpointRoom / this.HitpointsPerEnergy);
        }

        if (_mode == "Flesh")
        {
            return this.pickInjury(_actor) == null ? 0 : this.InjuryEnergy;
        }

        return 0;
    }

    function getUIData( _actor )
    {
        local effect = this.getEffect(_actor, false);

        return {
            Name = _actor.getName(),
            Energy = effect == null ? 0 : effect.m.Energy,
            Stacks = effect == null ? 0 : effect.m.Stacks,
            MaxStacks = this.MaxStacks,
            UnleashCost = this.UnleashCost,
            DamagePerStack = (this.DamagePerStack * 100).tointeger(),
            Overflow = effect == null ? 0 : effect.m.Overflow,
            OverflowCost = this.OverflowCost,
            OverflowDamage = (this.OverflowDamage * 100).tointeger(),
            Fatigue = {
                MaxEnergy = this.getMaxEnergy(_actor, "Fatigue"),
                PerEnergy = this.FatiguePerEnergy,
                Current = _actor.getFatigue().tointeger(),
                Max = _actor.getFatigueMax().tointeger(),
                Fixed = false
            },
            Blood = {
                MaxEnergy = this.getMaxEnergy(_actor, "Blood"),
                PerEnergy = this.HitpointsPerEnergy,
                Current = _actor.getHitpoints().tointeger(),
                Max = _actor.getHitpointsMax().tointeger(),
                Fixed = false
            },
            Flesh = {
                MaxEnergy = this.getMaxEnergy(_actor, "Flesh"),
                PerEnergy = 0,
                Fixed = true
            }
        };
    }

    function isActorValid()
    {
        return this.Actor != null && this.Actor.isAlive() && !this.Actor.isDying() && this.Actor.isPlacedOnMap();
    }

    function open( _actor )
    {
        if (this.Screen == null)
        {
            ::logError("Chaos Mind: Carnal Storage window was never created.");
            return;
        }

        this.Actor = _actor;
        this.Screen.show(this.getUIData(_actor));
    }

    function close()
    {
        this.Actor = null;

        if (this.Screen != null)
        {
            this.Screen.hide();
        }
    }

    function refresh()
    {
        this.Actor.getSkills().update();
        this.Actor.setDirty(true);
        this.Screen.update(this.getUIData(this.Actor));
    }

    function log( _text )
    {
        this.logFor(this.Actor, _text);
    }

    function logFor( _actor, _text )
    {
        ::logInfo("Chaos Mind: Carnal Storage: " + _actor.getName() + " " + _text);

        try
        {
            ::Tactical.EventLog.log(::Const.UI.getColorizedEntityName(_actor) + " " + _text);
        }
        catch (e)
        {
        }
    }

    // After 3 unleashes, every OverflowCost energy is spent on +1% damage (repeats if enough).
    function checkOverflow( _actor )
    {
        local effect = this.getEffect(_actor, false);

        if (effect == null)
        {
            return;
        }

        while (effect.m.Stacks >= this.MaxStacks && effect.m.Energy >= this.OverflowCost)
        {
            effect.m.Energy -= this.OverflowCost;
            effect.m.Overflow += 1;
            this.logFor(_actor, "overflows the eye: +" + (effect.m.Overflow * this.OverflowDamage * 100).tointeger() + "% extra damage until the battle ends");
        }
    }

    // Damage of a full Chaos Mind strike: weapon roll, melee skill and kill bonuses, and the
    // wielder's own damage multipliers (Unleash stacks, overflow, perks).
    function getStrikeRange( _actor )
    {
        local weapon = _actor.getMainhandItem();

        if (weapon == null || weapon.getID() != ::ChaosMind.SwordID)
        {
            return [0, 0];
        }

        local props = _actor.getCurrentProperties();
        local mult = props.DamageTotalMult * weapon.getMeleeSkillMult(_actor, props.getMeleeSkill()) * (1.0 + weapon.getKillBonus() / 100.0);
        return [::Math.floor(weapon.m.RegularDamage * mult), ::Math.floor(weapon.m.RegularDamageMax * mult)];
    }

    // Brothers standing in the cells around _actor.
    function getAdjacentBrothers( _actor )
    {
        local result = [];

        if (!_actor.isPlacedOnMap())
        {
            return result;
        }

        local tile = _actor.getTile();

        for (local dir = 0; dir < 6; ++dir)
        {
            if (!tile.hasNextTile(dir))
            {
                continue;
            }

            local next = tile.getNextTile(dir);

            if (!next.IsOccupiedByActor)
            {
                continue;
            }

            local other = next.getEntity();

            // Brothers with Chaos Protection can't be sacrificed.
            if (other != null && other.getID() != _actor.getID() && other.isAlliedWith(_actor) && other.isAlive() && !other.isDying()
                && !::ChaosMind.isProtected(other))
            {
                result.push(other);
            }
        }

        return result;
    }

    // One full strike on a brother: always hits, ignores armor, always kills, and he really dies.
    //  - The blow itself leaves him at 1 HP at least, so Nine Lives and damage reduction never
    //    come into it; he is then killed with a fatality (disemboweled), which the game never
    //    lets a brother survive with a permanent injury.
    //  - While this runs, IsSacrificing makes player.isReallyKilled answer "dead" as well.
    //  - He is flagged first: if he still turns up alive on the world map, checkSurvivors()
    //    gives him a huge mood penalty instead.
    // Returns the hitpoints he lost (all of them if he died).
    function strikeBrother( _user, _target, _skill )
    {
        local range = this.getStrikeRange(_user);

        if (range[1] <= 0)
        {
            return 0;
        }

        local hitpointsBefore = _target.getHitpoints();

        try
        {
            _target.getFlags().set(this.SacrificedFlag, true);
        }
        catch (e)
        {
        }

        this.IsSacrificing = true;

        try
        {
            local damage = ::Math.min(::Math.rand(range[0], range[1]), hitpointsBefore - 1);

            if (damage > 0)
            {
                local hitInfo = clone ::Const.Tactical.HitInfo;
                hitInfo.DamageRegular = damage;
                hitInfo.DamageArmor = 0;
                hitInfo.DamageDirect = 1.0;
                hitInfo.BodyPart = ::Const.BodyPart.Body;
                hitInfo.BodyDamageMult = 1.0;
                hitInfo.FatalityChanceMult = 0.0;
                _target.onDamageReceived(_user, _skill, hitInfo);
            }

            if (_target.isAlive() && !_target.isDying())
            {
                _target.kill(_user, _skill, this.getFatality());
            }
        }
        catch (e)
        {
            this.IsSacrificing = false;
            throw e;
        }

        this.IsSacrificing = false;

        local died = !_target.isAlive() || _target.isDying();
        return died ? hitpointsBefore : ::Math.max(0, hitpointsBefore - _target.getHitpoints());
    }

    // A fatality the game can't turn into "survived with a permanent injury". The names aren't
    // documented, so take the first that exists.
    function getFatality()
    {
        if (this.Fatality == null)
        {
            this.Fatality = ::Const.FatalityType.None;

            foreach (name in ["Disemboweled", "Smashed", "Suicide"])
            {
                if (name in ::Const.FatalityType)
                {
                    this.Fatality = ::Const.FatalityType[name];
                    ::logInfo("Chaos Mind: sacrificed brothers die by FatalityType." + name + ".");
                    break;
                }
            }

            if (this.Fatality == ::Const.FatalityType.None)
            {
                ::logWarning("Chaos Mind: no fatality type found for sacrifices; relying on the isReallyKilled hook.");
            }
        }

        return this.Fatality;
    }

    // On the world map, once per in-game hour: a brother still carrying the sacrifice flag lived
    // through it somehow, and hates the company for it.
    function checkSurvivors()
    {
        local hours = ::World.getTime().Hours;

        if (hours == this.LastSurvivorHour)
        {
            return;
        }

        this.LastSurvivorHour = hours;

        foreach (bro in ::World.getPlayerRoster().getAll())
        {
            if (!bro.getFlags().has(this.SacrificedFlag))
            {
                continue;
            }

            bro.getFlags().remove(this.SacrificedFlag);
            ::logWarning("Chaos Mind: " + bro.getName() + " survived being sacrificed; his mood drops by " + this.SurvivorMoodPenalty + ".");

            try
            {
                bro.worsenMood(this.SurvivorMoodPenalty, "Was sacrificed to Chaos Mind and lived");
            }
            catch (e)
            {
                ::logWarning("Chaos Mind: could not change " + bro.getName() + "'s mood (" + e + ").");
            }
        }
    }

    // Energy from outside the window (Brother / Mass Sacrifice). _what describes the offering.
    function addEnergy( _actor, _energy, _what )
    {
        if (_energy > 0)
        {
            this.getEffect(_actor, true).m.Energy += _energy;
        }

        this.logFor(_actor, _what + " for " + _energy + " energy");
        this.checkOverflow(_actor);
        _actor.getSkills().update();
        _actor.setDirty(true);

        if (this.Actor != null && this.Actor.getID() == _actor.getID() && this.Screen != null)
        {
            this.Screen.update(this.getUIData(_actor));
        }
    }

    function sacrifice( _mode, _amount )
    {
        if (!this.isActorValid())
        {
            this.close();
            return;
        }

        local actor = this.Actor;
        local max = this.getMaxEnergy(actor, _mode);

        if (max <= 0)
        {
            this.refresh();
            return;
        }

        local gained = 0;

        if (_mode == "Fatigue")
        {
            gained = ::Math.max(1, ::Math.min(max, _amount.tointeger()));
            actor.setFatigue(actor.getFatigue() + gained * this.FatiguePerEnergy);
            this.log("feeds the eye " + (gained * this.FatiguePerEnergy) + " fatigue for " + gained + " energy");
        }
        else if (_mode == "Blood")
        {
            gained = ::Math.max(1, ::Math.min(max, _amount.tointeger()));
            actor.setHitpoints(actor.getHitpoints() - gained * this.HitpointsPerEnergy);
            this.log("feeds the eye " + (gained * this.HitpointsPerEnergy) + " hitpoints for " + gained + " energy");
        }
        else if (_mode == "Flesh")
        {
            local script = this.pickInjury(actor);

            if (script == null)
            {
                this.refresh();
                return;
            }

            local injury = ::new("scripts/skills/injury/" + script);
            actor.getSkills().add(injury);
            gained = this.InjuryEnergy;
            this.log("tears their own flesh (" + injury.getName() + ") for " + gained + " energy");
        }
        else
        {
            ::logError("Chaos Mind: Unknown Carnal Storage sacrifice " + _mode);
            return;
        }

        this.getEffect(actor, true).m.Energy += gained;
        this.checkOverflow(actor);
        this.refresh();
    }

    function unleash()
    {
        if (!this.isActorValid())
        {
            this.close();
            return;
        }

        local effect = this.getEffect(this.Actor, false);

        if (effect == null || effect.m.Energy < this.UnleashCost || effect.m.Stacks >= this.MaxStacks)
        {
            this.refresh();
            return;
        }

        effect.m.Energy -= this.UnleashCost;
        effect.m.Stacks += 1;
        this.log("unleashes the eye: +" + (effect.m.Stacks * this.DamagePerStack * 100).tointeger() + "% damage until the battle ends");
        this.checkOverflow(this.Actor);
        this.refresh();
    }
};


// The window itself: Squirrel connection + JS/CSS for the interface.
::ChaosMind.CarnalStorage.Screen = ::new("scripts/mods/chaos_mind/carnal_storage_screen");
::MSU.UI.registerConnection(::ChaosMind.CarnalStorage.Screen);
::Hooks.registerJS("ui/mods/chaos_mind/carnal_storage.js");
::Hooks.registerCSS("ui/mods/chaos_mind/carnal_storage.css");


// During a sacrifice the game's "survived with a permanent injury" roll always says dead.
// Only hooked if the function is there (its name couldn't be confirmed in the encrypted scripts).
::ChaosMind.HooksMod.hook("scripts/entity/tactical/player", function(q)
{
    if (!q.contains("isReallyKilled", true))
    {
        ::logWarning("Chaos Mind: player has no isReallyKilled; sacrifices rely on the fatality type alone.");
        return;
    }

    q.isReallyKilled = @(__original) function( ... )
    {
        if (::ChaosMind.CarnalStorage.IsSacrificing)
        {
            return true;
        }

        local args = [ this ];
        args.extend(vargv);
        return __original.acall(args);
    }
});
