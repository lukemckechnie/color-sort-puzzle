class_name TutorialLevel
extends RefCounted
## First playable level. Two 5-slot trucks, five red and five yellow,
## alternating in each stack. Intended as the shipped tutorial.


static func data() -> LevelData:
	var left: Array[CubeColor.Id] = [
		CubeColor.Id.YELLOW,
		CubeColor.Id.RED,
		CubeColor.Id.YELLOW,
		CubeColor.Id.RED,
		CubeColor.Id.YELLOW,
	]
	var right: Array[CubeColor.Id] = [
		CubeColor.Id.RED,
		CubeColor.Id.YELLOW,
		CubeColor.Id.RED,
		CubeColor.Id.YELLOW,
		CubeColor.Id.RED,
	]
	var trucks: Array[LevelData.TruckSpec] = []
	trucks.append(LevelData.TruckSpec.new(5, left))
	trucks.append(LevelData.TruckSpec.new(5, right))
	# 5 is the minimum: one known line peaks at five cubes in transit.
	return LevelData.new(5, trucks, "tut1", "Tutorial")
