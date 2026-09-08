extends GutTest


func test_block_travels_from_one_truck_to_the_next_without_position_fields() -> void:
	var first := Truck.new(2, [Block.new(CubeColor.Id.RED)])
	var second := Truck.new(2)
	var conveyor := Conveyor.new(2, [first, second])
	var sizes := {CubeColor.Id.RED: 1}
	var unloaded := first.unload(1)
	assert_true(conveyor.load(unloaded, 0, sizes))
	assert_eq(conveyor.in_transit_count(), 1)
	assert_eq(conveyor.advance(1, sizes), Conveyor.AdvanceResult.ADVANCED)
	assert_eq(conveyor.in_transit_count(), 0)
	assert_eq(second.top_color(), CubeColor.Id.RED)
