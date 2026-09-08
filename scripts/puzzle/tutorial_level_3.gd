class_name TutorialLevel3
extends RefCounted
## Third tutorial. Three capacity-5 trucks and one capacity-7 truck. Its
## authored transit capacity is 7; its ten visual belt positions are derived
## from its four trucks.


static func data() -> LevelData:
	var left: Array[CubeColor.Id] = [
		CubeColor.Id.RED,
		CubeColor.Id.YELLOW,
		CubeColor.Id.GREEN,
		CubeColor.Id.RED,
		CubeColor.Id.BLUE,
	]
	var mid: Array[CubeColor.Id] = [
		CubeColor.Id.GREEN,
		CubeColor.Id.YELLOW,
		CubeColor.Id.BLUE,
		CubeColor.Id.YELLOW,
		CubeColor.Id.BLUE,
	]
	var mid2: Array[CubeColor.Id] = [
		CubeColor.Id.GREEN,
		CubeColor.Id.BLUE,
		CubeColor.Id.YELLOW,
		CubeColor.Id.RED,
		CubeColor.Id.BLUE,
	]
	var right: Array[CubeColor.Id] = [
		CubeColor.Id.GREEN,
		CubeColor.Id.RED,
		CubeColor.Id.BLUE,
		CubeColor.Id.GREEN,
		CubeColor.Id.BLUE,
		CubeColor.Id.RED,
		CubeColor.Id.YELLOW,
	]

	var trucks: Array[LevelData.TruckSpec] = []
	trucks.append(LevelData.TruckSpec.new(5, left))
	trucks.append(LevelData.TruckSpec.new(5, mid))
	trucks.append(LevelData.TruckSpec.new(5, mid2))
	trucks.append(LevelData.TruckSpec.new(7, right))
	return LevelData.new(7, trucks, "tut3", "Tutorial 3")
