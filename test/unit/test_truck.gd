extends GutTest
## Truck — accept / finish / unload / receive. Happy and sad.


func _block(color: CubeColor.Id) -> Block:
	return Block.new(color)


func _blocks(ids: Array) -> Array[Block]:
	var out: Array[Block] = []
	for id in ids:
		out.append(Block.new(id))
	return out


func _truck(capacity: int, ids: Array) -> Truck:
	return Truck.new(capacity, _blocks(ids))


func test_empty_truck_accepts_any_color() -> void:
	var truck := _truck(3, [])
	var sizes := {CubeColor.Id.RED: 1, CubeColor.Id.BLUE: 1}
	assert_true(truck.is_empty())
	assert_true(truck.can_accept(CubeColor.Id.RED, sizes))
	assert_true(truck.can_accept(CubeColor.Id.BLUE, sizes))


func test_empty_truck_refuses_claimed_color() -> void:
	var truck := _truck(3, [])
	var sizes := {CubeColor.Id.RED: 3, CubeColor.Id.BLUE: 1}
	var claimed := {CubeColor.Id.RED: true}
	assert_false(truck.can_accept(CubeColor.Id.RED, sizes, claimed))
	assert_true(truck.can_accept(CubeColor.Id.BLUE, sizes, claimed))


func test_top_match_still_accepts_claimed_color() -> void:
	var truck := _truck(3, [CubeColor.Id.RED])
	var sizes := {CubeColor.Id.RED: 3}
	var claimed := {CubeColor.Id.RED: true}
	assert_true(truck.can_accept(CubeColor.Id.RED, sizes, claimed))


func test_potential_completion_is_uniform_matching_capacity() -> void:
	var home := _truck(3, [CubeColor.Id.RED, CubeColor.Id.RED])
	var sizes := {CubeColor.Id.RED: 3, CubeColor.Id.BLUE: 5}
	assert_true(home.is_potential_completion(sizes))
	var parking := _truck(3, [CubeColor.Id.BLUE, CubeColor.Id.BLUE])
	assert_false(parking.is_potential_completion(sizes), "wrong capacity is not a claim")
	var mixed := _truck(3, [CubeColor.Id.RED, CubeColor.Id.BLUE])
	assert_false(mixed.is_potential_completion(sizes))
	var empty := _truck(3, [])
	assert_false(empty.is_potential_completion(sizes))
	var finished := _truck(3, [CubeColor.Id.RED, CubeColor.Id.RED, CubeColor.Id.RED])
	assert_true(finished.is_potential_completion(sizes))


func test_empty_top_color_is_none_and_run_length_is_zero() -> void:
	var truck := _truck(3, [])
	assert_eq(truck.top_color(), CubeColor.Id.NONE)
	assert_eq(truck.top_run_length(), 0)


func test_top_match_with_room_accepts() -> void:
	var truck := _truck(3, [CubeColor.Id.RED])
	var sizes := {CubeColor.Id.RED: 2}
	assert_true(truck.can_accept(CubeColor.Id.RED, sizes))
	assert_eq(truck.top_color(), CubeColor.Id.RED)
	assert_eq(truck.top_run_length(), 1)


func test_top_mismatch_with_room_rejects() -> void:
	var truck := _truck(3, [CubeColor.Id.RED])
	var sizes := {CubeColor.Id.RED: 1, CubeColor.Id.BLUE: 1}
	assert_false(truck.can_accept(CubeColor.Id.BLUE, sizes))


func test_top_run_length_counts_contiguous_from_top() -> void:
	var truck := _truck(4, [
		CubeColor.Id.BLUE,
		CubeColor.Id.RED,
		CubeColor.Id.RED,
		CubeColor.Id.RED,
	])
	assert_eq(truck.top_color(), CubeColor.Id.RED)
	assert_eq(truck.top_run_length(), 3)
	assert_false(truck.is_empty())


func test_unload_transfers_top_color_run_up_to_max_count_top_first() -> void:
	var blue := _block(CubeColor.Id.BLUE)
	var r1 := _block(CubeColor.Id.RED)
	var r2 := _block(CubeColor.Id.RED)
	var r3 := _block(CubeColor.Id.RED)
	var stacked: Array[Block] = []
	stacked.append(blue)
	stacked.append(r1)
	stacked.append(r2)
	stacked.append(r3)
	var truck := Truck.new(4, stacked)

	var taken := truck.unload(2)
	assert_eq(taken.size(), 2, "unload should transfer min(run, max_count)")
	if taken.size() < 2 or truck.blocks.size() < 2:
		return
	assert_same(taken[0], r3, "first unloaded block is the top")
	assert_same(taken[1], r2)
	assert_eq(truck.blocks.size(), 2)
	assert_same(truck.blocks[0], blue)
	assert_same(truck.blocks[1], r1)


func test_unload_does_not_take_past_the_top_run() -> void:
	var blue := _block(CubeColor.Id.BLUE)
	var r1 := _block(CubeColor.Id.RED)
	var r2 := _block(CubeColor.Id.RED)
	var stacked: Array[Block] = []
	stacked.append(blue)
	stacked.append(r1)
	stacked.append(r2)
	var truck := Truck.new(3, stacked)

	var taken := truck.unload(10)
	assert_eq(taken.size(), 2)
	assert_eq(truck.blocks.size(), 1)
	assert_same(truck.blocks[0], blue)


func test_receive_takes_ownership_of_the_same_block() -> void:
	var truck := _truck(3, [])
	var incoming := _block(CubeColor.Id.RED)
	var sizes := {CubeColor.Id.RED: 1}
	assert_true(truck.receive(incoming, sizes))
	assert_eq(truck.blocks.size(), 1)
	if truck.blocks.is_empty():
		return
	assert_same(truck.blocks[0], incoming)
	assert_eq(truck.top_color(), CubeColor.Id.RED)


func test_is_finished_only_when_full_uniform_and_capacity_matches_set_size() -> void:
	var truck := _truck(3, [CubeColor.Id.RED, CubeColor.Id.RED, CubeColor.Id.RED])
	var sizes := {CubeColor.Id.RED: 3}
	assert_true(truck.is_finished(sizes))
	assert_false(truck.can_accept(CubeColor.Id.RED, sizes), "finished truck cannot receive")


func test_five_slot_full_of_seven_count_color_is_not_finished() -> void:
	var ids := [
		CubeColor.Id.RED, CubeColor.Id.RED, CubeColor.Id.RED,
		CubeColor.Id.RED, CubeColor.Id.RED,
	]
	var truck := _truck(5, ids)
	var sizes := {CubeColor.Id.RED: 7}
	assert_false(truck.is_finished(sizes), "wrong-capacity full is parking, not finished")
	assert_false(truck.can_accept(CubeColor.Id.RED, sizes), "no room — not because of color")


func test_wrong_capacity_full_can_still_unload() -> void:
	var ids := [
		CubeColor.Id.RED, CubeColor.Id.RED, CubeColor.Id.RED,
		CubeColor.Id.RED, CubeColor.Id.RED,
	]
	var truck := _truck(5, ids)
	var sizes := {CubeColor.Id.RED: 7}
	assert_false(truck.is_finished(sizes))
	var taken := truck.unload(2)
	assert_eq(taken.size(), 2, "wrong-capacity full can still be excavated")
	assert_eq(truck.blocks.size(), 3)


func test_full_mixed_is_not_finished_and_cannot_receive() -> void:
	var truck := _truck(2, [CubeColor.Id.RED, CubeColor.Id.BLUE])
	var sizes := {CubeColor.Id.RED: 1, CubeColor.Id.BLUE: 1}
	var extra := _block(CubeColor.Id.BLUE)
	assert_false(truck.is_finished(sizes))
	assert_false(truck.can_accept(CubeColor.Id.BLUE, sizes))
	assert_false(truck.receive(extra, sizes))
	assert_eq(truck.blocks.size(), 2)


func test_finished_truck_cannot_receive() -> void:
	var truck := _truck(2, [CubeColor.Id.RED, CubeColor.Id.RED])
	var sizes := {CubeColor.Id.RED: 2}
	var extra := _block(CubeColor.Id.RED)
	assert_true(truck.is_finished(sizes))
	assert_false(truck.can_accept(CubeColor.Id.RED, sizes))
	assert_false(truck.receive(extra, sizes))
	assert_eq(truck.blocks.size(), 2)


func test_unload_on_empty_returns_no_blocks() -> void:
	var truck := _truck(3, [])
	var taken := truck.unload(2)
	assert_eq(taken.size(), 0)
	assert_true(truck.is_empty())
