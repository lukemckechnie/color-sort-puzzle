extends GutTest


func _colors(ids: Array) -> Array[CubeColor.Id]:
	var result: Array[CubeColor.Id] = []
	for id in ids:
		result.append(id)
	return result


func _spec(capacity: int, ids: Array = []) -> LevelData.TruckSpec:
	return LevelData.TruckSpec.new(capacity, _colors(ids))


func test_valid_data_has_only_capacity_and_truck_specs() -> void:
	var data := LevelData.new(4, [_spec(2, [CubeColor.Id.RED]), _spec(2)])
	assert_eq(data.validation_error(), "")
	assert_eq(data.conveyor_capacity, 4)
	assert_eq(data.trucks.size(), 2)


func test_conveyor_capacity_must_be_positive() -> void:
	var data := LevelData.new(0, [_spec(2)])
	assert_eq(data.validation_error(), LevelData.ERR_CONVEYOR_CAPACITY)


func test_empty_trucks_and_bad_stack_specs_are_rejected() -> void:
	assert_eq(LevelData.new(1, []).validation_error(), LevelData.ERR_EMPTY_TRUCKS)
	assert_eq(LevelData.new(1, [_spec(0)]).validation_error(), LevelData.ERR_CAPACITY)
	assert_eq(
		LevelData.new(1, [_spec(1, [CubeColor.Id.RED, CubeColor.Id.BLUE])]).validation_error(),
		LevelData.ERR_STACK_LENGTH
	)
	assert_eq(
		LevelData.new(1, [_spec(1, [CubeColor.Id.NONE])]).validation_error(),
		LevelData.ERR_NONE_IN_STACK
	)
