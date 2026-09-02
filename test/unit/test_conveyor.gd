extends GutTest
## Conveyor unit tests. Trucks are doubles — Conveyor behavior only.


var _TruckScript: GDScript


func before_all() -> void:
	_TruckScript = load("res://scripts/puzzle/truck.gd") as GDScript


func _block(color: CubeColor.Id) -> Block:
	return Block.new(color)


func _one(block: Block) -> Array[Block]:
	var out: Array[Block] = []
	out.append(block)
	return out


func _pair(a: Block, b: Block) -> Array[Block]:
	var out: Array[Block] = []
	out.append(a)
	out.append(b)
	return out


func _mock_truck(capacity: int, position: int, accept: bool = false) -> Truck:
	var empty: Array[Block] = []
	var truck: Truck = double(_TruckScript).new(capacity, position, empty)
	truck.capacity = capacity
	truck.position = position
	truck.blocks = empty
	stub(truck, "can_accept").to_return(accept)
	stub(truck, "receive").to_return(accept)
	stub(truck, "is_empty").to_return(true)
	stub(truck, "is_finished").to_return(false)
	return truck


func _conv(trucks: Array, conveyor_max: int, slot_count: int) -> Conveyor:
	var owned: Array[Truck] = []
	for truck in trucks:
		owned.append(truck)
	return Conveyor.new(conveyor_max, slot_count, owned)


func test_load_places_first_block_on_entry_slot() -> void:
	var t0 := _mock_truck(3, 0)
	var t1 := _mock_truck(3, 4)
	var conv := _conv([t0, t1], 3, 8)
	var cube := _block(CubeColor.Id.RED)

	assert_true(conv.load(_one(cube), 0))
	assert_eq(conv.in_transit_count(), 1)
	assert_eq(conv.in_transit.size(), 1)
	if conv.in_transit.is_empty():
		return
	assert_same(conv.in_transit[0], cube)
	assert_eq(cube.position, 1)
	assert_eq(t0.blocks.size(), 0)


func test_load_two_blocks_pushes_first_forward_second_steps_on_behind() -> void:
	var t0 := _mock_truck(3, 0)
	var t1 := _mock_truck(3, 4)
	var conv := _conv([t0, t1], 3, 8)
	var first_popped := _block(CubeColor.Id.RED)
	var second_popped := _block(CubeColor.Id.RED)

	assert_true(conv.load(_pair(first_popped, second_popped), 0))
	assert_eq(second_popped.position, 1, "later popped sits on the entry slot")
	assert_eq(first_popped.position, 2, "first popped was pushed one slot forward")


func test_load_from_last_truck_wraps_entry_slot() -> void:
	var t0 := _mock_truck(3, 0)
	var t1 := _mock_truck(3, 5)
	var conv := _conv([t0, t1], 3, 6)
	var cube := _block(CubeColor.Id.BLUE)

	assert_true(conv.load(_one(cube), 1))
	assert_called(t0, "receive")
	assert_not_called(t1, "receive")
	if conv.in_transit.is_empty():
		return
	assert_eq(cube.position, 0, "entry after slot 5 on a ring of 6 is 0")


func test_load_offers_to_truck_sitting_on_entry_slot() -> void:
	var source := _mock_truck(3, 0, false)
	var neighbor := _mock_truck(3, 1, true)
	var conv := _conv([source, neighbor], 3, 8)
	var cube := _block(CubeColor.Id.RED)

	assert_true(conv.load(_one(cube), 0))
	assert_eq(conv.in_transit.size(), 0)
	assert_called(neighbor, "receive")
	assert_not_called(source, "receive")


func test_load_refused_by_entry_truck_stays_on_that_slot() -> void:
	var source := _mock_truck(3, 0, false)
	var neighbor := _mock_truck(3, 1, false)
	var conv := _conv([source, neighbor], 3, 8)
	var cube := _block(CubeColor.Id.RED)

	assert_true(conv.load(_one(cube), 0))
	assert_eq(conv.in_transit.size(), 1)
	assert_eq(cube.position, 1)
	assert_called(neighbor, "receive")
	assert_not_called(source, "receive")


func test_load_pushes_occupant_at_source_slot_backward() -> void:
	var t0 := _mock_truck(3, 0)
	var t1 := _mock_truck(3, 4)
	var conv := _conv([t0, t1], 3, 8)
	var already_at_k := _block(CubeColor.Id.BLUE)
	already_at_k.position = 0
	conv.in_transit.append(already_at_k)

	var incoming := _block(CubeColor.Id.RED)
	assert_true(conv.load(_one(incoming), 0))
	assert_eq(incoming.position, 1)
	assert_eq(already_at_k.position, 7, "occupant of K is pushed backward one slot")


func test_load_pushes_incoming_side_k_minus_n_backward() -> void:
	var t0 := _mock_truck(3, 0)
	var t1 := _mock_truck(3, 4)
	var conv := _conv([t0, t1], 3, 8)
	var at_k := _block(CubeColor.Id.BLUE)
	var behind_k := _block(CubeColor.Id.GREEN)
	at_k.position = 0
	behind_k.position = 7
	conv.in_transit.append(at_k)
	conv.in_transit.append(behind_k)

	var incoming := _block(CubeColor.Id.RED)
	assert_true(conv.load(_one(incoming), 0))
	assert_eq(incoming.position, 1)
	assert_eq(at_k.position, 7)
	assert_eq(behind_k.position, 6, "K-n is pushed further backward")


func test_can_advance_true_when_next_slot_empty() -> void:
	var t0 := _mock_truck(3, 0)
	var t1 := _mock_truck(3, 4)
	var conv := _conv([t0, t1], 3, 8)
	var cube := _block(CubeColor.Id.RED)
	assert_true(conv.load(_one(cube), 0))
	assert_true(conv.can_advance(cube))


func test_can_advance_false_when_next_slot_occupied() -> void:
	var t0 := _mock_truck(3, 0)
	var t1 := _mock_truck(3, 4)
	var conv := _conv([t0, t1], 3, 8)
	var first_popped := _block(CubeColor.Id.GREEN)
	var second_popped := _block(CubeColor.Id.RED)
	assert_true(conv.load(_pair(first_popped, second_popped), 0))
	assert_eq(first_popped.position, 2)
	assert_eq(second_popped.position, 1)
	assert_false(conv.can_advance(second_popped), "next slot is occupied by the lead block")
	assert_true(conv.can_advance(first_popped), "lead has an empty slot ahead")


func test_advance_increments_position_when_can_advance() -> void:
	var t0 := _mock_truck(3, 0)
	var t1 := _mock_truck(3, 4)
	var conv := _conv([t0, t1], 3, 8)
	var cube := _block(CubeColor.Id.RED)
	assert_true(conv.load(_one(cube), 0))
	assert_eq(conv.advance(1, {}), Conveyor.AdvanceResult.ADVANCED)
	assert_eq(cube.position, 2)


func test_advance_does_not_move_a_jammed_block() -> void:
	var t0 := _mock_truck(3, 0)
	var t1 := _mock_truck(3, 4)
	var conv := _conv([t0, t1], 3, 8)
	var first_popped := _block(CubeColor.Id.GREEN)
	var second_popped := _block(CubeColor.Id.RED)
	assert_true(conv.load(_pair(first_popped, second_popped), 0))
	var parked := _block(CubeColor.Id.BLUE)
	parked.position = 3
	conv.in_transit.append(parked)
	assert_eq(conv.advance(1, {}), Conveyor.AdvanceResult.ADVANCED)
	assert_eq(first_popped.position, 2, "lead is jammed behind parked")
	assert_eq(second_popped.position, 1, "rear stays if lead did not move")


func test_advance_landing_on_accepting_truck_calls_receive_and_removes() -> void:
	var t0 := _mock_truck(3, 0, false)
	var t1 := _mock_truck(3, 3, true)
	var conv := _conv([t0, t1], 3, 8)
	var cube := _block(CubeColor.Id.RED)
	assert_true(conv.load(_one(cube), 0))
	assert_eq(conv.advance(2, {}), Conveyor.AdvanceResult.ADVANCED)
	assert_eq(conv.in_transit.size(), 0)
	assert_called(t1, "receive")
	assert_not_called(t0, "receive")


func test_advance_landing_on_refusing_truck_stays_in_slot() -> void:
	var t0 := _mock_truck(3, 0, false)
	var t1 := _mock_truck(3, 3, false)
	var conv := _conv([t0, t1], 3, 8)
	var cube := _block(CubeColor.Id.RED)
	assert_true(conv.load(_one(cube), 0))
	assert_eq(conv.advance(2, {}), Conveyor.AdvanceResult.ADVANCED)
	assert_eq(conv.in_transit.size(), 1)
	assert_eq(cube.position, 3)
	assert_called(t1, "receive")


func test_partial_advance_does_not_offer() -> void:
	var t0 := _mock_truck(3, 0, false)
	var t1 := _mock_truck(3, 3, true)
	var conv := _conv([t0, t1], 3, 8)
	var cube := _block(CubeColor.Id.RED)
	assert_true(conv.load(_one(cube), 0))
	assert_eq(conv.advance(1, {}), Conveyor.AdvanceResult.ADVANCED)
	assert_eq(cube.position, 2)
	assert_eq(conv.in_transit.size(), 1)
	assert_not_called(t1, "receive")


func test_load_that_would_exceed_max_returns_false_and_does_not_take_ownership() -> void:
	var t0 := _mock_truck(3, 0)
	var conv := _conv([t0], 1, 8)
	var a := _block(CubeColor.Id.RED)
	var b := _block(CubeColor.Id.BLUE)
	assert_false(conv.load(_pair(a, b), 0))
	assert_eq(conv.in_transit_count(), 0)
	assert_eq(conv.in_transit.size(), 0)
	assert_false(conv.is_at_max())


func test_second_load_that_would_exceed_max_leaves_existing_untouched() -> void:
	var t0 := _mock_truck(3, 0)
	var conv := _conv([t0], 1, 8)
	var first := _block(CubeColor.Id.RED)
	var extra := _block(CubeColor.Id.BLUE)
	assert_true(conv.load(_one(first), 0))
	assert_true(conv.is_at_max())
	assert_false(conv.load(_one(extra), 0))
	assert_eq(conv.in_transit.size(), 1)
	if conv.in_transit.is_empty():
		return
	assert_same(conv.in_transit[0], first)
	assert_eq(first.position, 1)


func test_advance_zero_is_invalid_and_does_not_move() -> void:
	var t0 := _mock_truck(3, 0)
	var conv := _conv([t0], 3, 8)
	var cube := _block(CubeColor.Id.RED)
	assert_true(conv.load(_one(cube), 0))
	assert_eq(conv.advance(0, {}), Conveyor.AdvanceResult.INVALID_TICKS)
	assert_eq(cube.position, 1)


func test_advance_negative_is_invalid_and_does_not_move() -> void:
	var t0 := _mock_truck(3, 0)
	var conv := _conv([t0], 3, 8)
	var cube := _block(CubeColor.Id.RED)
	assert_true(conv.load(_one(cube), 0))
	assert_eq(conv.advance(-2, {}), Conveyor.AdvanceResult.INVALID_TICKS)
	assert_eq(cube.position, 1)


func test_any_block_can_exit_uses_truck_can_accept() -> void:
	var t0 := _mock_truck(3, 0, false)
	var t1 := _mock_truck(3, 4, true)
	var conv := _conv([t0, t1], 3, 8)
	var cube := _block(CubeColor.Id.RED)
	assert_true(conv.load(_one(cube), 0))
	assert_true(conv.any_block_can_exit({}))
	assert_called(t1, "can_accept")


func test_any_block_can_exit_false_when_all_trucks_refuse() -> void:
	var t0 := _mock_truck(3, 0, false)
	var t1 := _mock_truck(3, 4, false)
	var conv := _conv([t0, t1], 1, 8)
	var cube := _block(CubeColor.Id.RED)
	assert_true(conv.load(_one(cube), 0))
	assert_false(conv.any_block_can_exit({}))
