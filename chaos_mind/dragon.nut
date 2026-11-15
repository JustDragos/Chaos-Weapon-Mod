// The Red Dragon (14 Nov): a seven-hex enemy, offered as a contract at Kills blade kills.
//  - Shape: the body in the centre (chaos_mind_red_dragon: health, AI, every attack), the head on
//    one neighbouring hex, the tail on the opposite one and two wings on each side
//    (chaos_mind_red_dragon_part: hitboxes that pass every hit on to the body). The game only has
//    one-hex combatants; this is how the Lindwurm (head + tail) and the Kraken are built.
//  - One shared health pool. When the body dies, the parts go with it.
//  - Its turn (ai_chaos_mind_dragon):
//      * in the air: lands on a spot near the company where all seven hexes are free, facing the
//        most brothers, and pushes everyone next to it back one hex;
//      * every FlyEvery-th turn, and when it first drops below 2/3 and 1/3 health: takes off. Its
//        parts leave the board and the body turns invisible and immune to damage until it lands.
//        The body stays on its hex while in the air, so the battle never runs out of enemies;
//      * every RoarEvery-th turn: a roar, a morale check for every brother in range;
//      * otherwise (and after a roar): breathes fire in a cone in front of its head.
//  - It starts every battle in the air and lands on its first turn, so its footprint is always on
//    clear ground.
//  - The dragon key (Ctrl+D since 15 Nov, Mod Settings > Keybinds to change): on the world map a Red
//    Dragon party lands next to the company and attacks it; in a battle one joins the fight.
//  - Mod Settings -> Dev / Game breaking -> Red Dragon (off by default since v1.0.1) switches the
//    contract on; the key works either way; an accepted hunt goes on.
// Names come from the readable Legends copies (legend_stollwurm, legend_firefield_skill,
// legend_teleport_skill, hidden_effect, swallow whole); vanilla's own scripts are encrypted.
::ChaosMind.Dragon <- {
    Kills = 750,
    ContractPay = 3000,
    ContractDifficultyMult = 1.6,

    Script = "scripts/entity/tactical/enemies/chaos_mind_red_dragon",
    PartScript = "scripts/entity/tactical/enemies/chaos_mind_red_dragon_part",
    Brush = "bust_chaos_mind_red_dragon",
    DeadBrush = "bust_chaos_mind_red_dragon_dead",
    Name = "Red Dragon",
    PartyName = "The Red Dragon",
    Description = "A red dragon has come down from the mountains. It is drawn to the blade that devours.",

    // Battle tuning.
    FlyEvery = 4,
    RoarEvery = 3,
    BreathRange = 3,
    BreathDamageMin = 40,
    BreathDamageMax = 70,
    BreathRounds = 2,
    RoarRange = 8,
    // Head directions the art can show (it faces right, or mirrored left): NE, SE, SW, NW.
    HeadDirections = [ 1, 2, 4, 5 ],

    // 0 not started, 1 hunting, 2 done.
    StateFlag = "ChaosMind.DragonState",
    TargetFlag = "ChaosMind.DragonTargetID",
    DeclinedDayFlag = "ChaosMind.DragonDeclinedDay",

    Town = null,
    LastTarget = null,
    LastHourChecked = -1,

    // ---- Hunt state (world map) ----

    function getState()
    {
        return ::ChaosMind.Quest.getFlag(this.StateFlag);
    }

    function getTarget()
    {
        local id = ::ChaosMind.Quest.getFlag(this.TargetFlag);

        if (id == 0)
        {
            return null;
        }

        local party = ::World.getEntityByID(id);
        return (party != null && party.isAlive()) ? party : null;
    }

    function isOpen()
    {
        // Mod Settings -> Dev / Game breaking -> Red Dragon (14 Nov).
        if (!::ChaosMind.Settings.isRedDragonOn())
        {
            return false;
        }

        if (this.getState() != 0 || ::World.getTime().Days <= ::ChaosMind.Quest.getFlag(this.DeclinedDayFlag))
        {
            return false;
        }

        local sword = ::ChaosMind.findSword();
        return sword != null && sword.m.Kills >= this.Kills;
    }

    function decline()
    {
        ::World.Flags.set(this.DeclinedDayFlag, ::World.getTime().Days);
    }

    function clearHunt()
    {
        ::World.Flags.set(this.StateFlag, 0);
        ::World.Flags.set(this.TargetFlag, 0);
    }

    // Hourly: the dragon's party shown through the fog.
    function check()
    {
        local hour = ::ChaosMind.getHour();

        if (hour == this.LastHourChecked)
        {
            return;
        }

        this.LastHourChecked = hour;

        if (this.getState() == 1)
        {
            ::ChaosMind.markTarget(this.getTarget());
        }
    }

    // Ctrl+F, after the Black Skull and The Ten (chaos_mind/quest.nut, aura.nut).
    function showDirection()
    {
        local target = this.getState() == 1 ? this.getTarget() : null;

        if (target == null)
        {
            ::ChaosMind.Notice.close();
            return false;
        }

        local text = "The Red Dragon is " + ::ChaosMind.Altar.describeLocation(target.getTile()) + ".";
        ::logInfo("Chaos Mind: " + text);
        return ::ChaosMind.Notice.toggle("The Red Dragon", [ text ]);
    }

    // Accepting the contract: the dragon's party near this.Town. Returns it, or null.
    function spawnTarget()
    {
        local q = ::ChaosMind.Quest;

        if (this.Town == null || !this.Town.isAlive())
        {
            ::logError("Chaos Mind: the Red Dragon has no town to start from.");
            return null;
        }

        local tile = q.findSpawnTile(this.Town);
        local faction = q.getFaction("Beasts");

        if (tile == null || faction == null)
        {
            ::logError("Chaos Mind: the Red Dragon could not spawn (" + (tile == null ? "no free tile near " + this.Town.getName() : "no beast faction") + ").");
            return null;
        }

        // The Lindwurm template gives the party its figure on the map; its troops are replaced.
        local template = ("Lindwurm" in ::Const.World.Spawn) ? ::Const.World.Spawn.Lindwurm : ::Const.World.Spawn.BanditRaiders;
        local party = faction.spawnEntity(tile, this.PartyName, false, template, 100);

        if (party == null)
        {
            ::logError("Chaos Mind: the Red Dragon's party could not be created.");
            return null;
        }

        ::World.Flags.set(this.StateFlag, 1);
        ::World.Flags.set(this.TargetFlag, party.getID());
        this.LastTarget = party;

        local steps = [
            [ "its dragon", function( _party )
            {
                _party.getTroops().clear();
                ::Const.World.Common.addTroop(_party, { Type = ::Const.World.Spawn.Troops.ChaosMindRedDragon }, true, 0);
            } ],
            [ "its look", function( _party )
            {
                _party.setDescription(this.Description);
                ::ChaosMind.markTarget(_party);
            } ],
            [ "protection from other parties", function( _party )
            {
                _party.setAttackableByAI(false);
            } ],
            [ "a roaming order", function( _party )
            {
                local roam = ::new("scripts/ai/world/orders/roam_order");
                roam.setPivot(this.Town);
                roam.setMinRange(::ChaosMind.Quest.MinSpawnDistance);
                roam.setMaxRange(::ChaosMind.Quest.MaxSpawnDistance);
                roam.setAllTerrainAvailable();
                roam.setTerrain(::Const.World.TerrainType.Ocean, false);
                roam.setTerrain(::Const.World.TerrainType.Shore, false);
                _party.getController().addOrder(roam);
            } ]
        ];

        foreach (step in steps)
        {
            try
            {
                step[1].call(this, party);
            }
            catch (e)
            {
                ::logWarning("Chaos Mind: the Red Dragon's party got no " + step[0] + " (" + e + ").");
            }
        }

        ::logInfo("Chaos Mind: the Red Dragon spawned " + ::ChaosMind.Altar.describeLocation(party.getTile()) + ".");
        return party;
    }

    // ---- Battle: the seven hexes ----

    // { Head, Tail, Wings = [ four directions ] } for a head direction (0 N, 1 NE, 2 SE, 3 S, 4 SW, 5 NW).
    function getLayout( _head )
    {
        local wings = [];

        for (local d = 0; d < 6; ++d)
        {
            if (d != _head && d != (_head + 3) % 6)
            {
                wings.push(d);
            }
        }

        return { Head = _head, Tail = (_head + 3) % 6, Wings = wings };
    }

    // The art faces right; heads to the west mirror it.
    function isFacingRight( _head )
    {
        return _head == 1 || _head == 2;
    }

    function isFreeTile( _tile )
    {
        if (!_tile.IsEmpty)
        {
            return false;
        }

        if ("TerrainType" in ::Const.Tactical && "Impassable" in ::Const.Tactical.TerrainType && _tile.Type == ::Const.Tactical.TerrainType.Impassable)
        {
            return false;
        }

        return true;
    }

    // Can the dragon land with its body on _center? The six hexes around must be free; the centre
    // may be the body's own hex (it stays there while in the air).
    function isFootprintFree( _center, _body )
    {
        if (!this.isFreeTile(_center) && _center.ID != _body.getTile().ID)
        {
            return false;
        }

        for (local d = 0; d < 6; ++d)
        {
            if (!_center.hasNextTile(d) || !this.isFreeTile(_center.getNextTile(d)))
            {
                return false;
            }
        }

        return true;
    }

    // Everyone the dragon fights: alive, on the map, not on its side.
    function getOpponents( _body )
    {
        local ret = [];
        local instances = ::Tactical.Entities.getAllInstances();

        foreach (faction in instances)
        {
            foreach (a in faction)
            {
                if (a != null && a.isAlive() && !a.isDying() && a.isPlacedOnMap() && !a.isAlliedWith(_body))
                {
                    ret.push(a);
                }
            }
        }

        return ret;
    }

    // Is _tile in the breath's cone: within BreathRange of the head, and straight in front of it
    // (one hex further from the body than from the head)?
    function isInCone( _center, _headTile, _tile )
    {
        local dh = _headTile.getDistanceTo(_tile);
        return dh >= 1 && dh <= this.BreathRange && _center.getDistanceTo(_tile) == dh + 1;
    }

    function getConeTiles( _center, _head )
    {
        local ret = [];

        if (!_center.hasNextTile(_head))
        {
            return ret;
        }

        local headTile = _center.getNextTile(_head);
        local r = this.BreathRange + 1;
        local cx = headTile.SquareCoords.X;
        local cy = headTile.SquareCoords.Y;

        for (local x = cx - r; x <= cx + r; ++x)
        {
            for (local y = cy - r; y <= cy + r; ++y)
            {
                if (!::Tactical.isValidTileSquare(x, y))
                {
                    continue;
                }

                local t = ::Tactical.getTileSquare(x, y);

                if (this.isInCone(_center, headTile, t))
                {
                    ret.push(t);
                }
            }
        }

        return ret;
    }

    // Where to land: { Tile, Head } near the company, or null. Scores brothers it will push away
    // (next to the footprint) and brothers in front of its head; slightly prefers short flights.
    // If no spot within 6 hexes of the company is clear, any clear spot will do: it must land.
    function chooseLanding( _body )
    {
        local opponents = this.getOpponents(_body);

        if (opponents.len() == 0)
        {
            return null;
        }

        local best = this.findLanding(_body, opponents, 6);
        return best != null ? best : this.findLanding(_body, opponents, 99);
    }

    function findLanding( _body, _opponents, _maxDistance )
    {
        local opponents = _opponents;

        local mapSize = ::Tactical.getMapSize();
        local best = null;
        local bestScore = -9000.0;

        for (local x = 0; x < mapSize.X; ++x)
        {
            for (local y = 0; y < mapSize.Y; ++y)
            {
                if (!::Tactical.isValidTileSquare(x, y))
                {
                    continue;
                }

                local center = ::Tactical.getTileSquare(x, y);
                local nearest = 99;

                foreach (o in opponents)
                {
                    nearest = ::Math.min(nearest, center.getDistanceTo(o.getTile()));
                }

                if (nearest < 2 || nearest > _maxDistance || !this.isFootprintFree(center, _body))
                {
                    continue;
                }

                local score = 0.0;

                foreach (o in opponents)
                {
                    local d = center.getDistanceTo(o.getTile());

                    if (d == 2)
                    {
                        score += 3.0;
                    }
                    else if (d <= 4)
                    {
                        score += 1.0;
                    }
                }

                local head = this.HeadDirections[0];
                local headScore = -1;

                foreach (dir in this.HeadDirections)
                {
                    local headTile = center.getNextTile(dir);
                    local n = 0;

                    foreach (o in opponents)
                    {
                        if (this.isInCone(center, headTile, o.getTile()))
                        {
                            ++n;
                        }
                    }

                    if (n > headScore)
                    {
                        headScore = n;
                        head = dir;
                    }
                }

                score += headScore * 2.0 - nearest * 0.25 + ::Math.rand(0, 10) * 0.01;

                if (score > bestScore)
                {
                    bestScore = score;
                    best = { Tile = center, Head = head };
                }
            }
        }

        return best;
    }

    // ---- Battle: actions ----

    function log( _text )
    {
        try
        {
            ::Tactical.EventLog.log(_text);
        }
        catch (e)
        {
        }
    }

    function getColorizedName( _body )
    {
        try
        {
            return ::Const.UI.getColorizedEntityName(_body);
        }
        catch (e)
        {
            return this.Name;
        }
    }

    function playSound( _body, _sounds, _volume = 1.5 )
    {
        try
        {
            ::Sound.play(_sounds[::Math.rand(0, _sounds.len() - 1)], ::Const.Sound.Volume.Actor * _volume, _body.getPos());
        }
        catch (e)
        {
        }
    }

    // Takes off: the parts leave the board; the body turns invisible and can't be hurt.
    function takeOff( _body )
    {
        _body.removeParts();
        ::ChaosMind.Dragon.makeAirborne(_body);
        this.log(this.getColorizedName(_body) + " beats its wings and rises into the sky!");
        this.playSound(_body, [ "sounds/enemies/lindwurm_idle_01.wav", "sounds/enemies/lindwurm_idle_05.wav" ], 2.0);
    }

    function makeAirborne( _body )
    {
        if (!_body.getSkills().hasSkill("effects.chaos_mind_dragon_airborne"))
        {
            _body.getSkills().add(::new("scripts/skills/effects/chaos_mind_dragon_airborne_effect"));
        }
    }

    // Lands at _choice ({ Tile, Head }) once the body stands on _choice.Tile: the parts come
    // back, the body shows, and everyone next to the dragon is pushed back a hex.
    function finishLanding( _body, _choice )
    {
        _body.setHeadDirection(_choice.Head);
        _body.getSkills().removeByID("effects.chaos_mind_dragon_airborne");
        _body.spawnParts();
        this.log(this.getColorizedName(_body) + " lands with a crash that shakes the ground!");
        this.playSound(_body, [ "sounds/enemies/lindwurm_death_01.wav", "sounds/enemies/lindwurm_hurt_02.wav" ], 2.0);

        try
        {
            ::Tactical.getCamera().quake(_body.getTile(), 1.0);
        }
        catch (e)
        {
        }

        this.pushAway(_body, _body.getTile());
    }

    // Everyone on a hex next to the footprint (two hexes from the body) goes one hex further out.
    function pushAway( _body, _center )
    {
        // Hexes already promised to someone pushed this landing (the moves take a moment).
        local claimed = {};

        foreach (a in this.getOpponents(_body))
        {
            local from = a.getTile();

            if (_center.getDistanceTo(from) != 2)
            {
                continue;
            }

            local dest = null;
            local dir = _center.getDirectionTo(from);

            foreach (d in [ dir, (dir + 1) % 6, (dir + 5) % 6 ])
            {
                if (!from.hasNextTile(d))
                {
                    continue;
                }

                local t = from.getNextTile(d);

                if (_center.getDistanceTo(t) == 3 && t.IsEmpty && !(t.ID in claimed) && ::Math.abs(t.Level - from.Level) <= 1)
                {
                    dest = t;
                    break;
                }
            }

            if (dest == null)
            {
                continue;
            }

            claimed[dest.ID] <- true;

            try
            {
                if ("MovementType" in ::Const.Tactical)
                {
                    a.setCurrentMovementType(::Const.Tactical.MovementType.Involuntary);
                }
            }
            catch (e)
            {
            }

            try
            {
                ::Tactical.getNavigator().teleport(a, dest, null, null, true);
                this.log(::Const.UI.getColorizedEntityName(a) + " is thrown back by the dragon's landing");
            }
            catch (e)
            {
                ::logWarning("Chaos Mind: the Red Dragon couldn't push " + a.getName() + " back (" + e + ").");
            }
        }
    }

    // A morale check for every opponent within RoarRange, harder up close.
    function roar( _body )
    {
        local here = _body.getTile();
        this.log(this.getColorizedName(_body) + " roars, and the air itself trembles!");
        this.playSound(_body, [ "sounds/enemies/lindwurm_flee_01.wav", "sounds/enemies/lindwurm_flee_03.wav" ], 2.5);

        foreach (a in this.getOpponents(_body))
        {
            local d = here.getDistanceTo(a.getTile());

            if (d > this.RoarRange)
            {
                continue;
            }

            try
            {
                a.checkMorale(-1, -10 + d * 2, ::Const.MoraleCheckType.MentalAttack);

                if (d <= 3 && a.isAlive() && !a.isDying())
                {
                    a.checkMorale(-1, 0, ::Const.MoraleCheckType.MentalAttack);
                }
            }
            catch (e)
            {
            }
        }
    }

    // Opponents in front of the head right now.
    function countInCone( _body )
    {
        local center = _body.getTile();

        if (!center.hasNextTile(_body.getHeadDirection()))
        {
            return 0;
        }

        local headTile = center.getNextTile(_body.getHeadDirection());
        local n = 0;

        foreach (a in this.getOpponents(_body))
        {
            if (this.isInCone(center, headTile, a.getTile()))
            {
                ++n;
            }
        }

        return n;
    }

    // Fire in the cone: every opponent there is burned, and the ground burns for BreathRounds.
    function breathe( _body )
    {
        local tiles = this.getConeTiles(_body.getTile(), _body.getHeadDirection());
        this.log(this.getColorizedName(_body) + " breathes a torrent of fire!");
        this.playSound(_body, [ "sounds/combat/dlc6/fire_pot_01.wav", "sounds/combat/dlc6/fire_pot_02.wav" ], 2.0);

        foreach (t in tiles)
        {
            this.setOnFire(_body, t);

            if (!t.IsOccupiedByActor)
            {
                continue;
            }

            local e = t.getEntity();

            if (e == null || !e.isAlive() || e.isDying() || e.isAlliedWith(_body))
            {
                continue;
            }

            this.burn(_body, e);
        }
    }

    function setOnFire( _body, _tile )
    {
        try
        {
            local p = {
                Type = "fire",
                Tooltip = "Dragonfire burns here",
                IsPositive = false,
                IsAppliedAtRoundStart = false,
                IsAppliedAtTurnEnd = true,
                IsAppliedOnMovement = false,
                IsAppliedOnEnter = false,
                IsByPlayer = false,
                Timeout = ::Time.getRound() + this.BreathRounds,
                Callback = ::Const.Tactical.Common.onApplyFire,
                function Applicable( _a )
                {
                    return true;
                }
            };

            if (_tile.Properties.Effect != null && _tile.Properties.Effect.Type == "fire")
            {
                _tile.Properties.Effect.Timeout = ::Time.getRound() + this.BreathRounds;
                return;
            }

            _tile.Properties.Effect = clone p;
            local particles = [];

            foreach (fp in ::Const.Tactical.FireParticles)
            {
                particles.push(::Tactical.spawnParticleEffect(true, fp.Brushes, _tile, fp.Delay, fp.Quantity, fp.LifeTimeQuantity, fp.SpawnRate, fp.Stages));
            }

            ::Tactical.Entities.addTileEffect(_tile, _tile.Properties.Effect, particles);
        }
        catch (e)
        {
            if (!this.FireWarned)
            {
                this.FireWarned = true;
                ::logWarning("Chaos Mind: the Red Dragon's fire couldn't be put on the ground (" + e + ").");
            }
        }
    }

    FireWarned = false,

    function burn( _body, _target )
    {
        local props = _target.getCurrentProperties();

        if ("IsImmuneToFire" in props && props.IsImmuneToFire)
        {
            return;
        }

        local damage = ::Math.rand(this.BreathDamageMin, this.BreathDamageMax);
        local fireMult = ("DamageReceivedFireMult" in props) ? props.DamageReceivedFireMult : 1.0;
        local hitInfo = clone ::Const.Tactical.HitInfo;
        hitInfo.DamageRegular = damage * fireMult;
        hitInfo.DamageArmor = damage;
        hitInfo.DamageDirect = 0.25;
        hitInfo.BodyPart = ::Const.BodyPart.Body;
        hitInfo.BodyDamageMult = 1.0;
        hitInfo.FatalityChanceMult = 0.0;

        if ("Burning" in ::Const.Injury)
        {
            hitInfo.Injuries = ::Const.Injury.Burning;
        }

        _target.onDamageReceived(_body, null, hitInfo);
    }

    // ---- Battle test ----

    // The dragon key (Ctrl+D by default; 15 Nov: "when pressing the keybind I want to be
    // attacked by the dragon"). On the world map a Red Dragon party lands next to the company and
    // comes for it; in battle one drops into the fight. Pressing the key is the opt-in, so it works
    // with the Red Dragon setting off too (that setting is for the contract). Every press is logged.
    function onTestKey()
    {
        ::logInfo("Chaos Mind: the Red Dragon key was pressed (" + (::Tactical.isActive() ? "battle" : "world map") + ").");

        if (!::Tactical.isActive())
        {
            return this.onWorldKey();
        }

        local spawned = false;

        try
        {
            spawned = this.spawnForTest();
        }
        catch (e)
        {
            ::logError("Chaos Mind: the test Red Dragon could not be spawned (" + e + ").");
        }

        try
        {
            ::Tactical.EventLog.log(spawned ? "A Red Dragon circles overhead (test); it lands on its turn." : "No test Red Dragon could be spawned; see log.html.");
        }
        catch (e)
        {
        }

        return true;
    }

    // Mod Settings -> Dev / Game breaking -> "Summon the Red Dragon" (15 Nov, after Ctrl+D also
    // never reached the mod). The button is pressed with the settings screen open, so the summon
    // waits: a real-time poll every PollMs lands it once no menu is open, on the world map (it
    // attacks the company) or in battle (it joins the fight). Gives up after PollTries.
    SummonPending = false,
    SummonTries = 0,
    PollMs = 250,
    PollTries = 480,

    function requestSummon()
    {
        if (this.SummonPending)
        {
            return;
        }

        this.SummonPending = true;
        this.SummonTries = 0;
        ::logInfo("Chaos Mind: Red Dragon summoned from Mod Settings; it comes once the menus are closed.");
        this.scheduleSummonPoll();
    }

    function scheduleSummonPoll()
    {
        try
        {
            ::Time.scheduleEvent(::TimeUnit.Real, this.PollMs, function( _data )
            {
                ::ChaosMind.Dragon.pollSummon();
            }, null);
        }
        catch (e)
        {
            this.SummonPending = false;
            ::logError("Chaos Mind: the Red Dragon summon could not wait for the menus (" + e + ").");
        }
    }

    function isClearToSummon()
    {
        if (::Tactical.isActive())
        {
            local t = ::Tactical.State;
            return t != null && !t.m.MenuStack.hasBacksteps();
        }

        local w = ::World.State;
        return w != null && w.getPlayer() != null && !w.m.MenuStack.hasBacksteps()
            && !w.m.EventScreen.isVisible() && !w.m.EventScreen.isAnimating();
    }

    function pollSummon()
    {
        if (!this.SummonPending)
        {
            return;
        }

        this.SummonTries += 1;
        local clear = false;

        try
        {
            clear = this.isClearToSummon();
        }
        catch (e)
        {
        }

        if (clear)
        {
            this.SummonPending = false;
            this.onTestKey();
            return;
        }

        if (this.SummonTries >= this.PollTries)
        {
            this.SummonPending = false;
            ::logInfo("Chaos Mind: Red Dragon summon given up; no campaign map or battle came up within two minutes.");
            return;
        }

        this.scheduleSummonPoll();
    }

    // World map: a Red Dragon party right next to the company. The game's own party AI makes it
    // attack ("You are being attacked"); a notice says so, and if it hesitates the player can click
    // it to fight. Not a contract target: no pay, nothing in the contract flags.
    function onWorldKey()
    {
        local lines;

        try
        {
            local state = ::World.State;

            if (state == null || state.getPlayer() == null)
            {
                return false;
            }

            if (state.m.EventScreen.isVisible() || state.m.MenuStack.hasBacksteps())
            {
                ::logInfo("Chaos Mind: no Red Dragon ambush, a window or town screen is open.");
                return false;
            }

            // No window when it lands (15 Nov, "remove the pop up for now"): the game's own
            // "you are being attacked" screen follows. Failures still say why.
            if (this.spawnAmbush() != null)
            {
                return true;
            }

            lines = [ "No Red Dragon could land here: no free tile next to your company.", "Move off the mountains or the coast and try again." ];
        }
        catch (e)
        {
            ::logError("Chaos Mind: the Red Dragon ambush failed (" + e + ").");
            lines = [ "The Red Dragon could not land (see log.html)." ];
        }

        ::ChaosMind.Notice.close();
        ::ChaosMind.Notice.toggle("The Red Dragon", lines);
        return true;
    }

    // A free, walkable world tile 1 to 3 tiles from _from, nearest first.
    function findAmbushTile( _from )
    {
        local t = ::Const.World.TerrainType;

        for (local d = 1; d <= 3; ++d)
        {
            for (local dx = -d; dx <= d; ++dx)
            {
                for (local dy = -d; dy <= d; ++dy)
                {
                    local x = _from.SquareCoords.X + dx;
                    local y = _from.SquareCoords.Y + dy;

                    if (!::World.isValidTileSquare(x, y))
                    {
                        continue;
                    }

                    local tile = ::World.getTileSquare(x, y);

                    if (tile.getDistanceTo(_from) != d || tile.IsOccupied || tile.Type == t.Ocean || tile.Type == t.Shore || tile.Type == t.Mountains)
                    {
                        continue;
                    }

                    return tile;
                }
            }
        }

        return null;
    }

    function spawnAmbush()
    {
        local player = ::World.State.getPlayer();
        local tile = this.findAmbushTile(player.getTile());
        local faction = ::ChaosMind.Quest.getFaction("Beasts");

        if (tile == null || faction == null)
        {
            ::logWarning("Chaos Mind: no Red Dragon ambush (" + (tile == null ? "no free tile next to the company" : "no beast faction") + ").");
            return null;
        }

        local template = ("Lindwurm" in ::Const.World.Spawn) ? ::Const.World.Spawn.Lindwurm : ::Const.World.Spawn.BanditRaiders;
        local party = faction.spawnEntity(tile, this.PartyName, false, template, 100);

        if (party == null)
        {
            ::logError("Chaos Mind: the Red Dragon ambush party could not be created.");
            return null;
        }

        local steps = [
            [ "its dragon", function( _party )
            {
                _party.getTroops().clear();
                ::Const.World.Common.addTroop(_party, { Type = ::Const.World.Spawn.Troops.ChaosMindRedDragon }, true, 0);
            } ],
            [ "its look", function( _party )
            {
                _party.setDescription(this.Description);
                _party.getFlags().set("ChaosMind.DragonAmbush", true);
                ::ChaosMind.markTarget(_party);
            } ],
            [ "protection from other parties", function( _party )
            {
                _party.setAttackableByAI(false);
            } ]
        ];

        foreach (step in steps)
        {
            try
            {
                step[1].call(this, party);
            }
            catch (e)
            {
                ::logWarning("Chaos Mind: the Red Dragon ambush got no " + step[0] + " (" + e + ").");
            }
        }

        ::logInfo("Chaos Mind: a Red Dragon lands " + tile.getDistanceTo(player.getTile()) + " tile(s) from the company to attack it (dragon key).");
        return party;
    }

    // Spawns a dragon on a free hex as far as possible from the company (it lands on its first turn).
    function spawnForTest()
    {
        if (!::Tactical.isActive())
        {
            ::logWarning("Chaos Mind: no test Red Dragon, not in a battle.");
            return false;
        }

        local players = [];

        foreach (a in ::Tactical.Entities.getInstancesOfFaction(::Const.Faction.Player))
        {
            if (a.isPlacedOnMap())
            {
                players.push(a);
            }
        }

        local mapSize = ::Tactical.getMapSize();
        local best = null;
        local bestDist = -1;

        for (local x = 0; x < mapSize.X; ++x)
        {
            for (local y = 0; y < mapSize.Y; ++y)
            {
                if (!::Tactical.isValidTileSquare(x, y))
                {
                    continue;
                }

                local t = ::Tactical.getTileSquare(x, y);

                if (!this.isFreeTile(t))
                {
                    continue;
                }

                local nearest = 99;

                foreach (p in players)
                {
                    nearest = ::Math.min(nearest, t.getDistanceTo(p.getTile()));
                }

                if (nearest > bestDist && nearest <= 14)
                {
                    bestDist = nearest;
                    best = t;
                }
            }
        }

        if (best == null)
        {
            ::logWarning("Chaos Mind: no free hex for a test dragon.");
            return false;
        }

        local dragon = ::Tactical.spawnEntity(this.Script, best.Coords.X, best.Coords.Y);
        dragon.setFaction(::Const.Faction.Enemy);
        ::logInfo("Chaos Mind: a test Red Dragon was spawned at " + best.SquareCoords.X + ", " + best.SquareCoords.Y + "; it lands on its first turn.");
        return true;
    }
};

// ---- Registration: entity type, stats, troop, AI ids ----

::ChaosMind.Dragon.EntityType <- (function()
{
    local id = ::Const.EntityIcon.len();
    ::Const.EntityIcon.push("lindwurm_orientation");
    ::Const.Strings.EntityName.push(::ChaosMind.Dragon.Name);

    if ("EntityNamePlural" in ::Const.Strings)
    {
        while (::Const.Strings.EntityNamePlural.len() < id)
        {
            ::Const.Strings.EntityNamePlural.push(::Const.Strings.EntityName[::Const.Strings.EntityNamePlural.len()]);
        }

        ::Const.Strings.EntityNamePlural.push("Red Dragons");
    }

    if ("EntityFaction" in ::Const)
    {
        ::Const.EntityFaction.push(::Const.FactionType.Beasts);
    }

    return id;
})();
::Const.EntityType.ChaosMindRedDragon <- ::ChaosMind.Dragon.EntityType;

::Const.Tactical.Actor.ChaosMindRedDragon <- {
    XP = 5000,
    ActionPoints = 12,
    Hitpoints = 2000,
    Bravery = 300,
    Stamina = 500,
    MeleeSkill = 80,
    RangedSkill = 80,
    MeleeDefense = 10,
    RangedDefense = 10,
    Initiative = 90,
    FatigueEffectMult = 0.0,
    MoraleEffectMult = 0.0,
    FatigueRecoveryRate = 50,
    Armor = [
        400,
        400
    ]
};

::Const.World.Spawn.Troops.ChaosMindRedDragon <- {
    ID = ::Const.EntityType.ChaosMindRedDragon,
    Variant = 0,
    Strength = 400,
    Cost = 400,
    Row = 1,
    Script = ::ChaosMind.Dragon.Script
};

::Const.AI.Agent.ID.ChaosMindRedDragon <- "agent.chaos_mind_red_dragon";
::Const.AI.Agent.ID.ChaosMindRedDragonPart <- "agent.chaos_mind_red_dragon_part";
::Const.AI.Behavior.ID.ChaosMindDragon <- ::Const.AI.Behavior.ID.COUNT;
::Const.AI.Behavior.ID.COUNT = ::Const.AI.Behavior.ID.COUNT + 1;

if ("Name" in ::Const.AI.Behavior)
{
    ::Const.AI.Behavior.Name.push("ChaosMindDragon");
}

::Const.AI.Behavior.Order.ChaosMindDragon <- 1;
::Const.AI.Behavior.Score.ChaosMindDragon <- 5000;

::ChaosMind.addWorldCheck("Red Dragon check", function()
{
    ::ChaosMind.Dragon.check();
});

// 15 Nov: Ctrl+D under a new ID. The game never delivered Shift to the mod: Ctrl+Shift+B pressed
// on the world map arrived as Ctrl+B (the boss list opened), and no Ctrl+Shift combo ever fired.
// The new ID also drops the old saved binding, which kept a Shift combo.
::ChaosMind.Mod.Keybinds.addSQKeybind(
    "redDragonKey",
    "ctrl+d",
    // World map too since 15 Nov: there it sends a Red Dragon at the company.
    ::MSU.Key.State.World | ::MSU.Key.State.Tactical,
    function()
    {
        return ::ChaosMind.Dragon.onTestKey();
    },
    "Red Dragon: attack my company / join this battle (experimental)",
    // On the key going down (MSU's default is on release, which misses if Ctrl or Shift is let go
    // before D).
    ::MSU.Key.KeyState.Press
);

// The summon button (15 Nov), under Extra content next to the Red Dragon setting.
try
{
    local page = ::ChaosMind.Mod.ModSettings.getPage("DevGameBreaking");
    local button = page.addButtonSetting("SummonRedDragon", "", "Summon Red Dragon",
        "After you close Mod Settings, a Red Dragon lands next to your company on the world map and attacks it; in a battle it joins the fight. Works with the Red Dragon setting off. The same as the Ctrl+D key.");
    button.addCallback(function()
    {
        ::ChaosMind.Dragon.requestSummon();
    });
}
catch (e)
{
    ::logWarning("Chaos Mind: the 'Summon the Red Dragon' button could not be added (" + e + ").");
}

// World map diagnostics (15 Nov): D pressed with Ctrl held is logged with the keys MSU saw held,
// and the first time the map runs the dragon key's binding is logged, so a Ctrl+D that does
// nothing shows why.
::ChaosMind.HooksMod.hook("scripts/states/world_state", function(q)
{
    if (!q.contains("onKeyInput", true))
    {
        return;
    }

    q.onKeyInput = @(__original) function( _key )
    {
        try
        {
            local map = ::MSU.Key.KeyMapSQ;
            local code = _key.getKey().tostring();

            if (code in map && map[code] == "d" && _key.getState() == 1)
            {
                local held = [];

                foreach (k, _ in ::MSU.System.Keybinds.PressedKeys)
                {
                    if (k != "d")
                    {
                        held.push(k);
                    }
                }

                if (held.find("ctrl") != null)
                {
                    held.sort();
                    ::logInfo("Chaos Mind: key D pressed on the world map with " + held.reduce(@(a, b) a + "+" + b) + " held; the dragon key is " + ::ChaosMind.getHotkey("redDragonKey", "?") + ".");
                }
            }
        }
        catch (e)
        {
        }

        return __original(_key);
    }
});

::ChaosMind.Dragon.KeyLogged <- false;
::ChaosMind.addWorldCheck("Red Dragon key log", function()
{
    if (!::ChaosMind.Dragon.KeyLogged)
    {
        ::ChaosMind.Dragon.KeyLogged = true;
        ::logInfo("Chaos Mind: the Red Dragon key is " + ::ChaosMind.getHotkey("redDragonKey", "not bound") + " (world map and battle).");
    }
});

// Diagnostics (14 Nov): in battle, D pressed with Ctrl or Shift held is logged with the keys MSU
// saw held, so a missed Ctrl+Shift+D shows why. Runs before MSU's own handling and changes nothing.
::ChaosMind.HooksMod.hook("scripts/states/tactical_state", function(q)
{
    if (!q.contains("onKeyInput", true))
    {
        return;
    }

    q.onKeyInput = @(__original) function( _key )
    {
        try
        {
            local map = ::MSU.Key.KeyMapSQ;
            local code = _key.getKey().tostring();

            if (code in map && map[code] == "d" && _key.getState() == 1)
            {
                local held = [];

                foreach (k, _ in ::MSU.System.Keybinds.PressedKeys)
                {
                    if (k != "d")
                    {
                        held.push(k);
                    }
                }

                // Only with Ctrl or Shift held: plain WASD camera moves (D with W or A) logged dozens
                // of lines a second (14 Nov).
                if (held.find("ctrl") != null || held.find("shift") != null)
                {
                    held.sort();
                    ::logInfo("Chaos Mind: key D pressed in battle with " + held.reduce(@(a, b) a + "+" + b) + " held.");
                }
            }
        }
        catch (e)
        {
        }

        return __original(_key);
    }
});
