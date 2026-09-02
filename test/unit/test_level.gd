extends GutTest
## Level facade — try_create, tap, advance, win/loss.


func _colors(ids: Array) -> Array[CubeColor.Id]:
	var stack: Array[CubeColor.Id] = []
	for id in ids:
		stack.append(id)
	return stack


func _spec(capacity: int, position: int, ids: Array) -> LevelData.TruckSpec:
	return LevelData.TruckSpec.new(capacity, position, _colors(ids))


func _data(conveyor_max: int, slot_count: int, specs: Array) -> LevelData:
	var trucks: Array[LevelData.TruckSpec] = []
	for spec in specs:
		trucks.append(spec)
	return LevelData.new(conveyor_max, slot_count, trucks)


func _playable() -> LevelData:
	return _data(2, 4, [
		_spec(2, 0, [CubeColor.Id.RED]),
		_spec(2, 2, [CubeColor.Id.RED]),
	])


func _require_level(data: LevelData) -> Level:
	var level := Level.try_create(data)
	assert_not_null(level, "try_create should return a Level for valid LevelData")
	return level


func test_try_create_valid_returns_level_with_set_sizes_and_conveyor() -> void:
	var level := _require_level(_playable())
	if level == null:
		return
	assert_not_null(level.conveyor())
	if level.conveyor() == null:
		return
	var sizes: Dictionary = level.set_sizes()
	assert_eq(sizes.get(CubeColor.Id.RED), 2)
	assert_eq(level.conveyor().trucks.size(), 2)
	assert_eq(level.conveyor().slot_count, 4)
	assert_eq(level.status(), Level.Status.PLAYING)


func test_try_create_copies_starting_stacks_bottom_first() -> void:
	var data := _data(3, 4, [
		_spec(3, 0, [CubeColor.Id.BLUE, CubeColor.Id.RED, CubeColor.Id.RED]),
		_spec(3, 2, []),
	])
	var level := _require_level(data)
	if level == null or level.conveyor() == null:
		return
	var truck: Truck = level.conveyor().trucks[0]
	assert_eq(truck.blocks.size(), 3)
	assert_eq(truck.blocks[0].color, CubeColor.Id.BLUE)
	assert_eq(truck.blocks[1].color, CubeColor.Id.RED)
	assert_eq(truck.blocks[2].color, CubeColor.Id.RED)
	assert_eq(truck.capacity, 3)
	assert_eq(truck.position, 0)


func test_try_create_invalid_returns_null() -> void:
	var invalid := _data(0, 4, [
		_spec(2, 0, [CubeColor.Id.RED]),
	])
	assert_null(Level.try_create(invalid))


func test_tap_unloads_contiguous_top_run_capped_by_conveyor_space() -> void:
	var data := _data(2, 8, [
		_spec(4, 0, [
			CubeColor.Id.BLUE,
			CubeColor.Id.RED,
			CubeColor.Id.RED,
			CubeColor.Id.RED,
		]),
		_spec(4, 4, []),
		_spec(4, 6, []),
	])
	var level := _require_level(data)
	if level == null or level.conveyor() == null:
		return
	var truck: Truck = level.conveyor().trucks[0]
	if truck.blocks.size() < 4:
		return
	var leftover_red: Block = truck.blocks[1]
	var first_popped: Block = truck.blocks[3]
	var second_popped: Block = truck.blocks[2]

	assert_eq(level.tap(0), Level.TapResult.ACCEPTED)
	assert_eq(level.last_tap_result(), Level.TapResult.ACCEPTED)
	assert_eq(truck.blocks.size(), 2, "leftover same-color stay on the truck")
	assert_eq(truck.blocks[0].color, CubeColor.Id.BLUE)
	assert_same(truck.blocks[1], leftover_red)
	assert_eq(level.conveyor().in_transit.size(), 2)
	assert_true(level.conveyor().in_transit.has(first_popped))
	assert_true(level.conveyor().in_transit.has(second_popped))
	assert_eq(second_popped.position, 1)
	assert_eq(first_popped.position, 2)


func test_two_unloaded_blocks_first_popped_is_ahead() -> void:
	# Destinations are full of another color so this test can assert
	# positions without those trucks receiving.
	var data := _data(2, 8, [
		_spec(3, 0, [CubeColor.Id.BLUE, CubeColor.Id.RED, CubeColor.Id.RED]),
		_spec(2, 4, [CubeColor.Id.BLUE, CubeColor.Id.BLUE]),
		_spec(2, 6, [CubeColor.Id.BLUE, CubeColor.Id.BLUE]),
	])
	var level := _require_level(data)
	if level == null or level.conveyor() == null:
		return
	var source: Truck = level.conveyor().trucks[0]
	if source.blocks.size() < 2:
		return
	var first_popped: Block = source.blocks[source.blocks.size() - 1]
	var second_popped: Block = source.blocks[source.blocks.size() - 2]

	assert_eq(level.tap(0), Level.TapResult.ACCEPTED)
	assert_eq(second_popped.position, 1)
	assert_eq(first_popped.position, 2)
	assert_eq(level.advance(2), Conveyor.AdvanceResult.ADVANCED)
	assert_eq(first_popped.position, 4)
	assert_eq(second_popped.position, 3)


func test_two_unloaded_same_color_split_across_two_destination_trucks() -> void:
	# Each destination has room for exactly one. First popped is ahead,
	# fills the nearer truck; the trailer is refused there and continues.
	var data := _data(2, 8, [
		_spec(2, 0, [CubeColor.Id.RED, CubeColor.Id.RED]),
		_spec(1, 3, []),
		_spec(1, 6, []),
	])
	var level := _require_level(data)
	if level == null or level.conveyor() == null:
		return
	var source: Truck = level.conveyor().trucks[0]
	var nearer: Truck = level.conveyor().trucks[1]
	var farther: Truck = level.conveyor().trucks[2]
	if source.blocks.size() < 2:
		return
	var first_popped: Block = source.blocks[source.blocks.size() - 1]
	var second_popped: Block = source.blocks[source.blocks.size() - 2]

	assert_eq(level.tap(0), Level.TapResult.ACCEPTED)
	assert_eq(second_popped.position, 1)
	assert_eq(first_popped.position, 2)

	assert_eq(level.advance(1), Conveyor.AdvanceResult.ADVANCED)
	assert_eq(level.conveyor().in_transit.size(), 1)
	assert_eq(nearer.blocks.size(), 1)
	assert_same(nearer.blocks[0], first_popped)
	assert_eq(second_popped.position, 2)
	assert_eq(farther.blocks.size(), 0)

	assert_eq(level.advance(4), Conveyor.AdvanceResult.ADVANCED)
	assert_eq(level.conveyor().in_transit.size(), 0)
	assert_eq(nearer.blocks.size(), 1)
	assert_same(nearer.blocks[0], first_popped)
	assert_eq(farther.blocks.size(), 1)
	assert_same(farther.blocks[0], second_popped)
	assert_true(source.is_empty())
	assert_eq(level.status(), Level.Status.PLAYING)


func test_tap_offers_immediately_when_next_slot_is_a_truck() -> void:
	var data := _data(2, 4, [
		_spec(1, 0, [CubeColor.Id.RED]),
		_spec(1, 1, []),
	])
	var level := _require_level(data)
	if level == null or level.conveyor() == null:
		return
	var source: Truck = level.conveyor().trucks[0]
	var neighbor: Truck = level.conveyor().trucks[1]
	if source.blocks.is_empty():
		return
	var cube: Block = source.blocks[0]

	assert_eq(level.tap(0), Level.TapResult.ACCEPTED)
	assert_eq(level.conveyor().in_transit.size(), 0)
	assert_true(source.is_empty())
	assert_eq(neighbor.blocks.size(), 1)
	assert_same(neighbor.blocks[0], cube)
	assert_eq(level.status(), Level.Status.WON, "receive during load can win")


func test_win_when_no_transit_and_every_truck_empty_or_finished() -> void:
	var level := _require_level(_playable())
	if level == null:
		return
	assert_eq(level.tap(0), Level.TapResult.ACCEPTED)
	assert_eq(level.status(), Level.Status.PLAYING, "win is not evaluated on tap")
	assert_eq(level.advance(1), Conveyor.AdvanceResult.ADVANCED)
	assert_eq(level.status(), Level.Status.WON, "win is evaluated on receive")
	assert_eq(level.conveyor().in_transit.size(), 0)
	assert_true(level.conveyor().trucks[0].is_empty())
	assert_true(level.conveyor().trucks[1].is_finished(level.set_sizes()))


func test_after_receive_player_can_tap_again_if_no_longer_at_max() -> void:
	var data := _data(1, 4, [
		_spec(3, 0, [CubeColor.Id.RED, CubeColor.Id.RED]),
		_spec(3, 2, []),
	])
	var level := _require_level(data)
	if level == null:
		return
	assert_eq(level.tap(0), Level.TapResult.ACCEPTED)
	assert_eq(level.tap(0), Level.TapResult.CONVEYOR_FULL)
	assert_eq(level.status(), Level.Status.PLAYING)
	assert_eq(level.advance(1), Conveyor.AdvanceResult.ADVANCED)
	assert_eq(level.tap(0), Level.TapResult.ACCEPTED)
	assert_eq(level.last_tap_result(), Level.TapResult.ACCEPTED)


func test_tap_out_of_range_is_invalid_index_and_does_not_change_state() -> void:
	var level := _require_level(_playable())
	if level == null or level.conveyor() == null:
		return
	var truck: Truck = level.conveyor().trucks[0]
	var before := truck.blocks.size()
	assert_eq(level.tap(-1), Level.TapResult.INVALID_INDEX)
	assert_eq(level.last_tap_result(), Level.TapResult.INVALID_INDEX)
	assert_eq(truck.blocks.size(), before)
	assert_eq(level.conveyor().in_transit.size(), 0)
	assert_eq(level.tap(99), Level.TapResult.INVALID_INDEX)
	assert_eq(truck.blocks.size(), before)


func test_tap_finished_truck_is_rejected_with_no_state_change() -> void:
	var data := _data(2, 4, [
		_spec(2, 0, [CubeColor.Id.RED, CubeColor.Id.RED]),
		_spec(2, 2, [CubeColor.Id.BLUE]),
	])
	var level := _require_level(data)
	if level == null or level.conveyor() == null:
		return
	var finished: Truck = level.conveyor().trucks[0]
	assert_true(finished.is_finished(level.set_sizes()))
	assert_eq(level.tap(0), Level.TapResult.FINISHED)
	assert_eq(level.last_tap_result(), Level.TapResult.FINISHED)
	assert_eq(finished.blocks.size(), 2)
	assert_eq(level.conveyor().in_transit.size(), 0)


func test_tap_empty_truck_is_rejected_with_no_state_change() -> void:
	var data := _data(2, 4, [
		_spec(2, 0, []),
		_spec(2, 2, [CubeColor.Id.RED]),
	])
	var level := _require_level(data)
	if level == null:
		return
	assert_eq(level.tap(0), Level.TapResult.EMPTY)
	assert_eq(level.last_tap_result(), Level.TapResult.EMPTY)
	assert_eq(level.conveyor().trucks[0].blocks.size(), 0)
	assert_eq(level.conveyor().in_transit.size(), 0)


func test_tap_when_conveyor_at_max_is_rejected_and_is_not_a_loss() -> void:
	var data := _data(1, 8, [
		_spec(2, 0, [CubeColor.Id.GREEN]),
		_spec(2, 3, []),
		_spec(2, 6, [CubeColor.Id.RED]),
	])
	var level := _require_level(data)
	if level == null:
		return
	assert_eq(level.tap(0), Level.TapResult.ACCEPTED)
	assert_eq(level.status(), Level.Status.PLAYING, "full conveyor is not itself a loss")
	var red_count_before: int = level.conveyor().trucks[2].blocks.size()
	assert_eq(level.tap(2), Level.TapResult.CONVEYOR_FULL)
	assert_eq(level.last_tap_result(), Level.TapResult.CONVEYOR_FULL)
	assert_eq(level.conveyor().trucks[2].blocks.size(), red_count_before)
	assert_eq(level.status(), Level.Status.PLAYING)


func test_loss_only_when_at_max_and_no_in_transit_block_can_exit() -> void:
	var data := _data(1, 4, [
		_spec(2, 0, [CubeColor.Id.RED, CubeColor.Id.GREEN]),
		_spec(2, 2, [CubeColor.Id.BLUE, CubeColor.Id.BLUE]),
	])
	var level := _require_level(data)
	if level == null:
		return
	assert_eq(level.tap(0), Level.TapResult.ACCEPTED)
	assert_eq(level.status(), Level.Status.LOST)
	assert_eq(level.conveyor().in_transit.size(), 1)
	assert_false(level.conveyor().any_block_can_exit(level.set_sizes()))


func test_five_slot_full_of_seven_color_is_not_a_win() -> void:
	var five_reds := [
		CubeColor.Id.RED, CubeColor.Id.RED, CubeColor.Id.RED,
		CubeColor.Id.RED, CubeColor.Id.RED,
	]
	var data := _data(2, 4, [
		_spec(5, 0, five_reds),
		_spec(2, 2, [CubeColor.Id.RED, CubeColor.Id.RED]),
	])
	var level := _require_level(data)
	if level == null:
		return
	assert_ne(level.status(), Level.Status.WON)
	assert_eq(level.status(), Level.Status.PLAYING)
	assert_false(level.conveyor().trucks[0].is_finished(level.set_sizes()))


func test_advance_zero_is_invalid_and_does_not_move() -> void:
	var data := _data(2, 4, [
		_spec(3, 0, [CubeColor.Id.RED]),
		_spec(3, 2, []),
	])
	var level := _require_level(data)
	if level == null:
		return
	assert_eq(level.tap(0), Level.TapResult.ACCEPTED)
	if level.conveyor() == null or level.conveyor().in_transit.is_empty():
		return
	var cube: Block = level.conveyor().in_transit[0]
	var pos := cube.position
	assert_eq(level.advance(0), Conveyor.AdvanceResult.INVALID_TICKS)
	assert_eq(cube.position, pos)
	assert_eq(level.conveyor().in_transit.size(), 1)
