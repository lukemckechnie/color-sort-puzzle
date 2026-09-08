extends GutTest


func test_tutorial_two_uses_six_transit_slots_and_eight_derived_positions() -> void:
	var data := TutorialLevel2.data()
	assert_eq(data.validation_error(), "")
	assert_eq(data.conveyor_capacity, 6)
	var level := Level.try_create(data)
	assert_not_null(level)
	if level != null:
		assert_eq(level.conveyor().belt_position_count, 8)
