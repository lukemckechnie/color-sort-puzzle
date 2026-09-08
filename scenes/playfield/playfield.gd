extends Control
## Programmer-art playfield. Belt and trucks are built from LevelData.


const TICK_SECONDS := 0.4
const SCENE_PATH := "res://scenes/playfield/playfield.tscn"
const PLAYFIELD_SCENE := preload(SCENE_PATH)
const BELT_CELL := Vector2(72, 72)
const TRUCK_CELL := Vector2(96, 96)
const LevelRunResultModel := preload("res://scripts/player/level_run_result.gd")


signal run_finished(result: LevelRunResultModel)

var _data: LevelData
var _target_completion: LevelCompletion
var _level: Level
var _tick_accum := 0.0
var _elapsed := 0.0
var _accepted_taps := 0
var _max_conveyor_load := 0
var _did_emit_run_result := false
var _station_slots: Array[int] = []
var _truck_cells: Array = []
@onready var _title: Label = %Title
@onready var _status: Label = %Status
@onready var _target: Label = %Target
@onready var _occupancy: Label = %Occupancy
@onready var _belt: HBoxContainer = %Belt
@onready var _trucks_box: HBoxContainer = %Trucks


static func launch(
	data: LevelData,
	target: LevelCompletion = null
) -> Control:
	var playfield: Control = PLAYFIELD_SCENE.instantiate()
	playfield.call("_configure", data, target)
	return playfield


func _configure(data: LevelData, target: LevelCompletion) -> void:
	_data = data
	_target_completion = target


func _ready() -> void:
	_level = Level.try_create(_data)
	if _data != null:
		_title.text = _data.title
	_build_from_level()
	_update_max_conveyor_load()
	_refresh()
	_emit_terminal_result_if_needed()


func _process(delta: float) -> void:
	if _level == null or _level.status() != Level.Status.PLAYING:
		return
	_elapsed += delta
	if _level.conveyor().in_transit.is_empty():
		return
	_tick_accum += delta
	if _tick_accum < TICK_SECONDS:
		return
	_tick_accum = 0.0
	_level.advance(1)
	_update_max_conveyor_load()
	_refresh()
	_emit_terminal_result_if_needed()


func _on_tap(truck_index: int) -> void:
	if _level == null or _level.status() != Level.Status.PLAYING:
		return
	var result: Level.TapResult = _level.tap(truck_index)
	if result == Level.TapResult.ACCEPTED:
		_accepted_taps += 1
	_tick_accum = 0.0
	_update_max_conveyor_load()
	_refresh()
	_emit_terminal_result_if_needed()


func _update_max_conveyor_load() -> void:
	if _level == null:
		return
	_max_conveyor_load = max(_max_conveyor_load, _level.conveyor().in_transit_count())


func _emit_terminal_result_if_needed() -> void:
	if _did_emit_run_result or _level == null:
		return
	var status := _level.status()
	if status == Level.Status.PLAYING:
		return
	_did_emit_run_result = true
	var outcome: LevelRunResultModel.Outcome = LevelRunResultModel.Outcome.WON
	if status == Level.Status.LOST:
		outcome = LevelRunResultModel.Outcome.LOST
	var level_id := ""
	if _data != null:
		level_id = _data.id
	run_finished.emit(LevelRunResultModel.new(
		level_id,
		outcome,
		_elapsed,
		_accepted_taps,
		_max_conveyor_load
	))


func _build_from_level() -> void:
	_clear(_belt)
	_clear(_trucks_box)
	_truck_cells.clear()
	_station_slots.clear()
	if _level == null:
		return
	var conveyor: Conveyor = _level.conveyor()
	for truck_index in conveyor.trucks.size():
		_station_slots.append(conveyor.offer_position(truck_index))
	for _slot in conveyor.belt_position_count:
		var cell := ColorRect.new()
		cell.custom_minimum_size = BELT_CELL
		_belt.add_child(cell)
	for truck_i in conveyor.trucks.size():
		var truck: Truck = conveyor.trucks[truck_i]
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		var caption := Label.new()
		caption.text = "Truck %d" % (truck_i + 1)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 26)
		caption.add_theme_color_override("font_color", Color(0.9, 0.9, 0.92))
		col.add_child(caption)
		var cells: Array[ColorRect] = []
		for _cell_i in truck.capacity:
			var cell := ColorRect.new()
			cell.custom_minimum_size = TRUCK_CELL
			col.add_child(cell)
			cells.append(cell)
		var tap := Button.new()
		tap.text = "Tap"
		tap.custom_minimum_size = Vector2(0, 64)
		tap.add_theme_font_size_override("font_size", 28)
		tap.pressed.connect(_on_tap.bind(truck_i))
		col.add_child(tap)
		_trucks_box.add_child(col)
		_truck_cells.append(cells)


func _refresh() -> void:
	if _level == null:
		_status.text = "Could not load level."
		_occupancy.text = occupancy_text()
		_target.text = target_text()
		_target.visible = not _target.text.is_empty()
		return
	_status.text = _status_text()
	_occupancy.text = occupancy_text()
	_target.text = target_text()
	_target.visible = not _target.text.is_empty()
	for slot in _belt.get_child_count():
		var cell := _belt.get_child(slot) as ColorRect
		if cell == null:
			continue
		var occupant := _block_at_slot(slot)
		if occupant != null:
			cell.color = _color_of(occupant.color)
		elif slot in _station_slots:
			cell.color = Color(0.28, 0.28, 0.32)
		else:
			cell.color = Color(0.16, 0.16, 0.18)
	for truck_i in _truck_cells.size():
		var cells: Array[ColorRect] = _truck_cells[truck_i]
		_paint_truck(cells, _level.conveyor().trucks[truck_i])


func _paint_truck(cells: Array[ColorRect], truck: Truck) -> void:
	var stacked: Array[Block] = truck.blocks
	for cell_i in cells.size():
		var from_top: int = cells.size() - 1 - cell_i
		if from_top < stacked.size():
			cells[cell_i].color = _color_of(stacked[from_top].color)
		else:
			cells[cell_i].color = Color(0.14, 0.14, 0.16)


func _block_at_slot(slot: int) -> Block:
	return _level.conveyor().block_at(slot)


func occupancy_text() -> String:
	if _level == null:
		return "0/0"
	var conveyor: Conveyor = _level.conveyor()
	return "%d/%d" % [conveyor.in_transit_count(), conveyor.conveyor_capacity]


func target_text() -> String:
	if _target_completion == null:
		return ""
	return "Target: %s" % _target_completion.summary_line()


func _status_text() -> String:
	match _level.status():
		Level.Status.WON:
			return "Won — every truck is finished."
		Level.Status.LOST:
			return "Lost — conveyor is full and nothing can exit."
		_:
			match _level.last_tap_result():
				Level.TapResult.FINISHED:
					return "Sort each color into its own truck. That truck is finished."
				Level.TapResult.EMPTY:
					return "Sort each color into its own truck. That truck is empty."
				Level.TapResult.CONVEYOR_FULL:
					return "Sort each color into its own truck. Conveyor is full."
				_:
					return "Sort each color into its own truck."


func _clear(box: Container) -> void:
	for child in box.get_children():
		child.queue_free()


func _color_of(id: CubeColor.Id) -> Color:
	match id:
		CubeColor.Id.RED:
			return Color(0.86, 0.22, 0.24)
		CubeColor.Id.ORANGE:
			return Color(0.92, 0.52, 0.18)
		CubeColor.Id.YELLOW:
			return Color(0.95, 0.82, 0.2)
		CubeColor.Id.GREEN:
			return Color(0.28, 0.72, 0.36)
		CubeColor.Id.BLUE:
			return Color(0.28, 0.48, 0.92)
		CubeColor.Id.PURPLE:
			return Color(0.62, 0.36, 0.78)
		CubeColor.Id.PINK:
			return Color(0.9, 0.45, 0.68)
		CubeColor.Id.CYAN:
			return Color(0.3, 0.78, 0.82)
		CubeColor.Id.BROWN:
			return Color(0.55, 0.36, 0.22)
		CubeColor.Id.WHITE:
			return Color(0.92, 0.92, 0.94)
		_:
			return Color(0.55, 0.55, 0.58)
