class_name Conveyor
extends RefCounted
## Closed loop. Owns the Trucks (stations) and every Block that has
## left a truck and not yet been accepted into another.
##
## See docs/CORE_LOOP.md §3 and §4 (advance).

enum AdvanceResult {
	ADVANCED,
	INVALID_TICKS,
}

var conveyor_max: int
var hop_duration: int
var trucks: Array[Truck]
var in_transit: Array[Block]


func _init(
	p_conveyor_max: int = 0,
	p_hop_duration: int = 0,
	p_trucks: Array[Truck] = []
) -> void:
	conveyor_max = p_conveyor_max
	hop_duration = p_hop_duration
	trucks = p_trucks
	in_transit = []


func in_transit_count() -> int:
	push_error("not implemented")
	return 0


func is_at_max() -> bool:
	push_error("not implemented")
	return false


## Take ownership of blocks just after from_truck_index. Does not ask
## that truck to accept them. Returns false if they would exceed max.
func load(blocks: Array[Block], from_truck_index: int) -> bool:
	push_error("not implemented")
	return false


## Move every in-transit block n ticks; offer a block to a truck only
## when it reaches that truck's position.
func advance(n: int, set_sizes: Dictionary) -> AdvanceResult:
	push_error("not implemented")
	return AdvanceResult.INVALID_TICKS


## True if any in-transit block would be accepted by any truck right now.
func any_block_can_exit(set_sizes: Dictionary) -> bool:
	push_error("not implemented")
	return false
