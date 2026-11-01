# Chaos Weapon Mod

A Battle Brothers mod (game version 1.5.0.14) built around **Chaos Mind**, a legendary two-handed sword that grows stronger with every life it takes, friend or foe.

In game the mod registers as **Chaos Mind** (`mod_chaos_mind`).

## Requirements

- [Modding Standards & Utilities (MSU)](https://www.nexusmods.com/battlebrothers/mods/479) 1.2.0 or later
- [Modern Hooks](https://www.nexusmods.com/battlebrothers/mods/685)

## Installing

1. Zip the contents of this repository (the folders `brushes`, `chaos_mind`, `gfx`, `scripts` and `ui` at the top level of the zip) as `mod_chaos_mind.zip`.
2. Put the zip in the game's `data` folder, next to MSU and Modern Hooks.

**Removing the mod breaks any save that contains the sword, The Frozen Eye, the Soul Arrow, an Armor Fixer or the Chaos Guide.**

## What's in it

- **The Frozen Eye:** a legendary location on the snow, one per campaign. It gives up Chaos Mind for eight of your brothers' lives. **Ctrl+F** shows where it is.
- **Chaos Mind:**
  - Damage scales with Melee Skill and grows with every kill.
  - Each hit spreads a black cloud to everyone near the target and curses the wielder's nearby allies.
  - It draws champions to its battles.
  - It awakens as the Devourer at 100 kills and changes form at 500.
- **Skills granted by the sword:**
  - **Carnal Storage:** trade fatigue, blood or flesh for energy, and spend it on damage.
  - **Brother Sacrifice** and **Mass Sacrifice:** feed brothers to the blade.
- **Soul Arrow:** the Devourer's gift at 100 kills, carried in the quiver slot. Once per battle it gives +3 AP.
- **Armor Fixer:** a single-use field repair kit, sold by every armorer.
- **Perks:** Chaos Protection, Only Chaos Matters, Used to It, Chaos Armor, Fatigue Transfer and Chaos Circle.
- **The Black Skull:** a three-part hunt that opens at 100, 200 and 500 kills.
  - Each part marks a champion's party near a town.
  - Its leader must die to the blade.
  - Each finished part makes the sword grant its wielder more max fatigue.
- **Leader duels:** a party's leader may challenge one of your men to single combat before a battle.
- **Chaos Guide:** a book that explains all of the above in full. It's given with the sword; open it with **Ctrl+G**.

All hotkeys can be changed in Mod Settings.

## Status

Built and tested piece by piece. Several features haven't been tried in play yet: the leader duel, Chaos Circle's resolve-gap scream, and parts 2 and 3 of the Black Skull. The game's own scripts are encrypted, so some names had to be guessed. Every guessed name is guarded: a wrong one logs a warning in `log.html` instead of crashing.

## Art

The sword, perk and skill icons and the sword's sprites were made from separate source images, which aren't included here. A few icons are recoloured vanilla Battle Brothers art: the Chaos Guide book and the Armor Fixer. The Black Skull's map banner is the game's own.
