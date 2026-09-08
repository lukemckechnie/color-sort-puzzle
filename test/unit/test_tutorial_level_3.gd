extends GutTest
## Tutorial 3's authored transit limit is independent of its visual belt size.


func test_tutorial_three_uses_seven_transit_slots_and_ten_derived_positions() -> void:
	var data := TutorialLevel3.data()
	assert_eq(data.validation_error(), "")
	assert_eq(data.conveyor_capacity, 7)
	var level := Level.try_create(data)
	assert_not_null(level)
	if level != null:
		assert_eq(level.conveyor().belt_position_count, 10)
