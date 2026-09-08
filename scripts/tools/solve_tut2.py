#!/usr/bin/env python3
"""Best-first search for the 5/5/7 tut2 draft. Replay any win on Level."""

from __future__ import annotations

import heapq
import time
from dataclasses import dataclass, field
from typing import Optional

# Match CubeColor.Id
RED, YELLOW, BLUE = 1, 3, 5
NAME = {RED: "R", YELLOW: "Y", BLUE: "B"}

NODE_LIMIT = 1_500_000


@dataclass
class Truck:
    capacity: int
    blocks: list[int]  # bottom-first colors

    def copy(self) -> Truck:
        return Truck(self.capacity, self.blocks.copy())

    def empty(self) -> bool:
        return not self.blocks

    def top(self) -> Optional[int]:
        return self.blocks[-1] if self.blocks else None

    def finished(self, sizes: dict[int, int]) -> bool:
        if len(self.blocks) != self.capacity or self.capacity < 1:
            return False
        color = self.blocks[0]
        return all(b == color for b in self.blocks) and sizes.get(color, -1) == self.capacity

    def potential_completion(self, sizes: dict[int, int]) -> bool:
        if self.empty():
            return False
        color = self.blocks[0]
        return all(b == color for b in self.blocks) and sizes.get(color, -1) == self.capacity

    def can_accept(self, color: int, sizes: dict[int, int], claimed: dict[int, bool] | None = None) -> bool:
        if self.finished(sizes) or len(self.blocks) >= self.capacity:
            return False
        if self.empty():
            return not (claimed or {}).get(color, False)
        return self.top() == color

    def top_run(self) -> int:
        if self.empty():
            return 0
        color = self.top()
        n = 0
        for b in reversed(self.blocks):
            if b != color:
                break
            n += 1
        return n

    def unload(self, max_count: int) -> list[int]:
        taken: list[int] = []
        limit = min(max_count, self.top_run())
        for _ in range(limit):
            taken.append(self.blocks.pop())
        return taken

    def receive(self, color: int, sizes: dict[int, int], claimed: dict[int, bool] | None = None) -> bool:
        if not self.can_accept(color, sizes, claimed):
            return False
        self.blocks.append(color)
        return True


@dataclass
class TransitBlock:
    color: int
    position: int


@dataclass
class State:
    conveyor_capacity: int
    trucks: list[Truck]
    transit: list[TransitBlock]
    sizes: dict[int, int]
    status: str = "PLAYING"

    def copy(self) -> State:
        return State(
            self.conveyor_capacity,
            [t.copy() for t in self.trucks],
            [TransitBlock(c.color, c.position) for c in self.transit],
            self.sizes,
            self.status,
        )

    def key(self) -> tuple:
        stacks = tuple(tuple(t.blocks) for t in self.trucks)
        belt = tuple(sorted((c.color, c.position) for c in self.transit))
        return (self.status, stacks, belt)

    @property
    def belt_position_count(self) -> int:
        return max((len(self.trucks) * 2) + 2, self.conveyor_capacity)

    def wrap(self, position: int) -> int:
        return position % self.belt_position_count

    def occupant(self, position: int) -> Optional[TransitBlock]:
        for cube in self.transit:
            if cube.position == self.wrap(position):
                return cube
        return None

    def offer_position(self, truck_index: int) -> int:
        return 1 + (truck_index * 2)

    def exit_position(self, truck_index: int) -> int:
        return self.wrap(self.offer_position(truck_index) + 1)

    def truck_at(self, position: int) -> Optional[int]:
        position = self.wrap(position)
        for i in range(len(self.trucks)):
            if self.offer_position(i) == position:
                return i
        return None

    def shift_chain(self, start: int, step: int) -> None:
        chain: list[TransitBlock] = []
        position = start
        while True:
            cube = self.occupant(position)
            if cube is None:
                break
            chain.append(cube)
            position = self.wrap(position + step)
            if position == start:
                break
        for cube in reversed(chain):
            cube.position = self.wrap(cube.position + step)
            self.offer(cube)

    def claimed_colors(self) -> dict[int, bool]:
        return {
            t.top(): True
            for t in self.trucks
            if t.potential_completion(self.sizes)
        }

    def offer(self, cube: TransitBlock) -> None:
        ti = self.truck_at(cube.position)
        if ti is None:
            return
        if self.trucks[ti].receive(cube.color, self.sizes, self.claimed_colors()):
            self.transit.remove(cube)

    def load(self, colors: list[int], from_index: int) -> None:
        entry = self.exit_position(from_index)
        for color in colors:
            self.shift_chain(entry, +1)
            cube = TransitBlock(color, entry)
            self.transit.append(cube)
            self.offer(cube)

    def any_can_exit(self) -> bool:
        claimed = self.claimed_colors()
        for cube in self.transit:
            if any(t.can_accept(cube.color, self.sizes, claimed) for t in self.trucks):
                return True
        return False

    def is_won(self) -> bool:
        if self.transit:
            return False
        return all(t.empty() or t.finished(self.sizes) for t in self.trucks)

    def is_lost(self) -> bool:
        return len(self.transit) >= self.conveyor_capacity and not self.any_can_exit()

    def tap(self, i: int) -> bool:
        if self.status != "PLAYING":
            return False
        t = self.trucks[i]
        if t.finished(self.sizes) or t.empty():
            return False
        if len(self.transit) >= self.conveyor_capacity:
            return False
        room = self.conveyor_capacity - len(self.transit)
        taken = t.unload(room)
        if not taken:
            return False
        self.load(taken, i)
        if self.is_won():
            self.status = "WON"
        elif self.is_lost():
            self.status = "LOST"
        return True

    def advance(self) -> None:
        if not self.transit:
            return
        for cube in self.transit:
            cube.position = self.wrap(cube.position + 1)
        for cube in self.transit.copy():
            self.offer(cube)
        if self.status == "PLAYING" and self.is_won():
            self.status = "WON"

    def score(self) -> int:
        """Lower is better. Finished trucks and homed cubes first."""
        if self.status == "WON":
            return -10_000
        if self.status == "LOST":
            return 10_000
        finished = 0
        homed = 0
        mixed = 0
        cubes = len(self.transit)
        for t in self.trucks:
            cubes += len(t.blocks)
            if t.finished(self.sizes):
                finished += 1
                homed += len(t.blocks)
                continue
            if not t.blocks:
                continue
            colors = set(t.blocks)
            if len(colors) > 1:
                mixed += 1
            elif t.capacity == self.sizes.get(t.blocks[0], -1):
                homed += len(t.blocks)
        return (
            100 * (len(self.trucks) - finished)
            + 4 * (cubes - homed)
            + 8 * mixed
            + len(self.transit)
        )


def tut1(conveyor_capacity: int) -> State:
    t0 = Truck(5, [YELLOW, RED, YELLOW, RED, YELLOW])
    t1 = Truck(5, [RED, YELLOW, RED, YELLOW, RED])
    return State(conveyor_capacity, [t0, t1], [], {RED: 5, YELLOW: 5})


def tut2(conveyor_capacity: int) -> State:
    t0 = Truck(5, [RED, YELLOW, BLUE, RED, BLUE])
    t1 = Truck(5, [RED, YELLOW, BLUE, YELLOW, BLUE])
    t2 = Truck(7, [BLUE, RED, BLUE, YELLOW, BLUE, RED, YELLOW])
    sizes = {RED: 5, YELLOW: 5, BLUE: 7}
    return State(conveyor_capacity, [t0, t1, t2], [], sizes)


def legal_taps(s: State) -> list[int]:
    if s.status != "PLAYING" or len(s.transit) >= s.conveyor_capacity:
        return []
    out = []
    for i, t in enumerate(s.trucks):
        if not t.empty() and not t.finished(s.sizes):
            out.append(i)
    return out


def search(start: State) -> dict:
    seen: set = {start.key()}
    heap: list[tuple[int, int, State, str]] = [(start.score(), 0, start, "")]
    seq = 0
    nodes = 0
    t0 = time.time()
    while heap:
        _score, _n, state, path = heapq.heappop(heap)
        nodes += 1
        if nodes > NODE_LIMIT:
            return {"verdict": "UNKNOWN", "nodes": nodes, "path": "", "secs": time.time() - t0}
        if state.status == "WON":
            return {"verdict": "WON", "nodes": nodes, "path": path.strip(), "secs": time.time() - t0}
        if state.status != "PLAYING":
            continue
        children: list[tuple[str, State]] = []
        for i in legal_taps(state):
            nxt = state.copy()
            if nxt.tap(i):
                children.append((f"T{i}", nxt))
        if state.transit:
            nxt = state.copy()
            nxt.advance()
            children.append(("A", nxt))
        for action, nxt in children:
            k = nxt.key()
            if k in seen:
                continue
            seen.add(k)
            seq += 1
            heapq.heappush(heap, (nxt.score(), seq, nxt, path + action + " "))
    return {"verdict": "UNWINNABLE", "nodes": nodes, "path": "", "secs": time.time() - t0}


def main() -> None:
    print("sanity tut1 capacity=5")
    r1 = search(tut1(5))
    print(f"  {r1['verdict']} nodes={r1['nodes']} {r1['secs']:.2f}s")
    if r1["verdict"] == "WON":
        print(f"  path: {r1['path']}")
    print("tut2 draft: three trucks with derived offer positions 1, 3, 5")
    for conveyor_capacity in range(15, 6, -1):
        result = search(tut2(conveyor_capacity))
        print(
            f"capacity={conveyor_capacity:2d}  {result['verdict']:<11}  "
            f"nodes={result['nodes']:<8}  {result['secs']:.2f}s"
        )
        if result["verdict"] == "WON":
            print(f"  path: {result['path']}")


if __name__ == "__main__":
    main()
