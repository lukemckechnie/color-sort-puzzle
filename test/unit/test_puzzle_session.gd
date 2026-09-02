extends GutTest
## Thin PuzzleSession construction only. history() schema is unspecified.


func _colors(ids: Array) -> Array[CubeColor.Id]:
	var stack: Array[CubeColor.Id] = []
	for id in ids:
		stack.append(id)
	return stack


func _valid_data() -> LevelData:
	var trucks: Array[LevelData.TruckSpec] = []
	trucks.append(LevelData.TruckSpec.new(2, 0, _colors([CubeColor.Id.RED])))
	trucks.append(LevelData.TruckSpec.new(2, 2, _colors([CubeColor.Id.BLUE])))
	return LevelData.new(2, 4, trucks)


func test_try_create_valid_returns_session_with_a_level() -> void:
	var session := PuzzleSession.try_create(_valid_data())
	assert_not_null(session)
	if session == null:
		return
	assert_not_null(session.current_level())
	assert_false(session.levels().is_empty())
	assert_gt(session.levels().size(), 0)


func test_try_create_invalid_returns_null() -> void:
	var trucks: Array[LevelData.TruckSpec] = []
	var bad := LevelData.new(0, 4, trucks)
	assert_null(PuzzleSession.try_create(bad))
