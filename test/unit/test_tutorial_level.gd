extends GutTest


func test_tutorial_one_uses_capacity_as_the_only_belt_authoring_value() -> void:
	var data := TutorialLevel.data()
	assert_eq(data.validation_error(), "")
	assert_eq(data.conveyor_capacity, 5)
	assert_eq(data.trucks.size(), 2)
	var level := Level.try_create(data)
	assert_not_null(level)
	if level != null:
		assert_eq(level.conveyor().belt_position_count, 6)

