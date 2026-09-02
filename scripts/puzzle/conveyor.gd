class_name Conveyor
extends RefCounted
## Closed loop of slot_count slots. Owns the Trucks (stations) and
## every Block that has left a truck and not yet been accepted.
##
## See docs/CORE_LOOP.md §3 and §4 (advance).

enum AdvanceResult {
	ADVANCED,
	INVALID_TICKS,
}

var conveyor_max: int
var slot_count: int
var trucks: Array[Truck]
var in_transit: Array[Block]


func _init(
	p_conveyor_max: int = 0,
	p_slot_count: int = 0,
	p_trucks: Array[Truck] = []
) -> void:
	conveyor_max = p_conveyor_max
	slot_count = p_slot_count
	trucks = p_trucks
	in_transit = []


func in_transit_count() -> int:
	push_error("not implemented")
	return 0


func is_at_max() -> bool:
	push_error("not implemented")
	return false


## First array element is first-popped: steps on the entry slot (source
## position + 1, wrap). Each later element pushes that chain forward
## one slot and steps on behind. May push existing occupants at the
## source slot and incoming side (K-n) backward. If a placed or pushed
## block sits on another truck’s slot, offer that truck. Does not
## offer back to the source. Returns false if they would exceed max.
func load(blocks: Array[Block], from_truck_index: int) -> bool:
	push_error("not implemented")
	return false


## True if this block may increment its slot this tick (next slot free
## or its occupant is also moving). False if jammed.
func can_advance(block: Block) -> bool:
	push_error("not implemented")
	return false


## For each of n ticks, each in-transit block asks can_advance before
## moving. Offer only when a granted step lands on a truck. Truck is a
## collaborator: ask can_accept / receive; do not implement truck rules.
func advance(n: int, set_sizes: Dictionary) -> AdvanceResult:
	push_error("not implemented")
	return AdvanceResult.INVALID_TICKS


## True if any in-transit block would be accepted by any truck right now.
func any_block_can_exit(set_sizes: Dictionary) -> bool:
	push_error("not implemented")
	return false
