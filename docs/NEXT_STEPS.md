# Session Handoff — Chroma Sort (working title)

Use this doc to pick up the project in a fresh conversation. See
[`DESIGN.md`](DESIGN.md) for the full design principles and monetization
philosophy — this file is just "where are we, what's next."

## Why this project exists

Frustration with the current App Store landscape: most mobile games are
built purely as vehicles to force-feed ads, with monetization designed to
manipulate rather than serve the player. This project is an attempt to
build something small and honest that can generate real income "on my
terms" — proving a fair monetization model can still work commercially.

## How we got here (decision trail)

1. Explored cross-platform mobile frameworks broadly (React Native,
   Flutter, Kotlin Multiplatform, .NET MAUI, Skip, etc.) — rejected
   WebView-based options outright, and settled that "real native widgets
   vs. self-rendered engine" was the key axis, but ultimately the whole
   direction changed once the actual goal (games, not general apps) came
   into focus.
2. Landed on: **2D color-sort/collection puzzle game** (think "water sort"
   genre), solo dev, programmer art for now, experienced generalist coder
   but no prior game-dev experience.
3. Picked **Godot 4.7 (GDScript)** as the engine — free/no revenue share
   (unlike Unity's runtime-fee history), strong native 2D support, GDScript
   is easy to pick up for an experienced dev, and — critically — C# mobile
   export (Android/iOS) is still marked *experimental* in Godot 4, which
   ruled it out for this project's actual goal (shipping to mobile).
4. Defined the core monetization pillar (see `DESIGN.md`): monetization
   may only remove **friction already earned**, never **challenge** or
   **time**, directly modeled on Antimatter Dimensions' "support the dev"
   ad framing.
5. Scaffolded the project folder (this one) with `project.godot`,
   `.gitignore`, folder structure (`scenes/`, `scripts/`, `assets/`,
   `addons/`), README, and `DESIGN.md`.
6. Got Godot actually running locally — hit a chain of macOS/Apple Silicon
   issues (Gatekeeper quarantine, unsigned binary blocked by AMFI on
   arm64, and finally a corrupted extraction of the 4.7.2 zip specifically).
   Resolved by grabbing **Godot 4.7.1** instead, which opened cleanly.
   Leftover zips in `~/Downloads` (4.7.1 and the bad 4.7.2) can be deleted
   whenever — harmless, not cleaned up yet.

## Current state

- [x] Project folder created at `/Users/lmckechn/projects/color-sort-puzzle`
      with git initialized (nothing committed yet — no commits made so far,
      by design, since commits are only made when explicitly requested).
- [x] `project.godot` configured: mobile renderer, portrait orientation,
      working title "Chroma Sort".
- [x] Design principles documented in `DESIGN.md`.
- [x] Godot 4.7.1 installed and confirmed working on this Mac.
- [ ] Project has **not** been opened in the Godot editor yet by the time
      of this handoff.
- [ ] No actual game code/scenes exist yet. `run/main_scene` in
      `project.godot` points to `res://scenes/main/main.tscn`, which does
      not exist yet — expect a "missing main scene" prompt on first open.

## Next steps, in order

1. Open the Godot editor → **Import** →
   `/Users/lmckechn/projects/color-sort-puzzle` (the folder with
   `project.godot` in it).
2. Build the **core puzzle data model first, decoupled from visuals**:
   - Represent the grid/containers and colors as plain GDScript data
     (arrays/classes), not nodes yet.
   - Implement move validation and win-condition checking as pure logic
     that can be tested headlessly (e.g. via a script run from the
     editor's script tab, or GUT/other testing approach) before any
     rendering exists.
   - Goal: prove the puzzle mechanic is actually solvable and fun before
     investing in visuals or input handling.
3. Once the core loop is validated, build the actual scene: grid
   rendering, container/color visuals (programmer-art shapes), and touch
   input for moves.
4. Only after the loop is fun: revisit the open questions in `DESIGN.md`
   (exact move rules, level progression/generation, concrete v1
   monetization hooks, visual identity, final name).

## Open decisions not yet made

See the "Open questions / next decisions" section at the bottom of
`DESIGN.md` — nothing there has been decided yet as of this handoff.
