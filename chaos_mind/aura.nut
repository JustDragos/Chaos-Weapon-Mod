// Aura of 10: an amulet won from a hunt that opens at 250 Chaos Mind kills.
//  - The hunt: like the Black Skull (chaos_mind/quest.nut, whose helpers it uses). When the blade
//    has AuraKills kills, the town the company comes to offers it as a real contract
//    (chaos_mind/contracts.nut). Accepting spawns "The Ten", a marked party of ten named human champions that roams near that town and
//    that other parties leave alone. It can't fail: the hunt is done once the party is gone.
//  - The reward: the amulet (accessory slot). While any brother wears it, the company's strength on
//    the world map is at least CompanyStrength, about a mid-game company of ten, so weak parties
//    don't attack and keep away.
//  - Ctrl+F shows where The Ten are (after the Black Skull's party, if both are hunted).
::ChaosMind.Aura <- {
    EventID = "event.chaos_mind_aura",
    ItemID = "accessory.aura_of_10",
    Script = "scripts/items/accessory/aura_of_10_item",
    AuraKills = 250,
    // A company of ten brothers around level 7 with mid-game gear. The vanilla formula is
    // encrypted; Legends rates such a company 200-240 on Normal and Expert. The company's own
    // strength is logged once (below), to tune this if small parties still attack.
    CompanyStrength = 220,
    // The contract's crowns before haggling, and its skulls in town.
    ContractPay = 2000,
    ContractDifficultyMult = 1.5,

    // 0 not started, 1 hunting, 2 done.
    StateFlag = "ChaosMind.AuraState",
    TargetFlag = "ChaosMind.AuraTargetID",
    DeclinedDayFlag = "ChaosMind.AuraDeclinedDay",
    // The amulet is owed when the stash had no room; given once a free slot appears.
    OwedFlag = "ChaosMind.AuraOwed",

    PartyName = "The Ten",
    Description = "Ten champions who swore to ride together until one of them holds a blade worth the oath. They have heard of yours.",
    // Ten human champions; a missing type (no DLC) is replaced by a Bandit Leader.
    Champions = [
        "HedgeKnight", "Swordmaster", "MasterArcher", "Knight", "BanditLeader",
        "BarbarianChampion", "Executioner", "Gladiator", "DesertDevil", "NomadLeader"
    ],

    Town = null,
    LastTarget = null,
    // The champions' names, for the log and the event.
    ChampionNames = "",
    PendingScreen = null,
    LastHourChecked = -1,
    StrengthLogged = false,

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

    function isWorn()
    {
        foreach (bro in ::World.getPlayerRoster().getAll())
        {
            local item = bro.getItems().getItemAtSlot(::Const.ItemSlot.Accessory);

            if (item != null && item != -1 && item.getID() == this.ItemID)
            {
                return true;
            }
        }

        return false;
    }

    // player_party.updateStrength hook: never below a company of ten while the amulet is worn.
    function raiseStrength( _party )
    {
        if (!this.StrengthLogged)
        {
            this.StrengthLogged = true;
            ::logInfo("Chaos Mind: the company's own strength on the map is " + _party.m.Strength + " (Aura of 10 raises it to at least " + this.CompanyStrength + ").");
        }

        if (_party.m.Strength < this.CompanyStrength && this.isWorn())
        {
            _party.m.Strength = this.CompanyStrength;
        }
    }

    // ---- The hunt ----

    // World map, every update with a clear screen; the same rhythm as the Black Skull.
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
            this.giveOwed();

            // Shown through the fog even while its contract runs the hunt (older saves too).
            if (this.getState() == 1)
            {
                ::ChaosMind.markTarget(this.getTarget());
            }

            // No fallback any more (14 Nov): a hunt only runs with its contract, which finishes it;
            // without one it's called off (::ChaosMind.Contracts.callOffOrphans).
        }
    }

    function isOpen()
    {
        if (this.getState() != 0 || ::World.getTime().Days <= ::ChaosMind.Quest.getFlag(this.DeclinedDayFlag))
        {
            return false;
        }

        local sword = ::ChaosMind.findSword();
        return sword != null && sword.m.Kills >= this.AuraKills;
    }

    function decline()
    {
        ::World.Flags.set(this.DeclinedDayFlag, ::World.getTime().Days);
    }

    function fireEvent( _screen )
    {
        this.PendingScreen = _screen;
        ::World.Events.fire(this.EventID);
    }

    function checkActive()
    {
        local target = this.getTarget();

        if (target != null)
        {
            // The ring isn't saved; mark it again after loading.
            try
            {
                ::ChaosMind.markTarget(target);
                target.getSprite("banner").setBrush(::ChaosMind.Quest.Banner);
            }
            catch (e)
            {
            }

            return;
        }

        ::World.Flags.set(this.StateFlag, 2);
        ::World.Flags.set(this.TargetFlag, 0);
        ::World.Flags.set(this.OwedFlag, true);
        ::logInfo("Chaos Mind: The Ten are gone; the Aura of 10 hunt is done.");
        this.giveOwed();
        this.fireEvent("Done");
    }

    // Puts the amulet in the stash if it's owed and there's room. True once given.
    function giveOwed()
    {
        if (!::World.Flags.has(this.OwedFlag) || !::World.Flags.get(this.OwedFlag))
        {
            return false;
        }

        if (::World.Assets.getStash().add(::new(this.Script)) == null)
        {
            ::logInfo("Chaos Mind: no room in the stash for the Aura of 10; it waits for a free slot.");
            return false;
        }

        ::World.Flags.set(this.OwedFlag, false);
        ::logInfo("Chaos Mind: the Aura of 10 was put in the stash.");
        return true;
    }

    // A copy of a troop type that always rolls a champion, with names to give him. A type without
    // names of its own borrows _namesFrom's (orcs pass "OrcWarlord", so they get orc names).
    function getChampionType( _key, _namesFrom = "BanditLeader" )
    {
        local troops = ::Const.World.Spawn.Troops;
        local key = (_key in troops) ? _key : "BanditLeader";
        local type = clone troops[key];
        local names = (_namesFrom in troops && "NameList" in troops[_namesFrom] && troops[_namesFrom].NameList != null) ? troops[_namesFrom] : troops.BanditLeader;

        if (!("Variant" in type) || type.Variant <= 0)
        {
            type.Variant <- 1;
        }

        if (!("NameList" in type) || type.NameList == null)
        {
            type.NameList <- names.NameList;
        }

        if (!("TitleList" in type) || type.TitleList == null)
        {
            type.TitleList <- ("TitleList" in names) ? names.TitleList : null;
        }

        return type;
    }

    // Accepting the hunt: spawns The Ten near this.Town. Returns the party, or null.
    function spawnTarget()
    {
        local q = ::ChaosMind.Quest;

        if (this.Town == null || !this.Town.isAlive())
        {
            ::logError("Chaos Mind: the Aura of 10 hunt has no town to start from.");
            return null;
        }

        local tile = q.findSpawnTile(this.Town);
        local faction = q.getFaction("Bandits");

        if (tile == null || faction == null)
        {
            ::logError("Chaos Mind: The Ten could not spawn (" + (tile == null ? "no free tile near " + this.Town.getName() : "no bandit faction") + ").");
            return null;
        }

        // The template only gives the party its figure on the map; its troops are replaced.
        local party = faction.spawnEntity(tile, this.PartyName, false, ::Const.World.Spawn.BanditRaiders, 100);

        if (party == null)
        {
            ::logError("Chaos Mind: The Ten could not be created.");
            return null;
        }

        ::World.Flags.set(this.StateFlag, 1);
        ::World.Flags.set(this.TargetFlag, party.getID());
        this.LastTarget = party;

        this.ChampionNames = "";
        local steps = [
            [ "its troops", function( _party )
            {
                _party.getTroops().clear();

                foreach (i, key in this.Champions)
                {
                    local troop = ::Const.World.Common.addTroop(_party, { Type = this.getChampionType(key) }, true, ::ChaosMind.Quest.LeaderMinibossify);
                    this.ChampionNames += (i == 0 ? "" : ", ") + ::ChaosMind.Duel.getLeaderName(troop);
                }
            } ],
            [ "its look", function( _party )
            {
                _party.setDescription(this.Description);
                _party.getSprite("banner").setBrush(::ChaosMind.Quest.Banner);
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
                roam.setTerrain(::Const.World.TerrainType.Mountains, false);
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
                ::logWarning("Chaos Mind: The Ten got no " + step[0] + " (" + e + ").");
            }
        }

        ::logInfo("Chaos Mind: The Ten spawned " + ::ChaosMind.Altar.describeLocation(party.getTile()) + ": " + this.ChampionNames + ".");
        return party;
    }

    // Ctrl+F: where The Ten are. False when they aren't being hunted.
    function showDirection()
    {
        local target = this.getState() == 1 ? this.getTarget() : null;

        if (target == null)
        {
            ::ChaosMind.Notice.close();
            return false;
        }

        local text = "The Ten are " + ::ChaosMind.Altar.describeLocation(target.getTile()) + ".";
        ::logInfo("Chaos Mind: " + text);
        return ::ChaosMind.Notice.toggle("Aura of 10", [ text ]);
    }
};

::ChaosMind.HooksMod.hook("scripts/entity/world/player_party", function(q)
{
    q.updateStrength = @(__original) function()
    {
        __original();

        try
        {
            ::ChaosMind.Aura.raiseStrength(this);
        }
        catch (e)
        {
        }
    }
});

::ChaosMind.addWorldCheck("Aura of 10 check", function()
{
    ::ChaosMind.Aura.check();
});
