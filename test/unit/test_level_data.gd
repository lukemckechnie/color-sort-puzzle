extends GutTest
## LevelData.validation_error — exact ERR_* reasons.


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


func _valid() -> LevelData:
	return _data(3, 4, [
		_spec(2, 0, [CubeColor.Id.RED, CubeColor.Id.BLUE]),
		_spec(5, 2, [CubeColor.Id.GREEN]),
	])


func test_valid_level_has_empty_validation_error() -> void:
	assert_eq(_valid().validation_error(), "")


func test_valid_allows_empty_truck_and_mixed_capacities() -> void:
	var data := _data(1, 4, [
		_spec(3, 0, []),
		_spec(7, 2, [CubeColor.Id.RED]),
	])
	assert_eq(data.validation_error(), "")


func test_valid_stacks_at_exact_per_truck_capacity() -> void:
	var data := _data(2, 4, [
		_spec(2, 0, [CubeColor.Id.RED, CubeColor.Id.RED]),
		_spec(1, 2, [CubeColor.Id.BLUE]),
	])
	assert_eq(data.validation_error(), "")


func test_capacity_zero_is_invalid() -> void:
	var data := _data(2, 4, [
		_spec(0, 0, []),
		_spec(2, 2, [CubeColor.Id.RED]),
	])
	assert_eq(data.validation_error(), LevelData.ERR_CAPACITY)


func test_capacity_negative_is_invalid() -> void:
	var data := _data(2, 4, [
		_spec(-1, 0, []),
		_spec(2, 2, [CubeColor.Id.RED]),
	])
	assert_eq(data.validation_error(), LevelData.ERR_CAPACITY)


func test_conveyor_max_zero_is_invalid() -> void:
	var data := _data(0, 4, [
		_spec(2, 0, [CubeColor.Id.RED]),
	])
	assert_eq(data.validation_error(), LevelData.ERR_CONVEYOR_MAX)


func test_slot_count_zero_is_invalid() -> void:
	var data := _data(2, 0, [
		_spec(2, 0, [CubeColor.Id.RED]),
	])
	assert_eq(data.validation_error(), LevelData.ERR_SLOT_COUNT)


func test_slot_count_negative_is_invalid() -> void:
	var data := _data(2, -1, [
		_spec(2, 0, [CubeColor.Id.RED]),
	])
	assert_eq(data.validation_error(), LevelData.ERR_SLOT_COUNT)


func test_stack_longer_than_that_truck_capacity_is_invalid() -> void:
	var data := _data(2, 4, [
		_spec(2, 0, [CubeColor.Id.RED, CubeColor.Id.BLUE, CubeColor.Id.GREEN]),
		_spec(2, 2, []),
	])
	assert_eq(data.validation_error(), LevelData.ERR_STACK_LENGTH)


func test_empty_trucks_list_is_invalid() -> void:
	var data := _data(2, 4, [])
	assert_eq(data.validation_error(), LevelData.ERR_EMPTY_TRUCKS)


func test_duplicate_positions_are_invalid() -> void:
	var data := _data(2, 4, [
		_spec(2, 0, [CubeColor.Id.RED]),
		_spec(2, 0, [CubeColor.Id.BLUE]),
	])
	assert_eq(data.validation_error(), LevelData.ERR_DUPLICATE_POSITION)


func test_none_in_starting_stack_is_invalid() -> void:
	var data := _data(2, 4, [
		_spec(2, 0, [CubeColor.Id.RED, CubeColor.Id.NONE]),
		_spec(2, 2, []),
	])
	assert_eq(data.validation_error(), LevelData.ERR_NONE_IN_STACK)


func test_position_equal_to_slot_count_is_invalid() -> void:
	var data := _data(2, 4, [
		_spec(2, 4, [CubeColor.Id.RED]),
	])
	assert_eq(data.validation_error(), LevelData.ERR_POSITION_RANGE)


func test_negative_position_is_invalid() -> void:
	var data := _data(2, 4, [
		_spec(2, -1, [CubeColor.Id.RED]),
	])
	assert_eq(data.validation_error(), LevelData.ERR_POSITION_RANGE)
