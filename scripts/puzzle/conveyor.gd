class_name Conveyor
extends RefCounted
## Closed loop with derived belt positions. Conveyor owns placement; Blocks
## and Trucks do not carry conveyor positions.

enum AdvanceResult { ADVANCED, INVALID_TICKS }

var conveyor_capacity: int
var belt_position_count: int
var trucks: Array[Truck]
var in_transit: Array[Block] = []
var _blocks_at: Dictionary = {}


func _init(p_conveyor_capacity: int = 0, p_trucks: Array[Truck] = []) -> void:
	conveyor_capacity = p_conveyor_capacity
	trucks = p_trucks
	belt_position_count = maxi((trucks.size() * 2) + 2, conveyor_capacity)


func in_transit_count() -> int:
	return in_transit.size()


func is_at_capacity() -> bool:
	return in_transit.size() >= conveyor_capacity


func offer_position(truck_index: int) -> int:
	if truck_index < 0 or truck_index >= trucks.size():
		return -1
	return 1 + (truck_index * 2)


func exit_position(truck_index: int) -> int:
	var offer := offer_position(truck_index)
	return _wrap(offer + 1) if offer >= 0 else -1


func position_of(block: Block) -> int:
	for position in _blocks_at:
		if _blocks_at[position] == block:
			return position
	return -1


func block_at(position: int) -> Block:
	return _blocks_at.get(_wrap(position), null)


func load(blocks: Array[Block], from_truck_index: int, set_sizes: Dictionary = {}) -> bool:
	if from_truck_index < 0 or from_truck_index >= trucks.size():
		return false
	if blocks.is_empty():
		return true
	if in_transit.size() + blocks.size() > conveyor_capacity:
		return false
	var entry := exit_position(from_truck_index)
	for block in blocks:
		_shift_forward_chain(entry, set_sizes)
		_put(block, entry)
		_offer_if_on_truck(block, set_sizes)
	return true


func advance(n: int, set_sizes: Dictionary) -> AdvanceResult:
	if n <= 0:
		return AdvanceResult.INVALID_TICKS
	for _tick in n:
		var moved := {}
		for position in _blocks_at:
			moved[_wrap(int(position) + 1)] = _blocks_at[position]
		_blocks_at = moved
		for block in in_transit.duplicate():
			_offer_if_on_truck(block, set_sizes)
	return AdvanceResult.ADVANCED


func any_block_can_exit(set_sizes: Dictionary) -> bool:
	var claimed := _claimed_colors(set_sizes)
	for block in in_transit:
		for truck in trucks:
			if truck.can_accept(block.color, set_sizes, claimed):
				return true
	return false


func _put(block: Block, position: int) -> void:
	_blocks_at[position] = block
	in_transit.append(block)


func _remove(block: Block) -> void:
	var position := position_of(block)
	if position >= 0:
		_blocks_at.erase(position)
	in_transit.erase(block)


func _shift_forward_chain(start_position: int, set_sizes: Dictionary) -> void:
	var chain: Array[int] = []
	var position := start_position
	while _blocks_at.has(position):
		chain.append(position)
		position = _wrap(position + 1)
		if position == start_position:
			break
	for i in range(chain.size() - 1, -1, -1):
		var from := chain[i]
		var block: Block = _blocks_at[from]
		_blocks_at.erase(from)
		_blocks_at[_wrap(from + 1)] = block
		_offer_if_on_truck(block, set_sizes)


func _truck_index_at(position: int) -> int:
	for truck_index in trucks.size():
		if offer_position(truck_index) == position:
			return truck_index
	return -1


func _offer_if_on_truck(block: Block, set_sizes: Dictionary) -> void:
	var truck_index := _truck_index_at(position_of(block))
	if truck_index < 0:
		return
	if trucks[truck_index].receive(block, set_sizes, _claimed_colors(set_sizes)):
		_remove(block)


func _claimed_colors(set_sizes: Dictionary) -> Dictionary:
	var claimed := {}
	for truck in trucks:
		if truck.is_potential_completion(set_sizes):
			claimed[truck.top_color()] = true
	return claimed


func _wrap(position: int) -> int:
	return (position % belt_position_count + belt_position_count) % belt_position_count
