extends GutTest


func _blocks(colors: Array) -> Array[Block]:
	var result: Array[Block] = []
	for color in colors:
		result.append(Block.new(color))
	return result


func test_belt_positions_are_derived_from_trucks_and_capacity() -> void:
	var trucks: Array[Truck] = [Truck.new(3), Truck.new(3)]
	var from_trucks := Conveyor.new(3, trucks)
	assert_eq(from_trucks.belt_position_count, 6)
	assert_eq(from_trucks.offer_position(0), 1)
	assert_eq(from_trucks.offer_position(1), 3)
	assert_eq(from_trucks.exit_position(0), 2)
	assert_eq(from_trucks.exit_position(1), 4)

	var from_capacity := Conveyor.new(10, trucks)
	assert_eq(from_capacity.belt_position_count, 10)


func test_load_places_blocks_after_the_source_truck() -> void:
	var conveyor := Conveyor.new(2, [Truck.new(2), Truck.new(2)])
	var block := Block.new(CubeColor.Id.RED)
	assert_true(conveyor.load([block], 0, {CubeColor.Id.RED: 1}))
	assert_eq(conveyor.position_of(block), conveyor.exit_position(0))
	assert_same(conveyor.block_at(conveyor.exit_position(0)), block)


func test_load_refuses_to_exceed_conveyor_capacity() -> void:
	var conveyor := Conveyor.new(1, [Truck.new(2), Truck.new(2)])
	var first := Block.new(CubeColor.Id.RED)
	var second := Block.new(CubeColor.Id.BLUE)
	assert_true(conveyor.load([first], 0, {}))
	assert_false(conveyor.load([second], 1, {}))
	assert_eq(conveyor.in_transit_count(), 1)


func test_displaced_block_is_offered_when_pushed_onto_a_truck() -> void:
	var receiver := Truck.new(2)
	var conveyor := Conveyor.new(3, [Truck.new(3), receiver])
	var first := Block.new(CubeColor.Id.RED)
	var second := Block.new(CubeColor.Id.RED)
	var sizes := {CubeColor.Id.RED: 2}
	assert_true(conveyor.load([first], 0, sizes))
	assert_true(conveyor.load([second], 0, sizes))
	assert_eq(conveyor.in_transit_count(), 1)
	assert_same(receiver.blocks[0], first)
	assert_same(conveyor.block_at(conveyor.exit_position(0)), second)


func test_blocks_move_simultaneously_to_the_next_derived_position() -> void:
	var source := Truck.new(3)
	var blocker := Truck.new(1, _blocks([CubeColor.Id.BLUE]))
	var conveyor := Conveyor.new(3, [source, blocker])
	var first := Block.new(CubeColor.Id.RED)
	var second := Block.new(CubeColor.Id.RED)
	var sizes := {CubeColor.Id.RED: 2, CubeColor.Id.BLUE: 1}
	assert_true(conveyor.load([first], 0, sizes))
	assert_true(conveyor.load([second], 0, sizes))
	assert_eq(conveyor.position_of(first), 3)
	assert_eq(conveyor.position_of(second), 2)

	assert_eq(conveyor.advance(1, sizes), Conveyor.AdvanceResult.ADVANCED)
	assert_eq(conveyor.position_of(first), 4)
	assert_eq(conveyor.position_of(second), 3)


func test_arriving_block_is_offered_to_the_truck_at_that_position() -> void:
	var source := Truck.new(2)
	var receiver := Truck.new(2)
	var conveyor := Conveyor.new(2, [source, receiver])
	var block := Block.new(CubeColor.Id.RED)
	var sizes := {CubeColor.Id.RED: 1}
	assert_true(conveyor.load([block], 0, sizes))
	assert_eq(conveyor.advance(1, sizes), Conveyor.AdvanceResult.ADVANCED)
	assert_eq(conveyor.in_transit_count(), 0)
	assert_same(receiver.blocks[0], block)
