class_name TutorialLevel2
extends RefCounted
## Second tutorial. Two capacity-5 trucks, one capacity-7, five red,
## five yellow, seven blue. Its authored transit capacity is 6; its eight
## visual belt positions are derived from its three trucks.


static func data() -> LevelData:
	var left: Array[CubeColor.Id] = [
		CubeColor.Id.RED,
		CubeColor.Id.YELLOW,
		CubeColor.Id.BLUE,
		CubeColor.Id.RED,
		CubeColor.Id.BLUE,
	]
	var mid: Array[CubeColor.Id] = [
		CubeColor.Id.RED,
		CubeColor.Id.YELLOW,
		CubeColor.Id.BLUE,
		CubeColor.Id.YELLOW,
		CubeColor.Id.BLUE,
	]
	var right: Array[CubeColor.Id] = [
		CubeColor.Id.BLUE,
		CubeColor.Id.RED,
		CubeColor.Id.BLUE,
		CubeColor.Id.YELLOW,
		CubeColor.Id.BLUE,
		CubeColor.Id.RED,
		CubeColor.Id.YELLOW,
	]
	var trucks: Array[LevelData.TruckSpec] = []
	trucks.append(LevelData.TruckSpec.new(5, left))
	trucks.append(LevelData.TruckSpec.new(5, mid))
	trucks.append(LevelData.TruckSpec.new(7, right))
	return LevelData.new(6, trucks, "tut2", "Tutorial 2")
