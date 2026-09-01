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

- Has exactly one **color**. Colors are opaque identifiers (the logic
  does not care how they are displayed).
- Exists in exactly one place at a time: in a truck stack, or in transit
  on the conveyor.

### Color set size

The **set size** of a color `C` is the total number of cubes of color
`C` in the level (every starting stack, counted once at session start).
Cubes are never created or destroyed, so set size is constant.

This spec treats each color as **one set**. A truck **accepts any
color** that passes the receive rule (empty, or top match + room). It
**completes** only when it is full of a single color `C` **and**
`T.capacity == set_size(C)`.

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
- **Position** on the conveyor — see §3. The truck sits at one point on
  the loop. That is the only place the conveyor will ask it to accept.
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

An **empty** truck has no color. It can receive a cube of **any** color
(subject to not being finished — it isn’t — and having room). It has
nothing to unload.

### Conveyor

- A closed loop. Trucks occupy positions on that loop.
- Holds zero or more cubes **in transit**, each with its own position
  on the same loop.
- Has a **maximum in-transit capacity**, defined per level (`conveyor_max`).
- Does not stop and wait. Cubes keep moving until they enter a truck or
  the level ends. Filling the conveyor does **not** freeze it.
- Owns the “offer” step: when a cube reaches a truck’s position, the
  **conveyor asks the truck** if it can accept that cube. The truck
  answers from its current stack; it does not pull cubes on its own.

### Level (input data)

A level is defined by:

| Field | Meaning |
| --- | --- |
| `conveyor_max` | Max cubes allowed in transit at once. |
| `hop_duration` | Integer **ticks** for a cube to travel from one truck’s position to the next along the loop. This is a clock, not a destination. See §3. |
| `trucks` | Ordered list of trucks around the loop. Each truck has `capacity` (≥ 1), `position` on the conveyor, and a starting `stack` (list of colors, **bottom first**). A truck may start empty. |

Truck positions must be unique and lie on the loop. The cyclic order of
trucks is the order of those positions in the direction of travel.
No truck’s starting stack may exceed **that truck’s** `capacity`.
`conveyor_max` must be ≥ 1. `hop_duration` must be an integer ≥ 1.

If positions are omitted in an early implementation, the ordered list
itself is the loop (truck `i` at station `i`). That is equivalent: the
list order *is* position.

---

## 3. Positions on the conveyor (not destination assignment)

Each cube on the conveyor is an independent traveler. It occupies one
in-transit slot and has a **position** on the loop. Cubes never reserve
a truck. Two cubes of the same color may both be approaching a truck
that only has one free slot; the first to **reach that truck’s
position** is offered first, and the second is offered against whatever
the truck looks like when **it** arrives.

**Receive is only attempted on reach.** The conveyor compares cube
position to truck positions. When a cube **reaches** truck `T`’s
position, the conveyor asks `T` whether it can accept that cube. If
`T` says no, the cube keeps moving toward the next truck’s position.

**Entry position — do not ask the source truck.** When cubes are
released from truck `K`, they enter the conveyor **just after `K`’s
position**, at the start of the hop toward the next truck (`K+1`).
Spawning there must **not** count as reaching `K`. The first offer is
when those cubes reach `K+1`. If rejected everywhere, a cube can later
come all the way around and be offered to `K`.

A cube in transit has:

- `color`
- `position` on the conveyor (or, equivalently, `approaching_truck` +
  ticks of `progress` toward that truck’s position)
- It does **not** have a destination or reserved slot

**Clock: ticks.** `hop_duration` is how many ticks a cube takes to go
from one truck position to the next. `advance(n)` moves every in-transit
cube forward `n` ticks. An offer happens when a cube’s movement lands
on (or would pass) a truck’s position. The scene can later map ticks to
real time however it wants (e.g. one tick per N milliseconds) without
changing this model.

Cubes do not merge, match, or clear on the conveyor. The only way off
is a truck accepting an offer **at its position**.

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
| Conveyor is already at `conveyor_max` | Cannot load more onto the conveyor |

**Accepted tap:**

1. Read the top cube’s color. Let `run` be the number of contiguous
   cubes of that color from the top down.
2. Let `load = min(run, conveyor_max - in_transit_count)`.
3. Pop `load` cubes from the top of the truck, **top first**.
4. Put each popped cube onto the conveyor **just after `K`’s position**,
   in that order (the first popped cube is ahead toward `K+1`).
5. No destination is chosen or reserved. The source truck is not asked
   to accept the cubes it just released.

Leftover cubes of the same run stay on the truck. Example: top run of
4 reds, 2 free conveyor slots → 2 reds enter transit, 2 reds remain.

Tapping never itself ends the level. A full conveyor only **blocks**
further taps. The conveyor keeps running.

### `advance(n)`

Moves the clock forward by `n` integer ticks. Tests pass exact values.
The scene later chooses how often to call this (e.g. once per frame
after accumulating real time, or once per fixed tick).

- `n` is not an integer, or `n <= 0`: invalid input; no movement;
  report an error.
- Every in-transit cube moves forward `n` ticks along the loop.
- The conveyor does not pause when full or between taps. `advance` is
  the only clock.

**Reach / offer / receive** — when a cube reaches truck `T`’s position:

1. The conveyor asks `T` if it can accept this cube **right now**
   (rules below). No reservation is consulted, because none exists.
2. **Accepted:** the cube leaves the conveyor (`in_transit_count` drops
   by 1) and is pushed onto `T`’s top. That cube is done traveling.
3. **Rejected:** the cube stays in transit and continues toward the
   next truck’s position. Leftover ticks in the same `advance` call
   keep moving it.

If several cubes reach the same truck in one `advance`, offer them in
travel order (the cube that is ahead is offered first). An accept can
change `T`’s top or remaining room for the next offer in that same
step. That is how “two cubes, one slot” is decided: arrival order, not
pre-assigned destinations.

---

## 5. Receive rule

The conveyor offers a cube of color `C` to truck `T` only when the cube
**reaches `T`’s position**. `T` accepts if and only if **all** of the
following hold **at that instant**:

1. `T` is not finished.
2. `T` has room (`stack length < T.capacity`).
3. Either `T` is empty, **or** `T`’s current **top** cube is color `C`.

Otherwise the truck refuses and the cube continues around the loop.

There is **no** capacity-vs-set-size check on accept. A 5-slot truck
may take a 7-cube color. Completing that truck still requires
`capacity == set_size(C)` (see §2). Receive never cares about colors
below the top, other than for the finished check elsewhere.

---

## 6. Win and loss

Evaluated after every successful `tap` and after every receive (i.e.
whenever session state changes). Both are false while the level is
still playable.

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

Loss is declared only when **both** are true:

- In-transit count equals `conveyor_max`.
- **No in-transit cube would be accepted by any truck if it reached
  that truck’s position right now** — same receive rule (accept any
  color; room + empty-or-top-match), current stacks.

That second clause is a **capability check**, not an assignment. It
does not pick a truck, reserve a slot, or change motion. If some cube
*could* be accepted, do **not** fail — keep running until a cube
actually reaches that truck and is accepted (or until a later receive
changes the stacks so that nothing left can exit). If no truck would
accept any in-transit cube, further travel cannot help.

Loss is **not** triggered by the tap that finds the conveyor full.

---

## 7. Invalid / unexpected input

| Input | Behavior |
| --- | --- |
| A truck with `capacity < 1` | Reject the level; do not start a session |
| Duplicate or missing truck positions (if positions are explicit) | Reject the level |
| Level with `conveyor_max < 1` | Reject the level |
| Level with `hop_duration` not an integer ≥ 1 | Reject the level |
| A starting stack longer than **that truck’s** `capacity` | Reject the level |
| Empty `trucks` list | Reject the level |
| `tap` with out-of-range index | Rejected tap; state unchanged |
| `advance(n)` with non-integer or `n <= 0` | Error; state unchanged |

The session does not invent cubes, colors, or trucks. It only rearranges
what the level provided.

A color whose `set_size` matches no truck capacity is legal input
(useful for loss / “cannot finish” tests) but the level cannot be won.

---

## 8. Collaborators

This unit owns session state. It depends on:

- **Level data** — supplied at construction; treated as an immutable
  description. Invalid level data is rejected up front (section 7).
- **Caller (tests, later the scene)** — calls `tap` and `advance`, reads
  observable state (stacks, in-transit cubes, win/loss, tap rejection
  reason).

It does **not** depend on Godot nodes, input, audio, or a random number
generator. Given the same level, taps, and `advance` values, results
are deterministic.

---

## 9. Observable state (for tests and later UI)

Enough to reconstruct the puzzle without looking at internals:

- Each truck’s `capacity`, `position`, stack (bottom → top), and
  whether it is finished.
- Each color’s `set_size`.
- Each in-transit cube: color and position on the conveyor.
- `in_transit_count`, `conveyor_max`.
- Whether the last `tap` was accepted, and if not, why.
- Whether the session is playing, won, or lost.

---

## 10. Out of scope (this spec)

- Obstacles from Loop Sort.
- Rendering, animation curves, touch hit-testing.
- Level generation / progression / scoring / stars.
- Monetization hooks.
- Undo.

---

## 11. Decisions closed (this spec)

- Positions: trucks sit on the conveyor; offer only on reach; entry is
  just after the source truck.
- Accept vs complete: accept any color; finish only when capacity
  matches that color’s set size.
- Clock: integer ticks. `hop_duration` is ticks per hop. `advance(n)`
  advances `n` ticks.

No further open points on the core loop. Next workflow step is the
skeleton (signatures only), then GUT + tests.
