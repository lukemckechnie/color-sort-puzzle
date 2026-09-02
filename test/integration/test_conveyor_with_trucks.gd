extends GutTest
## Conveyor + real Truck. Truck bugs may fail these; unit tests mock Truck.


func _colors(ids: Array) -> Array[Block]:
	var out: Array[Block] = []
	for id in ids:
		out.append(Block.new(id))
	return out


func test_real_truck_accepts_when_empty() -> void:
	var t0 := Truck.new(3, 0, [])
	var t1 := Truck.new(3, 3, [])
	var trucks: Array[Truck] = []
	trucks.append(t0)
	trucks.append(t1)
	var conv := Conveyor.new(3, 8, trucks)
	var cube := Block.new(CubeColor.Id.RED)
	var one: Array[Block] = []
	one.append(cube)
	var sizes := {CubeColor.Id.RED: 1}

	assert_true(conv.load(one, 0))
	assert_eq(conv.advance(2, sizes), Conveyor.AdvanceResult.ADVANCED)
	assert_eq(conv.in_transit.size(), 0)
	assert_eq(t1.blocks.size(), 1)
	if t1.blocks.is_empty():
		return
	assert_same(t1.blocks[0], cube)


func test_real_truck_rejects_top_mismatch() -> void:
	var t0 := Truck.new(3, 0, [])
	var t1 := Truck.new(2, 3, _colors([CubeColor.Id.BLUE, CubeColor.Id.BLUE]))
	var trucks: Array[Truck] = []
	trucks.append(t0)
	trucks.append(t1)
	var conv := Conveyor.new(3, 8, trucks)
	var cube := Block.new(CubeColor.Id.RED)
	var one: Array[Block] = []
	one.append(cube)
	var sizes := {CubeColor.Id.RED: 1, CubeColor.Id.BLUE: 2}

	assert_true(conv.load(one, 0))
	assert_eq(conv.advance(2, sizes), Conveyor.AdvanceResult.ADVANCED)
	assert_eq(conv.in_transit.size(), 1)
	assert_eq(cube.position, 3)
	assert_eq(t1.blocks.size(), 2)
