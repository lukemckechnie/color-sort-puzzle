# Core Loop — Behavior Spec

This is the step-1 behavior definition for the puzzle data model. It is
logic-only: no scenes, nodes, rendering, or input handling. Visuals later
drive this model; they do not own it.

Reference feel: Loop Sort (Voodoo / Garawell), core loop only. Obstacles
(hidden blocks, curtains, ice, barriers) are out of scope.

---

## 1. What the unit does

A **level session** is a closed loop of **trucks** plus a **conveyor**.
The player taps trucks to unload cubes onto the conveyor. Cubes travel
along the conveyor. When a cube **reaches a truck’s position**, the
conveyor asks that truck whether it can accept the cube. No cube is
assigned a destination when it is loaded. The level is won when every
cube is settled into a finished (pure, full, matching-capacity) truck
or gone. The level is lost when the conveyor is full and no cube on it
can enter any truck.

---

## 2. Entities

### Cube

- Has exactly one **Color** reference. A Color contains its stable
  `CubeColor.Id` and `SetSize`. The logic does not care how the color is
  displayed. `NONE` is not a playable cube; it is the empty-top sentinel.
- Exists in exactly one place at a time: in a truck stack, or in transit
  on the conveyor.

### Color set size

The **set size** of a color `C` is the total number of cubes of color
`C` in the level (every starting stack, counted once at session start).
Cubes are never created or destroyed, so set size is constant.
`Block.Color.SetSize` is the source of truth. Conveyor and Level must not
maintain a second authoritative color-to-size map.

This spec treats each color as **one set**. A color **completes at
most one truck**. A truck **accepts** a color that passes the receive
rule (§5). It **completes** only when it is full of a single color `C`
**and** `T.capacity == set_size(C)`.

So a 7-cube color may sit in a 5-slot truck (parking / staging). That
truck must not become finished: if it did, two cubes of that color
would be orphaned with no matching-capacity home left to complete.
Those cubes can be tapped back out.

If a later level wants two separate groups of the same hue (e.g. ten
reds into two 5-slot trucks), that needs a new rule. It is not supported
here: ten reds have set size 10 and would only *finish* on a 10-slot
truck.

### Truck

- An ordered **stack** of cubes, bottom → top.
- **Capacity** is a positive integer **on that truck**. Different trucks
  in the same level may have different capacities (e.g. a 5-slot truck
  and a 7-slot truck). The model must not hard-code a global capacity.
- May start mixed. A mixed stack is the normal unsolved state. Starting
  cubes of color `C` may sit in a truck whose capacity ≠ `set_size(C)`;
  they can also be received into a wrong-capacity truck. They just
  cannot *finish* there.
- Is both a **source** (tap unloads from the top) and a **destination**
  (the conveyor may offer it a cube that has reached its position).

A truck is **finished** only when **all** of the following hold:

1. Stack length equals **that truck’s** capacity.
2. Every cube in the stack is the same color `C`.
3. `T.capacity == set_size(C)`.

Clause 3 is the orphan rule: a 5-slot truck full of a 7-cube color is
**not** finished, is **not** locked, and can still be tapped so those
cubes can be excavated. It cannot receive more only because it has no
room — not because of the color.

A truck that is full but mixed is **not** finished: it cannot receive
(no room) but it can still be tapped.

An **empty** truck has no color. It can receive a cube of a color `C`
only if `C` is not **claimed** (see §5). It has nothing to unload.

A truck claims color `C` when it is empty, accepts its first `C` cube,
and `T.capacity == C.SetSize`. The truck stores that claim. Further
received cubes must match its top color, so the claim does not need to
be recomputed after each receive or partial unload. The claim clears when
the truck becomes empty. When the truck becomes full, it evaluates
completion; a completed truck remains the terminal owner of that claim.
A truck whose capacity does not match `C.SetSize` is parking and does not
claim `C`.

### Conveyor

- A closed loop. It derives each truck's offer and exit positions from the
  truck's order in the level — trucks do not own positions.
- Holds zero or more cubes **in transit**, mapping each cube to one derived
  belt position. At most one cube occupies a belt position.
- Has a **maximum in-transit capacity**, defined per level
  (`conveyor_capacity`).
- Does not stop and wait. Cubes keep moving until they enter a truck or
  the level ends. Filling the conveyor does **not** freeze it.
- Owns the “offer” step: when a cube reaches a truck’s position, the
  **conveyor asks the truck** if it can accept that cube. The truck
  answers from its current stack; it does not pull cubes on its own.

### Level (input data)

A level is defined by:

| Field | Meaning |
| --- | --- |
| `id` | Stable string key for catalog / completions. Optional for puzzle validity. |
| `title` | Display name. Optional for puzzle validity. |
| `conveyor_capacity` | Maximum cubes allowed in transit at once. This is the only authored belt-size value. |
| `trucks` | Ordered list of trucks. Each has `capacity` (≥ 1) and a starting `stack` (colors, **bottom first**). A starting stack must be empty or contain at least two distinct colors. |

Truck order is the cyclic order. Every truck must start empty or with at
least two blocks of different colors; a non-empty starting stack does not
have to fill its capacity. No starting stack may exceed that truck’s
`capacity`. No stack may contain `CubeColor.Id.NONE`.
`conveyor_capacity` ≥ 1. The conveyor derives its belt-position count:

```text
belt_position_count = max((truck_count * 2) + 2, conveyor_capacity)
```

This provides a position for every allowed in-transit cube, a position
between adjacent truck offer positions, and two buffer positions around
the visual wrap point. Position count is derived track geometry, not a
second authored capacity. Truck `i` has offer position `1 + (i * 2)`;
its exit position is the next position, wrapping around the derived count.

Validation failure reasons are the `LevelData.ERR_*` constants
(section 7).

---

## 3. Derived positions on the conveyor (not destination assignment)

The conveyor is a **ring of `belt_position_count` discrete positions**
(`0` .. `belt_position_count - 1`). It derives truck offer positions from
truck order. Each in-transit block occupies exactly one conveyor-owned
position; `Block` has no position field. Cubes never reserve a truck.
**At most one block occupies a position, and at most one block reaches a
given truck on a given tick.** There is no separate hop clock — one
advance is +1 position.

**Receive when a block occupies a truck’s offer position.** That occupancy can
come from a granted `advance` step **or** from `load` placing or
pushing a block onto that slot. The conveyor asks that truck whether
it can accept the block. Sitting still after a refuse does not
re-offer every tick; a new arrival does.

**Entry — first out is pushed forward, next steps on behind.** Blocks
leave truck `K` **top first**, onto the slot immediately after `K`
(the entry slot). They do not offer to `K` (they are no longer on
`K`). If another truck sits at the entry slot — or at a slot the
outgoing chain is pushed onto — offer that truck immediately.

1. The first popped block steps onto the entry slot.
2. Each later popped block **pushes that outgoing chain forward one
   slot**, then steps onto the entry slot — immediately **behind** the
   block that just left. Later-popped blocks do **not** spawn further
   down the belt.
3. After a two-block unload, the first popped is one slot **ahead** of
   the second. It will reach every subsequent truck first.

There is no special exclusion for the truck that unloaded a cube. The
cube starts one position after that truck's offer position, so it is not
immediately offered back. If it travels around the full loop and reaches
that truck's offer position again, the truck evaluates it normally and
may accept it.

**Displacement.** Inserting at `K`’s entry can shove blocks that are
already on the belt. Occupants of the entry and of slots the outgoing
chain is pushed into move **forward** with that push. Blocks already
at truck `K`’s slot or on the incoming side (`K-n`) that would overlap
the insertion are **pushed backward** (decreasing position, wrap) so
there is still one block per slot.

**Advance moves simultaneously.** On each tick, every in-transit block
moves one position forward (wrap) as one conveyor operation. A block does
not ask permission and does not wait behind another block that is also
moving that tick. A new position that is a truck offer position is offered
after movement. A packed belt rotates together.

If rejected everywhere, a cube can later come all the way around and
be offered to `K`.

A cube in transit has a color; its position belongs to the conveyor.

Cubes do not merge, match, or clear on the conveyor. The only way off
is a truck accepting an offer **at its slot**.

---

## 4. Inputs (operations)

The session exposes two operations. Nothing else mutates state.

### `tap(truck_index)`

Player choice. Any non-locked truck may be chosen at any time; there is
no turn order.

**Rejected taps** (state unchanged; caller may show feedback):

| Case | Feedback intent |
| --- | --- |
| `truck_index` out of range | Invalid input |
| Truck is finished | Locked; no interaction |
| Truck is empty | Nothing to unload |
| Conveyor is already at `conveyor_capacity` | Cannot load more onto the conveyor |

**Accepted tap:**

1. Read the top cube’s color. Let `run` be the number of contiguous
   cubes of that color from the top down.
2. Let `load = min(run, conveyor_capacity - in_transit_count)`.
3. Pop `load` cubes from the top of the truck, **top first**.
4. `Conveyor.load` them in that order: first onto the entry slot;
   each next pushes the outgoing chain forward one slot and steps on
   behind. No destination is reserved. The source truck is not asked at
   the instant of exit because the cubes are one position beyond its
   offer position. If a loaded or pushed block reaches any truck’s offer
   position—including the source after a full circuit—offer that truck
   (see §3).
5. After the tap, re-check **loss** if any cubes remain in transit
   (see §6). If a receive during this load emptied the belt, re-check
   **win** — that is the receive, not the tap. How a loss is animated
   is out of scope.

Leftover cubes of the same run stay on the truck. Example: top run of
4 reds, 2 free conveyor slots → 2 reds enter transit, 2 reds remain.

A rejected tap (including “conveyor already at max”) does not change
state and does not end the level. A **successful** tap can make the
level lost the instant the loss condition is true. The conveyor still
exists for whatever the scene later wants to show.

### `advance(n)`

Moves the clock forward by `n` integer ticks. Tests pass exact values.
The scene later chooses how often to call this (e.g. once per frame
after accumulating real time, or once per fixed tick).

- `n` is not an integer, or `n <= 0`: invalid input; no movement;
  report an error.
- Each of the `n` ticks: every in-transit block moves one derived belt
  position forward simultaneously.
- The conveyor does not pause when full or between taps. `advance` is
  the only clock that **moves** blocks. Tap-time load may **push**.

**Reach / offer / receive** — when a granted step lands a cube on
truck `T`’s slot:

1. The conveyor asks `T` if it can accept this cube **right now**.
2. **Accepted:** the cube leaves the conveyor and is pushed onto `T`.
   Then re-check **win** (see §6).
3. **Rejected:** the cube stays at that offer position until a later
   simultaneous advance carries it forward.

At most one cube reaches a given truck in one tick. Two blocks from
the same tap sit one slot apart (first popped ahead), so they do not
arrive together.

---

## 5. Receive rule

The conveyor offers a cube of color `C` to truck `T` only when the cube
**reaches `T`’s position**. `T` accepts if and only if **all** of the
following hold **at that instant**:

1. `T` is not finished.
2. `T` has room (`stack length < T.capacity`).
3. Either:
   - `T` is empty **and** no truck currently claims `C`, or
   - `T`’s current **top** cube is color `C`.

Otherwise the truck refuses and the cube continues around the loop.

A claimed `C` may still stack onto a truck whose top is `C`. It must
not be the first cube in an empty truck. That is the only extra check
beyond room / finished / top-match.

There is **no** capacity-vs-set-size check on accept except the claim
rule above. A 5-slot truck may take a 7-cube color (that 5-slot stack
does not claim the 7-cube color). Completing that truck still requires
`capacity == set_size(C)` (see §2). Receive never cares about colors
below the top, other than for the finished check and stored claim state.

---

## 6. Win and loss

**Win** is evaluated after every successful receive only — including a
receive that happens during `load` when the entry (or a pushed-to
slot) is another truck. **Loss** is evaluated after every successful
`tap` only, and only if cubes remain in transit. A receive drops
`in_transit_count` below `conveyor_capacity`, so the loss conjunction
cannot become true until a later tap fills the belt again.

### Win

All of:

- No cubes in transit.
- Every truck is either **empty** or **finished** (including the
  matching-capacity clause in §2).

There must be no partial, mixed, or wrong-capacity-full truck left.
A 5-slot truck sitting full of a 7-cube color is not a win.

### Loss

The conveyor being full is **not** a loss by itself. When it is full:

1. Further taps are rejected with “can’t load more” feedback.
2. The conveyor **keeps running**. Cubes keep moving. The conveyor
   keeps asking trucks when a cube reaches their position.
3. If a truck accepts, the cube exits, `in_transit_count` drops, and
   the player can tap again.

Loss is declared **the instant both are true after a successful tap**.
How that looks on screen is a later animation question; the model does
not wait for a full loop.

- In-transit count equals `conveyor_capacity`.
- **No in-transit cube would be accepted by any truck if it reached
  that truck’s position right now** — same receive rule as §5
  (room, empty-or-top-match, and the claim exception), current stacks.

That second clause is a **capability check**, not an assignment. If
some cube *could* be accepted, do **not** fail — keep running until a
cube actually reaches that truck and is accepted. After it is accepted
the belt is no longer at max; the player can tap again. If no truck
would accept any in-transit cube, further travel cannot help, and the
level is already lost from the tap that filled the belt.

A tap that is **rejected** because the conveyor is already at max does
not itself declare loss (state did not change). A **successful** tap
that leaves the conveyor at max with nothing able to exit **does**
declare loss immediately.

---

## 7. Invalid / unexpected input

| Input | `validation_error()` / result |
| --- | --- |
| A truck with `capacity < 1` | `LevelData.ERR_CAPACITY` |
| `conveyor_capacity < 1` | `LevelData.ERR_CONVEYOR_CAPACITY` |
| Starting stack longer than that truck’s capacity | `LevelData.ERR_STACK_LENGTH` |
| Non-empty starting stack contains fewer than two distinct colors | Validation reason to be named during the ownership refactor |
| `CubeColor.Id.NONE` in a starting stack | `LevelData.ERR_NONE_IN_STACK` |
| Empty `trucks` list | `LevelData.ERR_EMPTY_TRUCKS` |
| `tap` with out-of-range index | `TapResult.INVALID_INDEX`; state unchanged |
| `advance(n)` with non-integer or `n <= 0` | `AdvanceResult.INVALID_TICKS`; state unchanged |

The session does not invent cubes, colors, or trucks. It only rearranges
what the level provided.

A color whose `set_size` matches no truck capacity is legal input
(useful for loss / “cannot finish” tests) but the level cannot be won.

---

## 8. Ownership and collaborators

Runtime ownership (who frees whom, who may mutate what):

```
PuzzleSession          # play record: history + the Level(s) in this play
  └── Level            # playable puzzle; tap / advance live here
        └── Conveyor   # the loop
              ├── Truck...          # stations on the loop
              │     └── Block...    # stacked; truck owns until unload
              └── Block...          # in transit; conveyor owns until accept
```

`LevelData` is not in that tree. It is an immutable description used
only to construct a `Level`. A future `User` may own many
`PuzzleSession`s; that is out of scope here.

A `Block` is a real object. Unload **transfers** it from `Truck` to
`Conveyor`. A successful receive transfers it back. The object is not
copied and is never owned by two parents at once.

`Level.tap` / `Level.advance` are the only operations that mutate
playable state. They delegate: tap asks a truck to unload and the
conveyor to `load`; advance asks the conveyor to move and offer.

Collaborators of `Level`:

- **LevelData** — supplied at construction; invalid data is rejected
  up front (section 7).
- **Caller (tests, later the scene or PuzzleSession)** — calls `tap`
  and `advance`, reads observable state.

It does **not** depend on Godot nodes, input, audio, or a random number
generator. Given the same `LevelData`, taps, and `advance` values,
results are deterministic.

---

## 9. Observable state (for tests and later UI)

Enough to reconstruct the puzzle without looking at internals:

- Each truck’s `capacity`, owned blocks (bottom → top),
  and whether it is finished.
- Each color’s `set_size`.
- Each in-transit block: color and its conveyor-owned position.
- `in_transit_count`, `conveyor_capacity`, `belt_position_count`.
- Whether the last `tap` was accepted, and if not, why.
- Whether the level is playing, won, or lost.

---

## 10. Out of scope (this spec)

- Obstacles from Loop Sort.
- Rendering, animation curves, touch hit-testing.
- Level generation / progression / scoring / stars.
- Monetization hooks.
- Undo.

---

## 11. Decisions closed (this spec)

- Positions: derived discrete belt positions. Offer when a block occupies
  a truck offer position (advance land **or** load onto that position).
  Entry is the position after the source. First popped is pushed forward;
  later popped step on behind. Advance moves all transit blocks together.
- Accept vs complete: accept any color; finish only when capacity
  matches that color’s set size.
- Clock: `advance(n)` is `n` simultaneous +1 position steps. No
  `hop_duration`. Ring size is derived from truck count and capacity.
- Ownership: `PuzzleSession` → `Level` → `Conveyor` → (`Truck` →
  stacked `Block`, and in-transit `Block`). `tap` / `advance` on
  `Level`.

`PuzzleSession` history event schema is **not** specified yet. Do not
invent one in implementation.

Next workflow step: GUT + tests against this skeleton.
