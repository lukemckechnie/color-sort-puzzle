extends SceneTree
## Replay the solver path on a real Level.


const PATH := "T0 T0 T0 T0 A A A A A A A A A A A T0 A A A A A T2 A A A A T1 T1 A A A A A A A A T1 T1 A A A A A A A A A A A A T2 A A A A A A A T2 T2 A A A A A A A T1 A A A A T2 A A A A A A T2 A A A A A A T2 A A A A A A A T2 T2 A A A A A A A A A A A A T1 A A A A T1 A A A A T1 A A A A T1 A A A A T1 A A A A A A A A A"


func _init() -> void:
	_replay(6)
	quit()


func _tut2(conveyor_capacity: int) -> LevelData:
	var t0: Array[CubeColor.Id] = [
		CubeColor.Id.RED, CubeColor.Id.YELLOW, CubeColor.Id.BLUE,
		CubeColor.Id.RED, CubeColor.Id.BLUE,
	]
	var t1: Array[CubeColor.Id] = [
		CubeColor.Id.RED, CubeColor.Id.YELLOW, CubeColor.Id.BLUE,
		CubeColor.Id.YELLOW, CubeColor.Id.BLUE,
	]
	var t2: Array[CubeColor.Id] = [
		CubeColor.Id.BLUE, CubeColor.Id.RED, CubeColor.Id.BLUE,
		CubeColor.Id.YELLOW, CubeColor.Id.BLUE, CubeColor.Id.RED,
		CubeColor.Id.YELLOW,
	]
	var trucks: Array[LevelData.TruckSpec] = []
	trucks.append(LevelData.TruckSpec.new(5, t0))
	trucks.append(LevelData.TruckSpec.new(5, t1))
	trucks.append(LevelData.TruckSpec.new(7, t2))
	return LevelData.new(conveyor_capacity, trucks)


func _replay(conveyor_capacity: int) -> void:
	var level := Level.try_create(_tut2(conveyor_capacity))
	var peak := 0
	for token in PATH.split(" ", false):
		if token.begins_with("T"):
			var result := level.tap(int(token.substr(1)))
			if result != Level.TapResult.ACCEPTED:
				print("capacity=%d FAIL tap %s -> %s" % [conveyor_capacity, token, result])
				_dump(level, peak)
				return
		elif token == "A":
			level.advance(1)
		peak = maxi(peak, level.conveyor().in_transit_count())
	print(
		"capacity=%d status=%s peak_transit=%d leftover=%d"
		% [conveyor_capacity, level.status(), peak, level.conveyor().in_transit_count()]
	)
	_dump(level, peak)


func _dump(level: Level, peak: int) -> void:
	for i in level.conveyor().trucks.size():
		var t: Truck = level.conveyor().trucks[i]
		var names: PackedStringArray = []
		for b in t.blocks:
			names.append(_c(b.color))
		print(
			"  T%d cap=%d [%s] finished=%s"
			% [i, t.capacity, " ".join(names), t.is_finished(level.set_sizes())]
		)
	print("  peak=%d" % peak)


func _c(id: CubeColor.Id) -> String:
	match id:
		CubeColor.Id.RED:
			return "R"
		CubeColor.Id.YELLOW:
			return "Y"
		CubeColor.Id.BLUE:
			return "B"
		_:
			return "?"
