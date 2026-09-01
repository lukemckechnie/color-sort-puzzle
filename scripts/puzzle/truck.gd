class_name Truck
extends RefCounted
## Runtime truck. Owns its stacked Blocks until it unloads them onto
## the Conveyor. The Conveyor offers arriving Blocks back via receive.
##
## See docs/CORE_LOOP.md §2 (Truck) and §5 (receive).

var capacity: int
var position: int
## Blocks bottom-first. Index 0 is the bottom; the last element is the top.
var blocks: Array[Block]


func _init(
	p_capacity: int = 0,
	p_position: int = 0,
	p_blocks: Array[Block] = []
) -> void:
	capacity = p_capacity
	position = p_position
	blocks = p_blocks.duplicate()


func is_empty() -> bool:
	push_error("not implemented")
	return false


## Finished only if full, uniform color C, and capacity == set_size(C).
func is_finished(set_sizes: Dictionary) -> bool:
	push_error("not implemented")
	return false


## Receive rule at this instant: not finished, has room, empty or top matches.
## Does not check set size (accept any color).
func can_accept(color: CubeColor.Id, set_sizes: Dictionary) -> bool:
	push_error("not implemented")
	return false


## CubeColor.Id.NONE if the truck is empty.
func top_color() -> CubeColor.Id:
	push_error("not implemented")
	return CubeColor.Id.NONE


## Contiguous run of the top color, from the top down. 0 if empty.
func top_run_length() -> int:
	push_error("not implemented")
	return 0


## Transfer up to max_count blocks of the top-color run to the caller.
## Ownership moves with the returned array.
func unload(max_count: int) -> Array[Block]:
	push_error("not implemented")
	return []


## Take ownership of block if can_accept. Returns false if refused.
func receive(block: Block, set_sizes: Dictionary) -> bool:
	push_error("not implemented")
	return false
