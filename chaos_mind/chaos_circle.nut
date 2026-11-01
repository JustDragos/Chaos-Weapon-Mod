// Chaos Circle (tier 7 perk, perk.chaos_circle). Grants actives.chaos_circle, usable only while
// wielding Chaos Mind: up to 5 tiles away, it opens a circle of 7 tiles (a tile and its 6
// neighbours) for 3 rounds.
//  - Everyone inside, friend or foe, is hit by a Geist's Horrific Scream when it opens. For that
//    check his Resolve is shifted by the gap between the caster's Resolve and his own: the full gap
//    on the centre tile (CenterMult), half of it on the ring (RingMult). Below the caster's Resolve
//    he resists worse; at or above it, the same as against a Geist (effects.chaos_circle_ward).
//    Changed 1 Nov from a flat +15; braver targets got the gap as a bonus at first, which could
//    make the circle weaker than before, so the shift never helps them.
//  - While it lasts, anyone standing in it pays +1 AP and +3 fatigue per tile he moves
//    (effects.chaos_circle). Who's inside is checked on casting, after every move, and each round.
//  - The caster and Chaos Protection holders are untouched. Only Chaos Matters and Iron Mind
//    still shake off the scream through their own hooks, but are slowed.
::ChaosMind.ChaosCircle <- {
    PerkID = "perk.chaos_circle",
    SkillID = "actives.chaos_circle",
    EffectID = "effects.chaos_circle",
    Rounds = 3,
    MoveAPCost = 1,
    MoveFatigueCost = 3,
    // Share of the Resolve gap (caster minus target) taken off the target's Resolve for the scream
    // (effects.chaos_circle_ward): in full at the centre, halved on the ring.
    CenterMult = 1.0,
    RingMult = 0.5,
    WardID = "effects.chaos_circle_ward",

    // One circle per caster, by caster ID: { Tile, CasterID, Round }.
    Circles = {},
    Scream = null,
    ScreamWarningShown = false,
    // Whether the movement cost properties exist (null until first checked; see chaos_circle_effect).
    HasMovementProperties = null,

    function reset()
    {
        this.Circles = {};
    }

    function isActive( _circle )
    {
        return ::Time.getRound() < _circle.Round + this.Rounds;
    }

    // The active circle covering _tile, or null.
    function getCircleAt( _tile )
    {
        foreach (circle in this.Circles)
        {
            if (this.isActive(circle) && circle.Tile.getDistanceTo(_tile) <= 1)
            {
                return circle;
            }
        }

        return null;
    }

    function getTiles( _center )
    {
        local tiles = [ _center ];

        for (local dir = 0; dir < 6; ++dir)
        {
            if (_center.hasNextTile(dir))
            {
                tiles.push(_center.getNextTile(dir));
            }
        }

        return tiles;
    }

    function isExempt( _actor, _circle )
    {
        return _actor.getID() == _circle.CasterID || ::ChaosMind.isProtected(_actor);
    }

    // Gives or takes the slow effect depending on where _actor stands now.
    function updateActor( _actor )
    {
        if (_actor == null || !_actor.isAlive() || _actor.isDying() || !_actor.isPlacedOnMap())
        {
            return;
        }

        local circle = this.getCircleAt(_actor.getTile());
        local inside = circle != null && !this.isExempt(_actor, circle);
        local skills = _actor.getSkills();

        if (inside && !skills.hasSkill(this.EffectID))
        {
            skills.add(::new("scripts/skills/effects/chaos_circle_effect"));
        }
        else if (!inside && skills.hasSkill(this.EffectID))
        {
            skills.removeByID(this.EffectID);
        }
    }

    function updateAll()
    {
        foreach (faction in ::Tactical.Entities.getAllInstances())
        {
            foreach (actor in faction)
            {
                this.updateActor(actor);
            }
        }
    }

    // Drops circles that have run out; the rest flare up again so they stay visible.
    function onNewRound( _caster )
    {
        local id = _caster.getID();

        if (id in this.Circles)
        {
            if (this.isActive(this.Circles[id]))
            {
                this.spawnParticles(this.Circles[id].Tile);
            }
            else
            {
                delete this.Circles[id];
            }
        }

        this.updateAll();
    }

    function cast( _user, _center )
    {
        local circle = { Tile = _center, CasterID = _user.getID(), Round = ::Time.getRound() };
        this.Circles[_user.getID()] <- circle;
        this.spawnParticles(_center);

        local hit = 0;
        local horrified = 0;

        foreach (tile in this.getTiles(_center))
        {
            if (!tile.IsOccupiedByActor)
            {
                continue;
            }

            local target = tile.getEntity();

            if (target == null || !target.isAlive() || target.isDying() || this.isExempt(target, circle))
            {
                continue;
            }

            hit += 1;
            this.scream(_user, target, tile.getDistanceTo(_center) == 0);

            if (target.isAlive() && target.getSkills().hasSkill("effects.horrified"))
            {
                horrified += 1;
            }
        }

        this.updateAll();

        local text = "opens a Chaos Circle: " + hit + (hit == 1 ? " soul" : " souls") + " caught, " + horrified + " horrified";
        ::logInfo("Chaos Mind: " + _user.getName() + " " + text);

        try
        {
            ::Tactical.EventLog.log(::Const.UI.getColorizedEntityName(_user) + " " + text);
        }
        catch (e)
        {
        }
    }

    // Resolve shift for _target's check against the scream: minus the gap between the caster's
    // Resolve and his, times CenterMult or RingMult. Never positive: a braver target gets no bonus.
    function getResolveShift( _user, _target, _atCenter )
    {
        local gap = _user.getCurrentProperties().getBravery() - _target.getCurrentProperties().getBravery();
        return -::Math.floor((gap > 0 ? gap : 0) * (_atCenter ? this.CenterMult : this.RingMult) + 0.5);
    }

    // The scream: _target holds a hidden ward (getResolveShift) only while the check is made.
    function scream( _user, _target, _atCenter )
    {
        local shift = this.getResolveShift(_user, _target, _atCenter);
        ::logInfo("Chaos Mind: Chaos Circle screams at " + _target.getName() + (_atCenter ? " (centre)" : " (ring)")
            + ", Resolve " + _target.getCurrentProperties().getBravery() + " vs the caster's " + _user.getCurrentProperties().getBravery()
            + ": " + (shift >= 0 ? "+" : "") + shift + " for the check.");

        if (shift == 0)
        {
            this.screamAt(_user, _target);
            return;
        }

        // Removed through its own reference, not looked up again (the rule from 4.3 in spec.md):
        // a ward whose adding was put off must not stay on him after the scream.
        local ward = ::new("scripts/skills/effects/chaos_circle_ward_effect");
        ward.m.Shift = shift;
        local skills = _target.getSkills();
        skills.add(ward);
        skills.update();

        this.screamAt(_user, _target);

        ward.removeSelf();
        skills.update();
    }

    // The Geist's own Horrific Scream, used on _target as if _user had screamed at him.
    // If the vanilla skill can't be borrowed, fall back to a resolve roll and its Horrified effect.
    function screamAt( _user, _target )
    {
        try
        {
            if (this.Scream == null)
            {
                this.Scream = ::new("scripts/skills/actives/horrific_scream");
            }

            this.Scream.setContainer(_user.getSkills());
            this.Scream.onUse(_user, _target.getTile());
            return;
        }
        catch (e)
        {
            if (!this.ScreamWarningShown)
            {
                this.ScreamWarningShown = true;
                ::logWarning("Chaos Mind: Chaos Circle could not use the Geist's scream (" + e + "); using a resolve check instead.");
            }
        }

        try
        {
            if (::Math.rand(1, 100) > _target.getCurrentProperties().getBravery())
            {
                _target.getSkills().add(::new("scripts/skills/effects/horrified_effect"));
            }
        }
        catch (e)
        {
            ::logWarning("Chaos Mind: Chaos Circle could not horrify " + _target.getName() + " (" + e + ").");
        }
    }

    function spawnParticles( _center )
    {
        local particles = ::ChaosMind.getCloudParticles();

        if (particles == null)
        {
            return;
        }

        try
        {
            foreach (tile in this.getTiles(_center))
            {
                foreach (p in particles)
                {
                    ::Tactical.spawnParticleEffect(false, p.Brushes, tile, p.Delay, p.Quantity, p.LifeTimeQuantity, p.SpawnRate, p.Stages, ::createVec(0, 0));
                }
            }
        }
        catch (e)
        {
            ::logWarning("Chaos Mind: Chaos Circle could not be drawn (" + e + ").");
        }
    }
};


// Perk tree: tier 7 (row index 6).
::Const.Strings.PerkName.ChaosCircle <- "Chaos Circle";
::Const.Strings.PerkDescription.ChaosCircle <- "Unlocks the 'Chaos Circle' skill while wielding Chaos Mind: up to [color=" + ::Const.UI.Color.PositiveValue
    + "]5[/color] tiles away, tear open a circle of 7 tiles for 3 rounds. Everyone caught in it, friend or foe, hears the Horrific Scream of a Geist. "
    + "The lower his Resolve is than yours, the worse he resists it: the one in the centre feels the full gap, those around him half of it. "
    + "While it lasts, anyone standing in it pays [color=" + ::Const.UI.Color.NegativeValue + "]+1[/color] AP and [color=" + ::Const.UI.Color.NegativeValue
    + "]+3[/color] fatigue for every tile he moves. Can be used once every 3 turns.";

local chaosCirclePerk = {
    ID = "perk.chaos_circle",
    Script = "scripts/skills/perks/perk_chaos_circle",
    Name = ::Const.Strings.PerkName.ChaosCircle,
    Tooltip = ::Const.Strings.PerkDescription.ChaosCircle,
    Icon = "skills/chaos_mind/chaos_circle_perk.png",
    IconDisabled = "skills/chaos_mind/chaos_circle_perk_sw.png",
    Row = 6,
    Unlocks = 6
};
::Const.Perks.Perks[6].push(chaosCirclePerk);
::Const.Perks.LookupMap[chaosCirclePerk.ID] <- chaosCirclePerk;


// Anyone who walks into or out of a circle gains or loses the slow at once. A plain hook on
// actor (not hookTree), the same way MSU hooks this function.
::ChaosMind.HooksMod.hook("scripts/entity/tactical/actor", function(q)
{
    q.onMovementFinish = @(__original) function( _tile )
    {
        __original(_tile);

        if (::ChaosMind.ChaosCircle.Circles.len() != 0)
        {
            ::ChaosMind.ChaosCircle.updateActor(this);
        }
    }
});
