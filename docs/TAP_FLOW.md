# Tap Flow — Proposed Implementation

This document describes the proposed tap-flow redesign. It is the target
architecture, not the behavior of the current code.

## Shared terminology

- `T`: a truck reference or stable truck identifier.
- `TO(T)`: the truck's offer position on the conveyor. A block arriving
  at this position is offered to `T`.
- `TE(T)`: the truck's exit position: the position immediately after
  `TO(T)`, wrapping at `belt_position_count`.
- `conveyor_capacity`: the maximum number of blocks allowed in transit.
- `belt_position_count`: derived track geometry:
  `max((truck_count * 2) + 2, conveyor_capacity)`. It is not an authored
  capacity and gives each in-transit block a distinct position.
- **Load**: transfer a block from the conveyor into a truck at `TO(T)`.
- **Unload**: transfer blocks from a truck onto the conveyor at `TE(T)`.
- **Advance**: move every in-transit block forward by one conveyor
  position.

`TO` and `TE` are positions owned by the conveyor. They are not state on
`Truck` or `Block`.

## Ownership

```text
Playfield (Godot presentation)
└── Level (top-level domain)
    └── Conveyor (belt process owner)
        ├── truck placements: TO → Truck
        ├── in-transit block positions and ordering
        └── Trucks
            └── stacked Blocks
```

### Playfield

- Owns Godot `Control` nodes, hitboxes, visual state, and animations.
- Owns the runtime `Level` reference.
- Translates a Godot input event into `T`.
- Schedules conveyor ticks.
- Calls domain operations and renders the resulting domain state.
- Does not implement puzzle, truck, or conveyor rules.

### Level

- Is the top-level domain object exposed to Playfield.
- Owns the `Conveyor`.
- Owns level lifecycle state: `PLAYING`, `WON`, or `LOST`.
- Owns the last tap result exposed to the UI.
- Accepts the player command `tap(T)`.
- Does not calculate conveyor capacity, remove blocks from trucks, place
  blocks on the belt, or implement belt advancement.

### Conveyor

- Is the main interaction point for belt and truck transfers.
- Owns `conveyor_capacity` and derives `belt_position_count`.
- Owns each in-transit block's logical position and ordering.
- Owns truck placement around the belt, including `TO(T)` and `TE(T)`.
- Owns advancement, unload orchestration, belt insertion, displacement,
  offers, and aggregate belt/truck outcome checks.
- Calls into `Truck`, but neither `Truck` nor `Block` references back to
  `Conveyor`.
- Does not duplicate the truck's stack, acceptance, unload-run, or
  completion rules.

### Truck

- Owns its block stack.
- Owns top-run selection and removal.
- Owns acceptance and completion rules.
- Owns its claim state and claim lifecycle.
- Reads set size from the block's `Color`, which is the source of truth.
- Accepts only shared context it cannot derive locally, such as whether
  the arriving color is already claimed.
- Has no conveyor reference and does not move belt blocks.
- Does not own its conveyor position.

### Block

- Owns its `Color` reference only.
- `Block.Color.SetSize` is the source of truth for that color's total set
  size.
- Has no conveyor or truck reference.
- Has no `position`; its position is the key under which the conveyor
  currently stores it.

## Synchronous operation boundary

No domain event bus is required for this flow. A tap is a synchronous
command:

```text
Playfield → Level → Conveyor → Truck
```

The result returns through the same call stack:

```text
Truck → Conveyor → Level → Playfield
```

Because unload is processed synchronously, normal conveyor advancement
does not occur in the middle of an unload. This is what it means for belt
forward motion to pause while unloading.

## End-to-end tap sequence

```text
Godot truck hitbox receives press
  │
  ▼
Playfield._on_truck_tapped(T)
  │
  ├─ guard: Level exists
  ├─ translate presentation hitbox to T
  │
  ▼
Level.tap(T)
  │
  ├─ reject if level is not PLAYING
  │
  ▼
Conveyor.attempt_unload_at(T)
  │
  ├─ resolve T and its TO/TE placement
  ├─ reject unknown T
  ├─ reject finished truck
  ├─ reject empty truck
  ├─ calculate available conveyor capacity
  ├─ reject when no conveyor space remains
  │
  ▼
Truck.unload(available_capacity)
  │
  ├─ identify the contiguous top-color run
  ├─ remove up to the supplied limit
  └─ return removed Block references, top block first
  │
  ▼
Conveyor inserts returned blocks
  │
  ├─ insert one block at TE(T)
  ├─ push occupied belt blocks forward as required
  ├─ process arrivals at TO positions caused by each push
  ├─ repeat until all returned blocks are placed
  └─ offer every block that reaches any TO, including source T after a circuit
  │
  ▼
Conveyor attempts each arrival
  │
  ├─ resolve destination truck from TO position
  ├─ calculate shared acceptance context
  │    └─ whether another truck claims the arriving color
  │
  ▼
Truck.receive(block, acceptance_context)
  │
  ├─ evaluate all truck-owned acceptance rules
  ├─ append the Block when accepted
  └─ return receive outcome, including completion state
  │
  ▼
Conveyor applies receive outcome
  │
  ├─ accepted: remove block from conveyor transit state
  ├─ refused: retain block in conveyor transit state
  └─ continue insertion/offer processing
  │
  ▼
Conveyor returns aggregate operation outcome
  │
  ├─ tap result
  ├─ won/not won
  └─ lost/not lost
  │
  ▼
Level stores tap result and updates lifecycle state
  │
  ▼
Playfield refreshes from Level/Conveyor state
```

The exact concrete result types are not fixed by this document. The
behavioral contract is that enough information returns for `Level` to
update its own lifecycle without reimplementing conveyor or truck rules.

## 1. Godot input and truck identification

The current presentation still creates a physical **Tap** button for each
truck. Replacing it with a full-truck hitbox is a separate backlog item.

In either presentation, Playfield binds the hit target to `T`. It does not
pass pixels or a Godot `InputEvent` into the domain:

```text
Godot input → Playfield resolves T → Level.tap(T)
```

`T` must have one unambiguous representation at the domain boundary. It
may be a stable identifier or reference, but it must not sometimes mean a
truck-list index and sometimes mean `TO(T)`.

## 2. Level tap handling

`Level.tap(T)` is the player-command boundary, not the unload process
owner.

It:

1. Rejects the command if the level is no longer `PLAYING`.
2. Delegates the complete unload attempt to
   `Conveyor.attempt_unload_at(T)`.
3. Stores the returned tap result.
4. Changes its lifecycle state when the conveyor reports a win or loss.
5. Returns the tap result to Playfield.

It does not:

- resolve a truck by reading `Conveyor.trucks` itself;
- inspect whether the truck is empty or finished;
- calculate remaining conveyor capacity;
- call `Truck.unload()` directly;
- insert blocks onto the belt;
- ask trucks whether blocks can exit.

Those behaviors depend on conveyor-owned placement or process state and
belong in `Conveyor.attempt_unload_at(T)`.

## 3. Conveyor unload attempt

`Conveyor.attempt_unload_at(T)` coordinates the full transfer.

### Rejected attempts

It returns a rejected tap result without changing truck or belt contents
when:

1. `T` is not placed on this conveyor.
2. `T` is finished.
3. `T` is empty.
4. No additional block can fit on the conveyor.

The conveyor asks the truck for truck-owned facts such as `is_finished`
and `is_empty`; it does not reproduce those calculations.

### Available capacity

Available capacity is controlled only by `conveyor_capacity`:

```text
available capacity = conveyor_capacity - in_transit_count
```

`belt_position_count` does not participate in this calculation. It is
derived geometry used for movement, offers, exits, and wraparound.

### Accepted attempt

The conveyor:

1. Calculates available capacity.
2. Calls `Truck.unload(available_capacity)`.
3. Receives ownership of the removed `Block` references.
4. Inserts them one at a time at `TE(T)`.
5. Processes displacement and truck offers produced by each insertion.
6. Evaluates the aggregate outcome after insertion is complete.
7. Returns that outcome to `Level`.

## 4. Truck unload

`Truck.unload(max_count)` owns stack mutation:

1. Read the top block's color.
2. Count the contiguous top-color run.
3. Limit the count by `max_count`.
4. Remove that many block references from the stack.
5. Return the removed references in top-first order.

Blocks not selected for unloading remain owned by the truck. Returning a
second array containing all remaining blocks is unnecessary because the
truck already owns that state.

The truck does not know why `max_count` was selected and has no conveyor
reference.

## 5. Conveyor insertion and displacement

The first returned block is inserted at `TE(T)`. Every later returned
block is also inserted at `TE(T)` after the prior insertion has displaced
the existing outgoing chain forward.

The conveyor owns all movement because it owns transit position and
ordering:

```text
in-transit entry = Block reference + conveyor-owned position/order
```

This is a conceptual association, not a required concrete data type.
Moving a block means updating conveyor-owned transit state. No
`Block.position` field is updated. `belt_position_count` is derived to be
at least `conveyor_capacity`, so every permitted entry has a distinct
position.

Each one-position displacement is treated as movement. If a displaced
block arrives at any truck's `TO`, it is offered during that insertion
step. An accepted block leaves the belt before the next insertion step,
which may create space for the remaining returned blocks.

There is no source-truck exclusion. A block unloaded by `T` starts at
`TE(T)`, one position beyond `TO(T)`, so it cannot be immediately offered
back to `T`. If subsequent movement carries it around the full track to
`TO(T)`, it is a normal new arrival and `T` may accept it under the same
rules as any other truck.

## 6. Truck offer and receive

The conveyor detects that a block has arrived at `TO(T)` and asks `T` to
receive it.

The offer contains exactly one `Block`. Additional blocks are offered
individually on later advance steps.

The conveyor supplies only shared context that the truck cannot derive
from its own stack: whether the arriving color is currently claimed by a
matching-capacity, monochrome truck.

The arriving block's `Color.SetSize` is the source of truth for total set
size. Conveyor does not supply or own a separate color-to-size map.

The truck owns the complete acceptance decision:

1. Refuse if finished.
2. Refuse if full.
3. If empty, accept only when the color is not already claimed.
4. If non-empty, accept only when its top color matches.

A claimed color is therefore **not** rejected unconditionally. It may
still load into a non-empty truck with a matching top. The claim rule only
prevents that color from becoming the first block in an empty truck.

When an empty truck accepts its first block, it claims that color if:

```text
truck.capacity == block.Color.SetSize
```

The claim is stored on the truck rather than recomputed from its stack
after every operation:

- Additional accepted blocks must match the top color, so they cannot
  invalidate the claim.
- A partial unload leaves the claim in place.
- Emptying the truck clears the claim.
- Filling the truck evaluates completion. A completed truck remains the
  terminal owner of that color's claim.

On acceptance, the truck appends the block. Only when the truck is now
full and all its blocks have the same color does it evaluate completion.
Its receive result must distinguish at least:

- refused;
- accepted but not completed;
- accepted and completed.

The conveyor removes an accepted block from transit state. It does not
reimplement the truck's completion test.

## 7. Win and loss outcome

The conveyor has all trucks, transit positions, and receive capabilities,
so it can evaluate the aggregate state after the unload operation.

### Win

A win requires:

- there are no blocks in transit; and
- every truck to be empty or finished.

`Level` owns the `WON` lifecycle state, but it does not independently walk
truck stacks to reproduce this aggregate calculation. Conveyor reports
the outcome; Level applies it.

### Loss

Unless the gameplay rule is intentionally changed, a loss requires both:

- in-transit count equals `conveyor_capacity`; and
- no in-transit block can be accepted by any truck under the current
  receive rules.

Loss is checked after a successful unload attempt. A rejected tap on an
already full conveyor does not newly cause a loss.

The capability check asks trucks to apply their acceptance rules using
their blocks' color data and the supplied claim context. Conveyor
coordinates the query but does not duplicate those rules.

## 8. Level state update

The conveyor's aggregate operation result returns to `Level.tap(T)`.
Level:

1. Stores the tap result for presentation feedback.
2. Changes `_status` to `WON` when the operation reports a win.
3. Otherwise changes `_status` to `LOST` when it reports a loss.
4. Otherwise leaves `_status` as `PLAYING`.

This preserves lifecycle ownership in Level while keeping belt and truck
process logic in Conveyor.

## 9. UI refresh

After `Level.tap(T)` returns, Playfield resets its tick accumulator and
refreshes synchronously.

The refreshed UI reads:

- status and last tap result from `Level`;
- occupancy from `Conveyor`;
- belt colors and positions from Conveyor's transit state;
- truck colors from the trucks' stacks;
- win/loss presentation from `Level.status`.

Playfield does not read `Block.position`, because that field no longer
exists.

The current UI has a win modal but only status text for a loss. Whether
loss receives its own modal is outside this tap ownership change.

## 10. Relationship to normal conveyor advancement

Playfield supplies elapsed-time scheduling because `Conveyor` is a
`RefCounted` domain object and has no Godot `_process`.

The scheduled domain operation is `Conveyor.advance()`. Conveyor owns its
entire implementation:

1. Move all in-transit blocks one position forward simultaneously.
2. Process blocks that arrive at truck `TO` positions.
3. Remove accepted blocks from transit state.
4. Determine any resulting aggregate outcome.

Blocks do not ask whether they can advance. An unload call and an advance
call cannot interleave because both operations are synchronous.

How the result of a direct `Conveyor.advance()` call reaches Level so
Level can update lifecycle state is not yet settled.

## Inconsistencies and unclear points

These points must be resolved before implementation.

### 1. Meaning of `T`

The flow currently uses `T`, `truck_index`, truck reference, truck
position, and `Conveyor.trucks[position]` interchangeably.

They are not equivalent. In particular, a conveyor position is not
necessarily an index into a truck array. Choose one domain command
identity for `Level.tap(T)`, then let Conveyor map it to `TO(T)`.

### 2. Acceptance ownership

The draft sequence had Conveyor reject claimed colors, finished trucks,
and full trucks before calling `Truck.receive()`. That violates the stated
contract that Truck owns acceptance rules.

Conveyor should calculate only shared context and ask Truck for the whole
decision. It may ask `is_empty`/`is_finished` when validating a tap, but
it should not duplicate receive acceptance logic.

### 3. Initial claim state

Every valid starting truck is either empty or contains at least two
distinct colors. Therefore no truck starts claimed or completed:

- An empty starting truck has no color to claim.
- A non-empty starting truck is mixed and cannot claim a color.

The first claim is created during play when an empty,
matching-capacity truck accepts a block. It clears if that truck later
becomes empty and becomes terminal if the truck completes.

### 4. Truck receive result

The draft alternately says `Truck.receive()` returns a boolean and that it
returns completed state. A boolean cannot unambiguously represent refused,
accepted, and completed.

The concrete result type is still open, but it needs at least those three
observable outcomes.

### 5. Truck unload result

The draft returned both unloaded blocks and remaining blocks. That gives
the caller a second representation of state the truck already owns.

Returning only the removed block references better preserves truck
ownership. If Conveyor is expected to replace the truck's entire stack,
that would be a different ownership model.

### 6. Offer ordering during insertion

"Offer blocks on each advance loop" needs an exact ordering rule:

- Is every block displaced across `TO` offered?
- Can an accepted block create the space used by the next insertion?
- Can one block cross more than one position during a single insertion?

This document assumes one-position displacement steps, offers every new
arrival at `TO`, and applies acceptance before inserting the next returned
block. Confirm that assumption.

### 7. Source-truck return is position-driven

No special source identity or exclusion state is carried with an unloaded
block. Starting it at `TE(T)` prevents immediate re-entry. Reaching
`TO(T)` later proves that conveyor movement has carried it around the
track, so it is offered to `T` normally.

### 8. Advancement outcome path

Level owns lifecycle status, Conveyor owns advancement, and Playfield
schedules ticks. The return/event path from `Conveyor.advance()` to
Level's status update remains undefined.

Possible contracts include a Conveyor operation result passed into a
Level method, or a local signal observed by Level. This is the main
remaining process-ownership decision.

### 9. Public mutable state

For these contracts to hold, Playfield should receive read-only views or
queries of conveyor slots and truck stacks. Public mutable arrays would
allow presentation code to bypass Level, Conveyor, and Truck ownership.
