# Chroma Sort (working title) — Design Notes

## What this is

A low-graphics color-sort/collection puzzle game (in the vein of the "water
sort" / "collect the color" genre), built to prove that a small, honest,
well-made puzzle game can make real money without resorting to the
dark-pattern, ad-farm playbook that dominates the App Store right now.

## Core monetization principle

> Monetization only ever removes friction the player has already earned
> the right to skip. It never removes challenge or waiting the player
> hasn't earned past.

Inspired directly by *Antimatter Dimensions*, where the ad button is framed
explicitly as "support the developer" and grants things that make the game
**simpler**, never **easier** or **faster**:

- **Easier** = reduces actual challenge → off the table. Never sell a hint
  that solves part of the puzzle for the player.
- **Faster** = skips time/pacing → off the table. Never sell a timer skip.
- **Simpler** = removes tedium/friction around a decision the player has
  *already effectively made* → this is the only category we monetize.

### Concrete examples (simpler — allowed)

- Auto-play the remaining moves once the player has deduced the winning
  sequence, instead of making them tap through 15 known moves by hand.
- One-tap replay of an already 3-starred level for a repeat reward, instead
  of forcing a manual re-solve of something already mastered.
- Skip confirmation dialogs / end-of-level tap-throughs.
- Cosmetic-only content: palettes, themes, sound packs, container skins.
  Doesn't touch mechanics at all — pure "I like this, take my money."

### Concrete anti-examples (easier/faster — never do this)

- Hints that reveal or perform part of an *unsolved* puzzle.
- Extra moves/undos beyond a fair baseline that let you brute-force past a
  puzzle you haven't actually solved.
- Any timer, energy system, or "wait N hours or pay" mechanic.
- Interstitial ads, forced rewarded-video walls, or nagging.

### Framing

Any ad or purchase prompt should read like Antimatter Dimensions' — plainly
labeled as supporting the developer, no urgency/FOMO language, no countdown
pressure, always skippable with zero gameplay penalty for skipping.

## Game concept (draft — refine as we build)

- Genre: 2D color-sort/collection puzzle. Core mechanic is a Loop Sort–
  style truck/conveyor loop, specified in [`CORE_LOOP.md`](CORE_LOOP.md).
- Visual style: deliberately simple/minimal — this is a strength (fast to
  build, fast to load, easy to theme with cosmetic packs later), not a
  compromise.
- Art: programmer art for now (primitive shapes/colors); real art or
  purchased assets can swap in later without touching logic.

## Tech stack

- **Engine:** Godot 4.7 (GDScript)
  - Free, MIT-licensed, no revenue share, no per-seat/runtime fees.
  - Strong native 2D toolset; exports to both iOS and Android from one
    project.
- **Platforms:** Android first (fast iteration, no Mac required), then iOS
  once the core loop and monetization hooks are validated.
  - iOS export requires a Mac + Xcode + Apple Developer Program ($99/yr).
  - Android requires a one-time $25 Google Play Developer fee.

## Open questions / next decisions

- [x] Exact puzzle mechanic and win condition — core loop specified in
      [`CORE_LOOP.md`](CORE_LOOP.md). Still open: level generation vs.
      hand-authored levels, and how many trucks/colors per level.
- [ ] Level progression structure (linear, world map, daily puzzle, etc.)
- [ ] What the "simpler" convenience purchases look like concretely in v1
- [ ] Visual identity beyond programmer art placeholders
- [ ] Final game name
