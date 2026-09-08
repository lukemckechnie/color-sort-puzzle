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
7. Specified and implemented the Loop Sort–style core loop in
   [`CORE_LOOP.md`](CORE_LOOP.md), with GUT as the test runner.
8. Built the programmer-art Playfield, two tutorial levels, title menu,
   tutorial level selector, completion display model, and tests.
9. Documented the current tap path in [`TAP_FLOW.md`](TAP_FLOW.md).
   Reviewing that flow exposed a mismatch between the implemented process
   ownership and the intended domain boundaries; the redesign below has
   been discussed but is not implemented yet.
10. Defined a platform/account direction for future mobile persistence:
    Firebase-backed cloud saves with an internal Firebase UID as the
    canonical player identity, optional Google Play Games and Apple Game
    Center integrations, and a portable support/save-code flow. This is a
    product direction only; no backend or platform integration has been
    implemented yet.

## Current state

- [x] Project folder created; git has commits (only when explicitly
      requested).
- [x] `project.godot` configured: mobile renderer, portrait orientation,
      working title "Chroma Sort".
- [x] Design principles documented in `DESIGN.md`.
- [x] Godot 4.7.1 installed and confirmed working on this Mac.
- [x] Project has been opened in the Godot editor (`.godot/` cache exists).
- [x] Core-loop behavior specified in [`CORE_LOOP.md`](CORE_LOOP.md).
- [x] GUT installed and the current full suite passes: **52 tests**.
- [x] Core puzzle model implemented under `scripts/puzzle/`.
- [x] Main scene and reusable Playfield scene implemented.
- [x] Tutorials 1 through 4 are data-defined levels using the same
      Playfield; the obsolete Tut1 launcher scene has been removed.
- [x] Tutorial level selector implemented as its own full-screen scene,
      launched by the Main scene's **Tutorial** button.
- [x] Selector presents levels as numbered squares in rows of five,
      including a completion check on the square and space reserved for
      future stars.
- [x] `LevelData` has stable `id` and display `title`.
- [x] `User.completions` maps a level id to `LevelCompletion`.
- [x] `LevelCompletion` currently contains time to complete, accepted tap
      count, and peak conveyor load. Completions are display-only; winning
      does not record one yet.
- [x] Playfield displays current conveyor occupancy as
      `{in_transit_count}/{conveyor_capacity}` and can display a previous
      completion as a target.
- [x] A packed conveyor ring rotates rather than freezing.
- [ ] Current tap/process ownership still follows the implementation
      recorded in [`TAP_FLOW.md`](TAP_FLOW.md), not the intended ownership
      described below.
- [ ] `PuzzleSession.history()` event schema is not specified. Do not
      invent one.

## Known bug: Next discards the remaining level sequence

**Reproduction:** launch the tutorial selector, start level 1, finish it,
and press **Next Level**. Finish level 2.

**Expected:** level 2 offers level 3 as its next level.

**Actual:** level 2 has no next level. In `Playfield._on_next_level()`, the
launch of level 2 explicitly passes `null` for `next_data` and `""` for
`next_title`, replacing the level 1 → level 2 → level 3 sequence with only
level 2.

**Impact:** Next Level works for a single transition only; later levels in
the selected pack cannot be reached through the win flow.

**Current reproduction test:**
`test_two_wins_advance_through_the_retained_three_level_pack` in
[`test/unit/test_level_select.gd`](../test/unit/test_level_select.gd). It
models the retained three-level pack and proves that two successive wins can
launch level 3.

### Agreed remediation

Do not carry a successor or remaining sequence through Playfield. Instead:

1. `Main` continues to own and supply the selected tutorial or play pack.
2. `LevelSelect` remains the active scene after a level is selected and
   retains that ordered pack and the selected index.
3. `LevelSelect` creates the active Playfield as a child rather than asking
   Playfield to replace the scene.
4. Playfield receives only the current level’s data and emits exactly one
   terminal-result signal when the level is won or lost. Its payload is an
   immutable `LevelRunResult`, including the result model’s own `WON`/`LOST`
   outcome, level id, elapsed time, accepted taps, and peak conveyor load.
5. `LevelSelect` owns one result modal as an overlay child and handles its
   action. It uses its retained pack/index to choose a retry or the next
   level.

On a win, the modal says `You won!` and its **Next Level** action is enabled
only when a later entry exists in the retained pack; pressing it opens that
entry. On a loss, the same modal says `You lost!` and its action becomes
**Retry**, which opens the current entry again. The modal hides when a new
Playfield is launched. In either outcome, **Back** closes the modal, removes
the active Playfield child, and returns to the level tiles. At the end of a
pack, **Next Level** remains unavailable.

The signal is `run_finished(result: LevelRunResult)`. Tests must prove that
LevelSelect receives both outcomes and configures this single modal correctly.

## Next steps, in order

0. Resolve [Known bug: Next discards the remaining level sequence](#known-bug-next-discards-the-remaining-level-sequence).
1. Update `CORE_LOOP.md` and `TAP_FLOW.md` to specify the intended process
   ownership before changing implementation.
2. Refactor the remaining domain model and tests to match that ownership:
   - `Block` owns its `Color` reference only. `Block.Color.SetSize` is the
     authoritative set size. Remove the separate runtime `set_sizes`
     dictionary.
   - `Conveyor` owns the slot-to-block mapping and therefore all
     in-transit positions.
   - `Conveyor` owns truck placement around the track.
   - The authored `slot_count` has been replaced with derived
     `belt_position_count = max((truck_count * 2) + 2, conveyor_capacity)`.
     `conveyor_capacity` is the only authored gameplay transit limit.
   - Validate that each starting truck is either empty or contains at
     least two distinct colors. Starting stacks may be partially filled.
   - For truck `T`, `TO(T)` is its offer/loading position.
   - `TE(T)` is the next derived belt position after `TO(T)`, wrapping at
     `belt_position_count`.
   - `Conveyor.advance()` moves the belt. Blocks do not ask whether they
     can advance.
   - Belt advancement pauses while a truck unload is being processed.
   - `Level.tap(T)` is the domain command boundary and delegates to
     `Conveyor.attempt_unload_at(T)`.
   - `Conveyor.attempt_unload_at(T)` calculates remaining belt capacity,
     asks the truck for its unloadable top-color run, receives the block
     references, and inserts them at `TE(T)`, pushing forward as needed.
   - When a block reaches `TO(T)`, Conveyor offers it to the truck.
   - Truck owns its stack and acceptance/completion rules, but has no
     reference back to Conveyor.
   - Conveyor owns belt mechanics but does not duplicate Truck's
     acceptance or completion rules.
3. Settle the remaining post-advance lifecycle wiring: Playfield schedules
   ticks and Conveyor owns advancement, but the exact return/event path by
   which Level updates win/loss has not yet been finalized.
4. Re-run and update solver/replay tooling after the ownership refactor.
5. Continue playtesting before recording or persisting completions.
6. Only after the loop is fun, revisit the remaining questions in
   `DESIGN.md`: level generation/progression, v1 monetization hooks,
   visual identity, and final name.
7. Design and implement the account and persistence layer described in
   [Account, cloud-save, and support-code direction](#account-cloud-save-and-support-code-direction).

## Backlog

- **Make the entire truck the tap hitbox.** Remove the visible physical
  **Tap** button from each truck. Playfield should translate a click or
  touch anywhere on the truck presentation into `Level.tap(T)`. Keep
  graphical hit detection in Playfield; do not move pixels, Controls, or
  input events into the domain model. Add pressed/hover feedback and
  preserve keyboard/focus accessibility when this is implemented.
- Record a `LevelCompletion` when a level is won.
- Define how a new completion is compared with an existing completion
  before overwriting or retaining it.
- Add stars to `LevelCompletion` and render them in the space already
  reserved on each level square.
- Persist `User.completions` across application launches.

## Open decisions not yet made

See `DESIGN.md` for remaining product questions.

- The core puzzle behavior is mostly established, but process ownership in
  `CORE_LOOP.md` §8 is being reopened to match the model above.
- Decide how Conveyor reports an advance/receive outcome to Level without
  moving belt mechanics back into Level.
- Decide whether domain outcome notifications use direct return values,
  local Godot signals, or both. No global event bus has been selected.
- Define `PuzzleSession.history()` before implementing it.
- Define completion comparison, recording, and persistence.

## Account, cloud-save, and support-code direction

This is the agreed direction for a later implementation phase, after the
core loop and local completion persistence are stable.

### Identity and platform services

- Maintain an internal player identity as the canonical identity across
  Android and iOS.
- Let a new player start with an anonymous/local account so login is not
  required to play.
- When the player chooses Google sign-in, link the existing anonymous
  account rather than creating a replacement account. The Firebase `uid`
  becomes the stable Player ID for that Firebase project.
- Offer Google Play Games on Android and Apple Game Center on iOS as
  optional platform services for achievements, leaderboards, and related
  platform features. Neither service should gate the core game or replace
  the canonical account.
- Game Center and Play Games identities are platform-specific; the
  internal account remains the cross-platform source of truth.

### Analytics and cloud saves

- Firebase Analytics is for usage events and reporting, not save-game
  storage. It should work for anonymous and non-Google players as well as
  signed-in players.
- Store recoverable progress in a Firebase database service such as
  Firestore or Realtime Database, keyed by the authenticated Firebase UID
  and protected by authentication-aware rules.
- Save locally first so the game remains playable offline, then synchronize
  when an account is available and connectivity returns.
- Define explicit merge/conflict behavior before implementing sync, with
  special attention to anonymous progress being linked into a permanent
  account.
- Do not use email addresses, auth tokens, or provider-specific identifiers
  as the canonical database key.

### Export and troubleshooting

- Provide **Copy Player ID** in Settings. This exposes the Firebase UID as a
  support identifier. It is an opaque identifier, not proof of account
  ownership or an authentication credential.
- Provide **Export Save Code** for manual transfer and troubleshooting.
  This is an encoded save payload, not a one-way cryptographic hash: it
  must contain enough state to be imported again.
- Version the save format and include a checksum so truncated or corrupted
  codes can be diagnosed. A future format can use a structure such as
  `CS1.<compressed-payload>.<checksum>`.
- Keep personal data, email addresses, auth tokens, receipts, and other
  secrets out of exported codes. Treat imported codes as user-editable and
  never trust them for competitive rewards.
- Consider a separate short support token that lets authorized support
  tooling locate a cloud save without asking the player to share the full
  save payload.

### Godot integration caveat

Firebase's official client SDK list does not currently include Godot as a
first-class client target. Before committing to implementation, evaluate a
maintained Godot plugin versus native Android/iOS bridges. Record that
choice, its supported Firebase features, and its failure/offline behavior
before writing the integration.
