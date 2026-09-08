class_name Truck
extends RefCounted
## Runtime truck. Owns its stacked Blocks until it unloads them onto
## the Conveyor. The Conveyor offers arriving Blocks back via receive.
##
## See docs/CORE_LOOP.md §2 (Truck) and §5 (receive).

var capacity: int
## Blocks bottom-first. Index 0 is the bottom; the last element is the top.
var blocks: Array[Block]


func _init(
	p_capacity: int = 0,
	p_blocks: Array[Block] = []
) -> void:
	capacity = p_capacity
	blocks = p_blocks.duplicate()


func is_empty() -> bool:
	return blocks.is_empty()


## Finished only if full, uniform color C, and capacity == set_size(C).
func is_finished(set_sizes: Dictionary) -> bool:
	if blocks.size() != capacity or capacity < 1:
		return false
	var color: CubeColor.Id = blocks[0].color
	for block in blocks:
		if block.color != color:
			return false
	return set_sizes.get(color, -1) == capacity


## Uniform C and capacity == set_size(C). Empty, mixed, and wrong-capacity
## monochrome stacks are not claims.
func is_potential_completion(set_sizes: Dictionary) -> bool:
	if is_empty():
		return false
	var color: CubeColor.Id = blocks[0].color
	for block in blocks:
		if block.color != color:
			return false
	return set_sizes.get(color, -1) == capacity


## Receive rule at this instant: not finished, has room, empty (and C is
## not claimed) or top matches. claimed is color -> true from the conveyor.
func can_accept(
	color: CubeColor.Id,
	set_sizes: Dictionary,
	claimed: Dictionary = {}
) -> bool:
	if is_finished(set_sizes):
		return false
	if blocks.size() >= capacity:
		return false
	if is_empty():
		return not claimed.get(color, false)
	return top_color() == color


## CubeColor.Id.NONE if the truck is empty.
func top_color() -> CubeColor.Id:
	if is_empty():
		return CubeColor.Id.NONE
	return blocks[blocks.size() - 1].color


## Contiguous run of the top color, from the top down. 0 if empty.
func top_run_length() -> int:
	if is_empty():
		return 0
	var color: CubeColor.Id = top_color()
	var count := 0
	for i in range(blocks.size() - 1, -1, -1):
		if blocks[i].color != color:
			break
		count += 1
	return count


## Transfer up to max_count blocks of the top-color run to the caller.
## Ownership moves with the returned array.
func unload(max_count: int) -> Array[Block]:
	var taken: Array[Block] = []
	var limit: int = mini(max_count, top_run_length())
	for _i in limit:
		taken.append(blocks.pop_back())
	return taken


## Take ownership of block if can_accept. Returns false if refused.
func receive(
	block: Block,
	set_sizes: Dictionary,
	claimed: Dictionary = {}
) -> bool:
	if block == null or not can_accept(block.color, set_sizes, claimed):
		return false
	blocks.append(block)
	return true
