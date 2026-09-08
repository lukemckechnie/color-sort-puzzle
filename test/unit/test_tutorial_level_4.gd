extends GutTest
## Tutorial 4 keeps a blue anchor in the seven-slot truck.


const TutorialLevel4Data := preload("res://scripts/puzzle/tutorial_level_4.gd")


func test_tutorial_four_uses_six_transit_slots_and_ten_derived_positions() -> void:
	var data := TutorialLevel4Data.data()
	assert_not_null(data, "Tutorial 4 provides level data")
	if data == null:
		return
	assert_eq(data.validation_error(), "")
	assert_eq(data.id, "tut4")
	assert_eq(data.title, "Tutorial 4")
	assert_eq(data.conveyor_capacity, 6)
	assert_eq(data.trucks.size(), 4)
	assert_eq(data.trucks[0].stack, [
		CubeColor.Id.RED,
		CubeColor.Id.YELLOW,
		CubeColor.Id.GREEN,
		CubeColor.Id.RED,
		CubeColor.Id.GREEN,
	])
	assert_eq(data.trucks[1].stack, [
		CubeColor.Id.GREEN,
		CubeColor.Id.YELLOW,
		CubeColor.Id.BLUE,
		CubeColor.Id.YELLOW,
		CubeColor.Id.BLUE,
	])
	assert_eq(data.trucks[2].stack, [
		CubeColor.Id.GREEN,
		CubeColor.Id.BLUE,
		CubeColor.Id.YELLOW,
		CubeColor.Id.RED,
		CubeColor.Id.BLUE,
	])
	assert_eq(data.trucks[3].capacity, 7)
	assert_eq(data.trucks[3].stack, [
		CubeColor.Id.BLUE,
		CubeColor.Id.RED,
		CubeColor.Id.BLUE,
		CubeColor.Id.GREEN,
		CubeColor.Id.BLUE,
		CubeColor.Id.RED,
		CubeColor.Id.YELLOW,
	])
	var level := Level.try_create(data)
	assert_not_null(level)
	if level != null:
		assert_eq(level.conveyor().belt_position_count, 10)
