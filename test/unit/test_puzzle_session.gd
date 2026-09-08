extends GutTest


func test_try_create_valid_returns_session_with_a_level() -> void:
	var trucks: Array[LevelData.TruckSpec] = [
		LevelData.TruckSpec.new(2, [CubeColor.Id.RED]),
		LevelData.TruckSpec.new(2, [CubeColor.Id.BLUE]),
	]
	var session := PuzzleSession.try_create(LevelData.new(2, trucks))
	assert_not_null(session)
	if session != null:
		assert_not_null(session.current_level())


func test_try_create_invalid_returns_null() -> void:
	assert_null(PuzzleSession.try_create(LevelData.new(0, [])))
