class_name TutorialLevel4
extends RefCounted
## Anchored blue tutorial. See docs/LEVEL_SELECT.md.


static func data() -> LevelData:
	var first: Array[CubeColor.Id] = [
		CubeColor.Id.RED,
		CubeColor.Id.YELLOW,
		CubeColor.Id.GREEN,
		CubeColor.Id.RED,
		CubeColor.Id.GREEN,
	]
	var second: Array[CubeColor.Id] = [
		CubeColor.Id.GREEN,
		CubeColor.Id.YELLOW,
		CubeColor.Id.BLUE,
		CubeColor.Id.YELLOW,
		CubeColor.Id.BLUE,
	]
	var third: Array[CubeColor.Id] = [
		CubeColor.Id.GREEN,
		CubeColor.Id.BLUE,
		CubeColor.Id.YELLOW,
		CubeColor.Id.RED,
		CubeColor.Id.BLUE,
	]
	var blue_anchor: Array[CubeColor.Id] = [
		CubeColor.Id.BLUE,
		CubeColor.Id.RED,
		CubeColor.Id.BLUE,
		CubeColor.Id.GREEN,
		CubeColor.Id.BLUE,
		CubeColor.Id.RED,
		CubeColor.Id.YELLOW,
	]
	var trucks: Array[LevelData.TruckSpec] = []
	trucks.append(LevelData.TruckSpec.new(5, first))
	trucks.append(LevelData.TruckSpec.new(5, second))
	trucks.append(LevelData.TruckSpec.new(5, third))
	trucks.append(LevelData.TruckSpec.new(7, blue_anchor))
	return LevelData.new(6, trucks, "tut4", "Tutorial 4")
