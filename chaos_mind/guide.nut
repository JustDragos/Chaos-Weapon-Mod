// Chaos Guide: a book (scripts/items/misc/chaos_guide_item.nut) holding the full explanation of
// every item and perk in this mod, so their tooltips can stay short.
//  - Given with Chaos Mind at The Frozen Eye (::ChaosMind.Altar).
//  - Given back whenever Chaos Mind kills and the company has no guide (chaos_mind_effect).
//  - Given once on the world map to a company that already owns Chaos Mind (older saves).
//  - Read with Ctrl+G (world map and battle, rebindable) or by right-clicking it in the stash.
::ChaosMind.Guide <- {
    ItemID = "misc.chaos_guide",
    Script = "scripts/items/misc/chaos_guide_item",
    GivenFlag = "ChaosMind.GuideGiven",
    KeybindID = "openChaosGuide",
    LastHourChecked = -1,
    Screen = null,

    function find()
    {
        foreach (item in ::World.Assets.getStash().getItems())
        {
            if (item != null && item.getID() == this.ItemID)
            {
                return item;
            }
        }

        return null;
    }

    // Puts a new guide in the stash. Returns it, or null if the stash is full.
    function give( _why )
    {
        local guide = ::new(this.Script);

        if (!::World.Assets.getStash().add(guide))
        {
            ::logInfo("Chaos Mind: no room in the stash for the Chaos Guide (" + _why + ").");
            return null;
        }

        ::World.Flags.set(this.GivenFlag, true);
        ::logInfo("Chaos Mind: the Chaos Guide was put in the stash (" + _why + ").");
        return guide;
    }

    // After a Chaos Mind kill: the company gets the guide back if it has none.
    function onSwordKill( _user )
    {
        if (this.find() != null || this.give("Chaos Mind killed and the company had no guide") == null)
        {
            return;
        }

        try
        {
            ::Tactical.EventLog.log("The Chaos Guide returns to the company's stash");
        }
        catch (e)
        {
        }
    }

    // World map, once an hour: a company that owns Chaos Mind but was never given the guide
    // (a save from before it existed) gets one.
    function check()
    {
        if (::World.Flags.has(this.GivenFlag) && ::World.Flags.get(this.GivenFlag))
        {
            return;
        }

        local hour = ::ChaosMind.getHour();

        if (hour == this.LastHourChecked)
        {
            return;
        }

        this.LastHourChecked = hour;

        if (::ChaosMind.findSword() != null && this.find() == null)
        {
            this.give("the company owns Chaos Mind");
        }
    }

    function open()
    {
        if (this.Screen == null)
        {
            return false;
        }

        this.Screen.show({ Title = "Chaos Guide", Chapters = this.getChapters() });
        return true;
    }

    // Hotkey: opens or closes the guide, if the company owns one. Otherwise the key is passed on.
    function toggle()
    {
        if (this.Screen != null && this.Screen.isShowing())
        {
            this.Screen.hide();
            return true;
        }

        if (this.find() == null)
        {
            return false;
        }

        return this.open();
    }

    // The book's text. Each chapter has a title and lines: "# " starts a heading, "- " a bullet,
    // anything else is a paragraph.
    function getChapters()
    {
        local cs = ::ChaosMind.CarnalStorage;
        local cc = ::ChaosMind.ChaosCircle;
        local sa = ::ChaosMind.SoulArrow;
        local ut = ::ChaosMind.UsedToIt;
        local chapters = [];

        local blade = [
            "A legendary two-handed greatsword. It swings with Overhead Strike, Split and Swing, like any greatsword, and deals 100 to 120 base damage.",
            "# Damage",
            "- +0.5% damage for every point of the wielder's Melee Skill. With the Chaos Armor perk this doubles to +1% per point.",
            "- +1% damage for every 10 kills the blade has taken, with no cap.",
            "# The black cloud",
            "- Every hit spreads damage to everyone around the target, friend or foe, except the wielder: 50% of the hit's damage 1 tile away, 25% at 2 tiles.",
            "- Armor still applies. Swing and Split make one cloud for each enemy they hit.",
            "- Brothers with Chaos Protection are untouched by it.",
            "# The curse",
            "- Every hit also deals 200% of its damage to each of the wielder's allies within 2 tiles of him.",
            "- Keep your other brothers at least 3 tiles away, or give them Chaos Protection.",
            "# Kills",
            "- Every death the blade causes counts, brothers included: its attacks, the black cloud, the curse, Brother Sacrifice and Mass Sacrifice. The count is saved with the sword.",
            "- Every enemy it kills, by attack or cloud, gives Carnal Storage energy: the hitpoints he lost to the killing blow divided by " + cs.HitpointsPerEnergy + ".",
            "# Drawing champions",
            "- +2% chance for every 20 kills, up to 35%: at the start of each battle the wielder fights in, every enemy that can become a champion rolls this chance on top of the normal one.",
            "# Milestones",
            "- 100 kills: the blade awakens as Chaos Mind, the Devourer, and gives the company the Soul Arrow.",
            "- 100, 200 and 500 kills: each opens a part of the Black Skull hunt, which makes the blade give its wielder more max fatigue (see The Black Skull).",
            "- 500 kills: the gorged form. The blade changes its look. Every kill the wielder makes improves his mood by 1, and after a Brother or Mass Sacrifice he becomes Confident.",
            "# Granted skills",
            "- Carnal Storage, Brother Sacrifice and Mass Sacrifice, while it's equipped. Each has its own chapter."
        ];

        local sword = ::ChaosMind.findSword();

        if (sword != null)
        {
            blade.insert(1, "Your blade has " + sword.m.Kills + " kills: +" + sword.getKillBonus() + "% damage and +" + sword.getChampionBonus() + "% chance to draw champions.");
        }

        chapters.push({ Title = "The Frozen Eye", Lines = [
            "Chaos Mind is buried point-first in a mound of snow far in the frozen north: The Frozen Eye. There is one in every campaign, on snow or snowy forest, at least 6 tiles from any settlement.",
            "Press " + ::ChaosMind.getLocateKey() + " on the world map to see which way it lies and how far, until the sword is claimed.",
            "# The price",
            "- The eye demands eight lives. You choose the eight brothers yourself in a window; Offer them unlocks once exactly eight are chosen.",
            "- You need at least eight eligible brothers and one more who stays. Your player character can never be offered.",
            "- The sword goes to the stash first. If the stash is full, nothing happens and nobody dies.",
            "- Each offered brother's gear goes to the stash, and he is recorded as fallen.",
            "- The blade starts with 8 kills, one for each of them. This guide comes with it."
        ]});
        chapters.push({ Title = "Chaos Mind", Lines = blade });
        local q = ::ChaosMind.Quest;
        local skull = [
            "A three-part hunt that opens as the blade feeds. Each part must be finished before the next.",
            "# When it's offered",
            "- Part 1 at " + q.Tiers[0].Kills + " kills, part 2 at " + q.Tiers[1].Kills + ", part 3 at " + q.Tiers[2].Kills + ". The kills count is your Chaos Mind's.",
            "- Once the blade has enough kills, the offer comes the next time the company enters a town, any town. Turn it down and it comes again from the next day on.",
            "# The hunt",
            "- Accepting spawns a party under a black skull banner " + q.MinSpawnDistance + " to " + q.MaxSpawnDistance + " tiles from that town, led by a champion. It's marked on the map with a ring, and other parties leave it alone.",
            "- Part 1: " + q.Tiers[0].Name + " (brigands). Part 2: " + q.Tiers[1].Name + " (barbarians). Part 3: " + q.Tiers[2].Name + " (orcs).",
            "- " + ::ChaosMind.getLocateKey() + " shows where it is.",
            "- Its leader must die to Chaos Mind: the wielder's attacks, the black cloud or the curse. Once the party is gone, the part is done if he did.",
            "- If he dies any other way (another brother, a duel won by someone else), the part fails and is offered again from the next day, with a new party.",
            "# The reward",
            "- While wielding Chaos Mind, extra max fatigue for every +1% damage the blade has from kills: +" + q.Tiers[0].Rate + " after part 1, +" + q.Tiers[1].Rate + " after part 2, +" + q.Tiers[2].Rate + " after part 3 (rounded down). It grows as the blade keeps killing.",
            "- Example: at 500 kills (+50% damage) with all three parts done, +" + ::Math.floor(q.Tiers[2].Rate * 50) + " max fatigue."
        ];

        local done = q.getDone();

        if (q.getActive() != 0)
        {
            skull.insert(1, "Now hunting: part " + q.getActive() + ", " + q.Tiers[q.getActive() - 1].Name + ".");
        }
        else if (done < q.Tiers.len())
        {
            skull.insert(1, "Parts done: " + done + " of " + q.Tiers.len() + ". The next opens at " + q.Tiers[done].Kills + " kills.");
        }
        else
        {
            skull.insert(1, "All three parts are done.");
        }

        if (sword != null && done > 0)
        {
            skull.insert(2, "Your blade gives its wielder +" + q.getStaminaBonus(sword) + " max fatigue.");
        }

        chapters.push({ Title = "The Black Skull", Lines = skull });
        chapters.push({ Title = "Carnal Storage", Lines = [
            "A skill granted by Chaos Mind. 0 AP. It opens a window where the wielder trades his own body for energy, and spends energy on damage.",
            "# Sacrifices",
            "- Fatigue: " + cs.FatiguePerEnergy + " fatigue for 1 energy.",
            "- Blood: " + cs.HitpointsPerEnergy + " hitpoints for 1 energy. It always leaves him at least 1 hitpoint.",
            "- Flesh: one random minor injury he doesn't already have, for " + cs.InjuryEnergy + " energy.",
            "- Choose how many at once. A sacrifice you can't afford is greyed out.",
            "# Other sources of energy",
            "- Enemies killed by the blade or its cloud: the hitpoints they lost to the killing blow divided by " + cs.HitpointsPerEnergy + ".",
            "- Brothers struck by Brother or Mass Sacrifice: all the hitpoints they had, divided by " + cs.HitpointsPerEnergy + ".",
            "# Spending",
            "- Unleash: " + cs.UnleashCost + " energy for +" + (cs.DamagePerStack * 100).tointeger() + "% damage until the battle ends, up to " + cs.MaxStacks + " times (+" + (cs.DamagePerStack * cs.MaxStacks * 100).tointeger() + "%).",
            "- Overflow: once fully unleashed, every " + cs.OverflowCost + " stored energy automatically becomes another +" + (cs.OverflowDamage * 100).tointeger() + "% damage until the battle ends.",
            "# After the battle",
            "- Energy and every bonus are lost when the battle ends.",
            "- The status effect Carnal Storage shows the energy stored and the current bonus."
        ]});
        chapters.push({ Title = "Brother Sacrifice", Lines = [
            "A skill granted by Chaos Mind. 4 AP, 10 fatigue. Targets one adjacent brother.",
            "- He takes a full Chaos Mind strike: the weapon's damage with the Melee Skill bonus, the kill bonus and the wielder's damage bonuses. It always hits and ignores armor.",
            "- He always dies. He can't survive with a permanent injury, and Nine Lives doesn't save him.",
            "- All the hitpoints he had become energy: " + cs.HitpointsPerEnergy + " hitpoints for 1.",
            "- His death counts as a kill for the blade. There is no cloud or curse.",
            "- Brothers with Chaos Protection can't be chosen.",
            "- Every other brother's mood drops, and on the field they flee in terror (see Sacrifice Terror)."
        ]});
        chapters.push({ Title = "Mass Sacrifice", Lines = [
            "A skill granted by Chaos Mind. 6 AP, 25 fatigue. Only usable while at least one brother stands next to the wielder.",
            "- Every brother in the 6 tiles around him takes the same strike as Brother Sacrifice, and every one of them dies.",
            "- Brothers with Chaos Protection are skipped.",
            "- All the hitpoints lost become energy (" + cs.HitpointsPerEnergy + " for 1), and every death counts as a kill for the blade.",
            "- Every other brother's mood drops, and on the field they flee in terror (see Sacrifice Terror)."
        ]});
        chapters.push({ Title = "Sacrifice Terror", Lines = [
            "After any Brother or Mass Sacrifice, every other brother on the field is Terrified by the Sacrifice.",
            "- He drops to Fleeing at once and can't rally until the battle ends. Rally the Troops doesn't help him.",
            "- The wielder who did it is spared, as is anyone with Only Chaos Matters or Chaos Protection.",
            "- It is removed when the battle ends.",
            "# Hatred",
            "If the wielder has Only Chaos Matters, the company hates him for it: see that perk."
        ]});
        chapters.push({ Title = "Soul Arrow", Lines = [
            "The Devourer's gift. The first time any Chaos Mind the company owns reaches 100 kills, the event The Devourer's Gift puts a Soul Arrow in the stash. Once per campaign. If the stash is full, it asks you to make room and tries again the next day.",
            "# The arrow",
            "- It goes in the quiver (ammo) slot, but holds no arrows or bolts: a bow or crossbow can't shoot with it.",
            "- If the brother carrying it falls, it can be looted like any item.",
            "# The skill",
            "- Soul Arrow: 0 AP, " + sa.FatigueCost + " fatigue, once per battle. +" + sa.BonusAP + " Action Points this turn, even when he is already at full AP.",
            "# Recharging",
            "- After each battle, a spent arrow takes " + sa.RefillCost + " ammo from the company's supplies to recharge.",
            "- With less than " + sa.RefillCost + " ammo it stays empty and tries again after the next battle.",
            "- Only an arrow equipped by a brother who fought in the battle recharges, not one in the stash."
        ]});
        chapters.push({ Title = "Armor Fixer", Lines = [
            "A field repair kit. Every armorer, north and south, sells up to 3.",
            "- Carried in a bag slot.",
            "- Use Armor Fixer: 3 AP, no fatigue, single use. Repairs up to " + ::ChaosMind.ArmorFixer.Repair + " armor: body armor first, the rest to the helmet. Never above maximum.",
            "- Greyed out when there's nothing to repair, so it can't be wasted.",
            "- Several in one bag give one button each."
        ]});
        chapters.push({ Title = "Chaos Protection", Lines = [
            "Perk, tier 1.",
            "- Immune to Chaos Mind's black cloud and its curse.",
            "- Can't be sacrificed: Brother Sacrifice can't target him, Mass Sacrifice skips him.",
            "- Never flees from Sacrifice Terror.",
            "- Not touched by a Chaos Circle: neither screamed at nor slowed.",
            "- The cost: -" + ::ChaosMind.ChaosProtectionResolvePenalty + " Resolve while he has the perk."
        ]});
        chapters.push({ Title = "Only Chaos Matters", Lines = [
            "Perk, tier 3.",
            "- Immune to a Hexe's Charm and a Geist's Horrific Scream, including the scream of a Chaos Circle.",
            "- Never loses morale when an ally dies.",
            "- Never flees from Sacrifice Terror.",
            "- Isolated: other brothers can't raise his morale. Rally the Troops and Inspiring Presence do nothing for him. Resolve auras such as a banner still apply.",
            "# Hated by the company",
            "- Every other brother's mood drops by 1.5 each time he performs a Brother or Mass Sacrifice.",
            "- By 0.5 after every battle he fights in.",
            "- By 0.25 every day."
        ]});
        chapters.push({ Title = "Used to It", Lines = [
            "Perk, tier 4. Works for any brother; Chaos Mind isn't needed.",
            "- Every attack, melee or ranged, that misses him gives +" + ut.DefensePerStack + " Melee Defense and +" + ut.DefensePerStack + " Ranged Defense until the battle ends, up to " + ut.MaxStacks + " stacks (+" + (ut.DefensePerStack * ut.MaxStacks) + ").",
            "- A new stack already counts against the very next attack.",
            "- Dodging an attack costs him no fatigue.",
            "- The status effect Used to It (+N) shows the current bonus."
        ]});
        chapters.push({ Title = "Chaos Armor", Lines = [
            "Perk, tier 5. Only works while wielding Chaos Mind.",
            "- +1 Melee Defense and +1 Ranged Defense for every +1% damage the blade has gained from kills (one per 10 kills), with no cap.",
            "- Doubles the blade's Melee Skill scaling, from +0.5% to +1% damage per point. This also strengthens Brother and Mass Sacrifice."
        ]});
        chapters.push({ Title = "Fatigue Transfer", Lines = [
            "Perk, tier 6. Grants the skill Fatigue Transfer.",
            "- 1 AP. Targets one adjacent enemy.",
            "- All of the user's fatigue moves onto the enemy, up to the enemy's maximum, and the user drops to 0 fatigue.",
            "- Can be used once every 3 turns. Not usable at 0 fatigue."
        ]});
        chapters.push({ Title = "Chaos Circle", Lines = [
            "Perk, tier 7. Grants the skill Chaos Circle, usable only while wielding Chaos Mind.",
            "- 6 AP, 30 fatigue, once every 3 turns.",
            "- Target any visible tile 1 to 5 tiles away. The circle covers that tile and the 6 around it.",
            "# On cast",
            "- Everyone inside, friend or foe, is hit by a Geist's Horrific Scream.",
            "- How well each one resists depends on the gap between your Resolve and his. On the centre tile his Resolve for the check drops by the full gap (x" + cc.CenterMult + "); on the 6 tiles around it, by half (x" + cc.RingMult + ").",
            "- Example: you have 80 Resolve. A 40 Resolve brigand in the centre resists with 0; on the ring with 20.",
            "- Someone as brave as you or braver resists it like a Geist's scream, with no bonus. Aim the centre at the most fearful target.",
            "# The slow zone",
            "- Lasts " + cc.Rounds + " rounds: the round it's cast and the next two. Casting again moves it.",
            "- Anyone who starts a move inside pays +" + cc.MoveAPCost + " AP and +" + cc.MoveFatigueCost + " fatigue for every tile of that move. Someone walking in from outside pays nothing on that move, and is slowed from then on.",
            "# Exempt",
            "- The caster, and anyone with Chaos Protection: neither screamed at nor slowed.",
            "- Only Chaos Matters and Iron Mind shake off the scream, but are still slowed."
        ]});
        chapters.push({ Title = "Leader Duels", Lines = [
            "Not tied to Chaos Mind. When you engage a hostile party that has a leader, he may step forward and challenge one of your men. Each party challenges at most once.",
            "- His buff for the duel only: +20% to every combat stat for each 300 armor his whole party wears, up to +300%.",
            "- Chance of a challenge: 49% plus half his buff, up to 95%.",
            "- Pick one of up to 5 duelists (the Chaos Mind wielder first), or refuse for a normal battle.",
            "- Win: the leader is gone and his men start the battle Breaking.",
            "- Lose: his men start the battle Confident."
        ]});
        chapters.push({ Title = "Hotkeys", Lines = [
            "All of them can be changed in Mod Settings.",
            "- " + ::ChaosMind.getGuideKey() + ": open or close this guide, on the world map or in battle.",
            "- " + ::ChaosMind.getLocateKey() + ": which way The Frozen Eye lies, on the world map, until the sword is claimed. Afterwards, where the Black Skull's marked party is while you hunt it."
        ]});

        return chapters;
    }
};


// Gives the guide to companies that owned Chaos Mind before it existed.
::ChaosMind.addWorldCheck("Chaos Guide check", function()
{
    ::ChaosMind.Guide.check();
});


// Ctrl+G on the world map and in battle: read the guide. Rebindable in Mod Settings.
::ChaosMind.Mod.Keybinds.addSQKeybind(
    ::ChaosMind.Guide.KeybindID,
    "ctrl+g",
    ::MSU.Key.State.World | ::MSU.Key.State.Tactical,
    function()
    {
        return ::ChaosMind.Guide.toggle();
    },
    "Open the Chaos Guide"
);


::ChaosMind.Guide.Screen = ::new("scripts/mods/chaos_mind/guide_screen");
::MSU.UI.registerConnection(::ChaosMind.Guide.Screen);
::Hooks.registerJS("ui/mods/chaos_mind/guide.js");
::Hooks.registerCSS("ui/mods/chaos_mind/guide.css");
