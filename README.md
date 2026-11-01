<p align="center">
  <img src="gfx/ui/items/weapons/legendary/chaos_mind.png" height="160" alt="Chaos Mind">
  &nbsp;&nbsp;
  <img src="gfx/ui/items/weapons/legendary/chaos_mind_500.png" height="160" alt="Chaos Mind, gorged form">
</p>

<h1 align="center">Chaos Weapon Mod</h1>

<p align="center">
  A <b>Battle Brothers</b> mod (game version 1.5.0.14) built around <b>Chaos Mind</b>, a legendary two-handed sword<br>
  that grows stronger with every life it takes, friend or foe.
</p>

<p align="center">
  <a href="../../releases/latest"><b>Download the latest release</b></a> ·
  In game the mod registers as <b>Chaos Mind</b> (<code>mod_chaos_mind</code>)
</p>

---

## Contents

- [Installing](#installing)
- [Abilities at a glance](#abilities-at-a-glance)
- [The Frozen Eye](#the-frozen-eye)
- [Chaos Mind](#chaos-mind)
- [Carnal Storage](#carnal-storage)
- [Brother and Mass Sacrifice](#brother-and-mass-sacrifice)
- [Soul Arrow](#soul-arrow)
- [Armor Fixer](#armor-fixer)
- [Perks](#perks)
- [The Black Skull](#the-black-skull)
- [Leader duels](#leader-duels)
- [Chaos Guide](#chaos-guide)
- [Hotkeys](#hotkeys)
- [Status](#status)

## Installing

**Requires:**
- [Modding Standards & Utilities (MSU)](https://www.nexusmods.com/battlebrothers/mods/479) 1.2.0 or later
- [Modern Hooks](https://www.nexusmods.com/battlebrothers/mods/685)

**Steps:**
1. Download `mod_chaos_mind.zip` from the [latest release](../../releases/latest).
2. Put it in the game's `data` folder, next to MSU and Modern Hooks.

To build the zip yourself, zip the folders `brushes`, `chaos_mind`, `gfx`, `scripts` and `ui` so that they sit at the top level of the zip.

> [!WARNING]
> Removing the mod breaks any save that contains the sword, The Frozen Eye, the Soul Arrow, an Armor Fixer or the Chaos Guide.

## Abilities at a glance

| | Name | What it is | Cost |
|:-:|---|---|---|
| <img src="gfx/skills/chaos_mind/carnal_storage.png" width="48"> | **Carnal Storage** | Trade fatigue, blood or flesh for energy; spend energy on damage | 0 AP |
| <img src="gfx/skills/chaos_mind/brother_sacrifice.png" width="48"> | **Brother Sacrifice** | Kill one adjacent brother for energy and a blade kill | 4 AP, 10 fatigue |
| <img src="gfx/skills/chaos_mind/mass_sacrifice.png" width="48"> | **Mass Sacrifice** | Kill every adjacent brother | 6 AP, 25 fatigue |
| <img src="gfx/skills/chaos_mind/soul_arrow.png" width="48"> | **Soul Arrow** | +3 AP this turn, once per battle | 0 AP, 20 fatigue |
| <img src="gfx/skills/chaos_mind/armor_fixer.png" width="48"> | **Use Armor Fixer** | Repairs up to 50 armor, single use | 3 AP |
| <img src="gfx/skills/chaos_mind/fatigue_transfer.png" width="48"> | **Fatigue Transfer** | Push all your fatigue onto an adjacent enemy | 1 AP, every 3 turns |
| <img src="gfx/skills/chaos_mind/chaos_circle.png" width="48"> | **Chaos Circle** | A Geist's scream on 7 tiles, sharpened by your Resolve | 6 AP, 30 fatigue, every 3 turns |

| | Perk | Tier |
|:-:|---|:-:|
| <img src="gfx/skills/chaos_mind/chaos_protection.png" width="48"> | **Chaos Protection** | 1 |
| <img src="gfx/skills/chaos_mind/only_chaos_matters.png" width="48"> | **Only Chaos Matters** | 3 |
| <img src="gfx/skills/chaos_mind/used_to_it_perk.png" width="48"> | **Used to It** | 4 |
| <img src="gfx/skills/chaos_mind/chaos_armor.png" width="48"> | **Chaos Armor** | 5 |
| <img src="gfx/skills/chaos_mind/fatigue_transfer_perk.png" width="48"> | **Fatigue Transfer** | 6 |
| <img src="gfx/skills/chaos_mind/chaos_circle_perk.png" width="48"> | **Chaos Circle** | 7 |

| | Item | Slot |
|:-:|---|---|
| <img src="gfx/ui/items/weapons/legendary/chaos_mind_70x70.png" width="56"> | **Chaos Mind** | Two-handed weapon |
| <img src="gfx/ui/items/ammo/soul_arrow.png" width="56"> | **Soul Arrow** | Quiver |
| <img src="gfx/ui/items/misc/armor_fixer.png" width="56"> | **Armor Fixer** | Bag |
| <img src="gfx/ui/items/misc/chaos_guide.png" width="56"> | **Chaos Guide** | Stash only |

## The Frozen Eye

<img src="docs/images/sprite_world_chaos_mind_altar.png" width="260" align="right" alt="The Frozen Eye on the world map">

Chaos Mind is buried point-first in a mound of snow far in the frozen north. There is one per campaign, on snow or snowy forest, at least 6 tiles from any settlement.

**Ctrl+F** on the world map shows which way it lies and how far away it is.

The eye demands **eight lives**:
- You choose the eight brothers yourself, in a window that unlocks **Offer them** at exactly eight.
- You need at least eight eligible brothers, plus one who stays. Your player character can never be offered.
- If the stash is full, nothing happens and nobody dies.
- The sword starts with **8 kills**, one for each life. The Chaos Guide comes with it.

```mermaid
flowchart LR
    A[Find The Frozen Eye<br/>Ctrl+F] --> B{Offer eight<br/>brothers?}
    B -- Not now --> A
    B -- Offer them --> C[Chaos Mind<br/>with 8 kills]
    C --> D[Chaos Guide<br/>in the stash]
```

<br clear="right">

## Chaos Mind

<p>
  <img src="docs/images/sprite_icon_chaos_mind_01.png" height="110" alt="Chaos Mind in hand">
  <img src="docs/images/sprite_icon_chaos_mind_01_bloodied.png" height="110" alt="Chaos Mind in hand, bloodied">
  &nbsp;&nbsp;→&nbsp;&nbsp;
  <img src="docs/images/sprite_icon_chaos_mind_500.png" height="110" alt="Gorged form in hand">
  <img src="docs/images/sprite_icon_chaos_mind_500_bloodied.png" height="110" alt="Gorged form in hand, bloodied">
</p>

A legendary greatsword (Overhead Strike, Split, Swing) with **100–120** base damage.

**Damage:**
- **+0.5% per point of Melee Skill**, or **+1%** with the Chaos Armor perk.
- **+1% for every 10 kills**, with no cap.

Every hit also does the following:

<img src="docs/images/concept_black_cloud_curse.svg" alt="Black cloud: 50% one tile from the target, 25% two tiles away. Curse: 200% to allies within 2 tiles of you.">

Every death the blade causes counts as a kill, brothers included. As kills pile up:

<img src="docs/images/concept_kill_milestones.svg" alt="Kill milestones: 8 claimed, 100 Devourer, 200 Black Skull II, 350 champion cap, 500 gorged form">

- **Draws champions:** at the start of each battle the wielder fights in, every enemy that can be a champion rolls an extra chance to become one.
- **100 kills:** the blade awakens as **Chaos Mind, the Devourer** and gives the company the Soul Arrow.
- **500 kills, the gorged form:**
  - The sword gets a new look.
  - Every kill improves the wielder's mood.
  - After a sacrifice, he turns Confident.

## Carnal Storage

<img src="gfx/skills/chaos_mind/carnal_storage.png" width="56" align="left">

The wielder feeds the eye with his own body, stores the energy, and spends it on damage until the battle ends. Energy and bonuses are lost after every battle.

<br clear="left">

```mermaid
flowchart LR
    F[Fatigue<br/>12 = 1 energy] --> E((Energy))
    B[Blood<br/>4 HP = 1 energy] --> E
    L[Flesh<br/>1 minor injury = 20] --> E
    K[Enemies the blade kills<br/>HP lost / 4] --> E
    S[Sacrificed brothers<br/>all their HP / 4] --> E
    E -- 20 energy --> U[Unleash<br/>+25% damage, up to 3x]
    U -- fully unleashed --> O[Overflow<br/>every 150 energy: +1% damage]
```

## Brother and Mass Sacrifice

<img src="docs/images/concept_sacrifices.svg" alt="Brother Sacrifice kills one adjacent brother; Mass Sacrifice kills every adjacent brother except Chaos Protection holders">

## Soul Arrow

<img src="gfx/ui/items/ammo/soul_arrow.png" width="70" align="left">
<img src="gfx/ui/items/ammo/soul_arrow_empty.png" width="70" align="left">

The Devourer's gift when any of the company's Chaos Mind blades reaches **100 kills**, once per campaign.

<br clear="left">

- **Slot:** the quiver, but it holds no arrows, so a bow can't shoot with it.
- **Use:** once per battle, **+3 AP** this turn, even at full AP. Costs 20 fatigue.
- **Recharge:** after a battle it takes **15 ammo** from the company's supplies. With less than that, it stays empty until a later battle.

## Armor Fixer

<img src="gfx/ui/items/misc/armor_fixer.png" width="70" align="left">

A field repair kit; every armorer, north and south, stocks up to 3. Carry it in a bag slot. Using it costs 3 AP and repairs up to **50 armor**, body first, then the helmet. It's greyed out when there's nothing to repair.

<br clear="left">

## Perks

| | Perk | Effect |
|:-:|---|---|
| <img src="gfx/skills/chaos_mind/chaos_protection.png" width="48"> | **Chaos Protection** (tier 1) | Immune to the black cloud and the curse. Can't be sacrificed. Never flees from sacrifice terror. Untouched by Chaos Circle. **−20 Resolve.** |
| <img src="gfx/skills/chaos_mind/only_chaos_matters.png" width="48"> | **Only Chaos Matters** (tier 3) | Immune to Hexe charm and Geist screams. No morale loss when allies die. Never flees from sacrifice terror. Other brothers can't raise his morale, and they come to hate him: mood drops after each sacrifice, after each battle and every day. |
| <img src="gfx/skills/chaos_mind/used_to_it_perk.png" width="48"> | **Used to It** (tier 4) | Every attack that misses him gives +1 Melee and Ranged Defense until the battle ends, up to +10. Dodging costs no fatigue. |
| <img src="gfx/skills/chaos_mind/chaos_armor.png" width="48"> | **Chaos Armor** (tier 5) | While wielding Chaos Mind: +1 Melee and Ranged Defense per +1% damage from kills, no cap. Melee Skill scaling doubles to +1% per point. |
| <img src="gfx/skills/chaos_mind/fatigue_transfer_perk.png" width="48"> | **Fatigue Transfer** (tier 6) | Grants the skill: 1 AP, moves all your fatigue onto an adjacent enemy (up to his maximum). Once every 3 turns. |
| <img src="gfx/skills/chaos_mind/chaos_circle_perk.png" width="48"> | **Chaos Circle** (tier 7) | Grants the skill below, usable only with Chaos Mind in hand. |

<img src="docs/images/concept_chaos_circle.svg" alt="Chaos Circle: 7 tiles, centre feels the full Resolve gap, the ring half of it">

## The Black Skull

A three-part hunt that opens as the blade feeds: **100**, **200** and **500** kills, in order.

```mermaid
flowchart TD
    A[Blade reaches 100 / 200 / 500 kills] --> B[Enter any town]
    B --> C{The Black Skull}
    C -- Not now --> D[Offered again tomorrow]
    D --> B
    C -- Hunt them --> E[Marked party spawns 5–9 tiles away<br/>black skull banner, ring on the map<br/>led by a champion]
    E --> F[Ctrl+F shows where it is]
    F --> G{Did Chaos Mind<br/>kill the leader?}
    G -- yes, party destroyed --> H[Part done:<br/>more max fatigue]
    G -- no, party gone anyway --> D
```

| Part | Kills | Enemy | Reward rate |
|:-:|:-:|---|:-:|
| I | 100 | Black Skull Brigands, led by a brigand champion | 0.1 |
| II | 200 | Black Skull Reavers, led by a barbarian champion | 0.25 |
| III | 500 | Black Skull Warband, led by an orc warlord champion | 0.5 |

**Reward:** while wielding Chaos Mind, the brother gets **extra max fatigue equal to the rate × the blade's damage bonus from kills**, rounded down. It keeps growing as the blade kills.

<img src="docs/images/concept_black_skull_reward.svg" alt="Extra max fatigue against blade kills after each part">

## Leader duels

Not tied to Chaos Mind. When you engage a hostile party that has a leader, he may step out and demand single combat. Each party asks at most once.

```mermaid
flowchart TD
    A[Engage a party with a leader] --> B{Challenge?<br/>49% + half his buff, max 95%}
    B -- no --> N[Normal battle]
    B -- yes --> C[His buff: +20% to every combat stat<br/>per 300 armor his party wears, max +300%]
    C --> D{Pick a duelist<br/>or refuse}
    D -- Refuse --> N
    D -- One of up to 5 brothers --> E[1 vs 1 duel]
    E -- Won --> W[Leader gone,<br/>his men start Breaking]
    E -- Lost --> L[His men start Confident]
```

## Chaos Guide

<img src="gfx/ui/items/misc/chaos_guide.png" width="70" align="left">

A book with the full explanation of every item, skill and perk above, so the tooltips can stay short. It's given with the sword. If it's ever lost or sold, Chaos Mind's next kill puts it back in the stash. Open it with **Ctrl+G** on the world map or in battle, or right-click it in the stash.

<br clear="left">

## Hotkeys

| Key | Where | What |
|---|---|---|
| **Ctrl+F** | World map | Where The Frozen Eye is; once the sword is claimed, where the Black Skull's marked party is |
| **Ctrl+G** | World map, battle | Open or close the Chaos Guide |

All of them can be changed in Mod Settings.

## Status

Built and tested piece by piece. A few features haven't been tried in play yet: the leader duel since its last fix, Chaos Circle's resolve-gap scream, and parts 2 and 3 of the Black Skull. The game's own scripts are encrypted, so some names had to be guessed. Every guessed name is guarded: a wrong one logs a warning in `log.html` instead of crashing.

## Art

The sword, perk and skill icons and the sword's sprites were made from separate source images, which aren't included here. A few icons are recoloured vanilla Battle Brothers art: the Chaos Guide book and the Armor Fixer. The Black Skull's map banner is the game's own. The diagrams in `docs/images` are generated by `docs/make_diagrams.py`.
