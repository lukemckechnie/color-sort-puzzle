extends GutTest


func _colors(ids: Array) -> Array[CubeColor.Id]:
	var result: Array[CubeColor.Id] = []
	for id in ids:
		result.append(id)
	return result


func _data(capacity: int, stacks: Array) -> LevelData:
	var trucks: Array[LevelData.TruckSpec] = []
	for stack in stacks:
		trucks.append(LevelData.TruckSpec.new(2, _colors(stack)))
	return LevelData.new(capacity, trucks)


func test_create_derives_belt_positions_from_capacity_and_truck_count() -> void:
	var level := Level.try_create(_data(8, [[], []]))
	assert_not_null(level)
	if level != null:
		assert_eq(level.conveyor().belt_position_count, 8)


func test_tap_unloads_a_top_color_run_up_to_capacity() -> void:
	var level := Level.try_create(_data(1, [[CubeColor.Id.RED, CubeColor.Id.BLUE], []]))
	assert_not_null(level)
	if level == null:
		return
	assert_eq(level.tap(0), Level.TapResult.ACCEPTED)
	assert_eq(level.conveyor().in_transit_count(), 1)
	assert_eq(level.conveyor().trucks[0].blocks.size(), 1)
	assert_eq(level.tap(0), Level.TapResult.CONVEYOR_FULL)


func test_tap_rejects_invalid_and_empty_trucks() -> void:
	var level := Level.try_create(_data(2, [[], []]))
	assert_not_null(level)
	if level == null:
		return
	assert_eq(level.tap(-1), Level.TapResult.INVALID_INDEX)
	assert_eq(level.tap(0), Level.TapResult.EMPTY)
