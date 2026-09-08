# Level Select and Completions

UI around the core loop. Does not change puzzle rules. Completions
are **display-only** in this step: the selector and playfield read a
map the caller already has. A win does not write a new completion.

---

## LevelData identity

`LevelData` carries optional `id` and `title`. Empty values are valid
for the puzzle. The selector matches `id` to the user’s completion
map. Shipped tutorials use `tut1` / `tut2` / `tut3` / `tut4`.

---

## LevelCompletion

One recorded successful play of a level. Fields (no others yet):

| Field | Meaning |
| --- | --- |
| `ttc` | Time to complete, seconds (float). |
| `taps` | Accepted taps in that play. |
| `max_conveyor_load` | Peak `in_transit_count` during that play. |

`summary_line()` is the shared display string:
`{ttc}s · {taps} taps · peak {max_conveyor_load}` with `ttc` to one
decimal.

---

## LevelRunResult

One completed play attempt, whether it ends in a win or a loss. This is a
standalone immutable model, outside both Playfield and LevelSelect. It is
not a saved completion.

Its initial shape is:

| Field | Meaning |
| --- | --- |
| `level_id` | The stable id of the level played. |
| `outcome` | `LevelRunResult.Outcome.WON` or `.LOST`. This enum belongs to the result model; it does not reuse `Level.Status`. |
| `ttc` | Elapsed attempt time in seconds (float). |
| `taps` | Accepted taps in the attempt. |
| `max_conveyor_load` | Peak `in_transit_count` in the attempt. |

`LevelCompletion` remains win-only. Later, the owner that receives a winning
`LevelRunResult` may choose to create or update a `LevelCompletion`; Playfield
does not record it.

---

## User

Caller-owned. Holds `completions`: `level_id` → `LevelCompletion`.
`completion_for(id)` returns the object or `null` (unknown id, empty
id, or missing map entry). This is not persistence and does not own
`PuzzleSession`s.

---

## Main-owned level sets

`Main` is the only owner of shipped level sets. It supplies two packs:

- `tutorial_levels()` for the **Tutorial** button;
- `play_levels()` for the **Play** button.

Every `LevelData` in either pack must have a non-empty, unique `id`, pass
`validation_error()`, and create a playable `Level`. The pack lint runs with
the GUT suite and rejects duplicate ids, invalid data, and data that cannot
create a `Level`.

The shipped tutorial pack currently uses these authored transit capacities.
Their visual belt-position counts remain derived by the core-loop rule:

| Level | `conveyor_capacity` | Derived `belt_position_count` |
| --- | ---: | ---: |
| Tutorial 1 | 5 | 6 |
| Tutorial 2 | 6 | 8 |
| Tutorial 3 | 7 | 10 |
| Tutorial 4 | 6 | 10 |

### Tutorial curriculum

Each tutorial should introduce one new decision while relying on the lessons
before it. A lower conveyor capacity is not automatically a harder lesson;
the starting stack order can create or remove useful room.

| Level | Teaches |
| --- | --- |
| Tutorial 1 | The basic loop: tap a mixed truck to unload its top-color run, then let blocks circulate into a truck that can receive them. Two equal five-block color sets keep the destination decision simple. |
| Tutorial 2 | Set size and truck capacity matter. The seven blue blocks ultimately need the seven-slot truck; the two five-slot trucks are the destinations for the other colors. |
| Tutorial 3 | Belt capacity is working space and timing matters. Because every truck starts full, the seven-slot truck must first evacuate seven blocks before it can receive the blue blocks that complete it. This establishes seven as the tight playable transit capacity for this layout. |
| Tutorial 4 | An anchored destination changes the required working space. The seven-slot truck starts with blue at its bottom and two blue blocks above it. After it unloads its upper six blocks, its retained blue anchor lets the circulating blues return, so six transit slots suffice. |

Tutorial 4 uses the same five red, five yellow, five green, and seven blue
blocks as Tutorial 3. Its stacks are bottom → top:

| Truck capacity | Starting stack |
| ---: | --- |
| 5 | red, yellow, green, red, green |
| 5 | green, yellow, blue, yellow, blue |
| 5 | green, blue, yellow, red, blue |
| 7 | blue, red, blue, green, blue, red, yellow |

`LevelSelect` does not define a fallback level list. It only displays the
pack passed by `Main`, so a level registered in either Main-owned pack is
automatically selectable and playable. An empty pack is valid and displays
an empty selector until levels are added to it.

## Selected-level lifecycle

LevelSelect retains its Main-supplied pack and its selected index for the
entire selected-level lifecycle. Selecting a tile does **not** replace the
LevelSelect scene. Instead, LevelSelect creates an active Playfield child
for that one `LevelData` and retains the ordered pack behind it.

Playfield has no knowledge of successor levels. When its current level first
reaches a terminal status, it emits exactly one terminal-result signal to its
parent, carrying a `LevelRunResult` for either outcome. LevelSelect does not
query Playfield for post-run state. It receives that result, owns one result
modal as an overlay child, and configures its outcome text and one action from
its own pack and selected index. This preserves every later level in the pack
across any number of Next transitions.

The signal is `run_finished(result: LevelRunResult)`. It emits at most once
per active Playfield.

On either outcome, LevelSelect displays that single result modal:

| Outcome | Modal text | Action | Action behavior |
| --- | --- | --- | --- |
| `WON` | `You won!` | **Next Level** | Enabled only when the retained pack has an entry after the selected index. Pressing it replaces the active Playfield child with that next entry. At the end of a pack, the action is unavailable. |
| `LOST` | `You lost!` | **Retry** | Enabled. Pressing it replaces the active Playfield child with the currently selected entry. |

The modal also always provides **Back**. Pressing it hides the modal, removes
the active Playfield child, and returns to the level tiles. This is distinct
from the selector's own **Back** button, which returns to Main.

The modal is hidden whenever LevelSelect launches or replaces its active
Playfield child.

## LevelSelect

A full-screen scene, launched the same way as the playfield. Main's
**Tutorial** and **Play** buttons call `LevelSelect.launch(tree, levels, user)`
with their respective owned packs. The scene is not instanced into Main.

**Input:** `launch` stores the list and user, then changes scene.
`configure(levels, user)` builds the tiles (`user` may be `null`).

**Layout:** levels are packed into rows of **5 squares**. Each filled
square shows its 1-based index in the pack. A green check sits **on
the square** when `user.completion_for(level.id)` is non-null. The
bottom of the square is reserved for a later star row from the same
completion object — do not invent stars yet. Empty slots in a short
row are present and not playable. A completed square is still
playable (replay); the completion is passed through as the target.

**Output:** signal `level_selected(data, target)` where `target` is
that level’s `LevelCompletion` or `null`.

**Invalid / empty input:** empty `levels` → no rows. Completions
whose ids are not in `levels` are ignored. Configure again replaces
the previous tiles.

---

## Playfield extras

- Occupancy label: `{in_transit_count}/{conveyor_capacity}`, updated after
  tap and each advance. This is cubes on the belt vs the authored transit
  cap, not the derived belt-position count.
- If launched with a `target` completion, show
  `Target: {summary_line()}` so the player can aim at a prior run.
- LevelSelect supplies the current level’s completion target when it creates
  a Playfield child. Playfield does not receive any next-level data.
- Selector **Back** returns to Main. The single result modal and its action
  are owned by LevelSelect, not Playfield.
