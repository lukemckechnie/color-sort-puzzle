class_name LevelSelect
extends Control
## Tutorial pack selector. Rows of 5 numbered squares.
## See docs/LEVEL_SELECT.md.


signal level_selected(data: LevelData, target: LevelCompletion)

const SCENE_PATH := "res://scenes/level_select/level_select.tscn"
const MAIN_SCENE := "res://scenes/main/main.tscn"
const Playfield := preload("res://scenes/playfield/playfield.gd")
const LevelRunResultModel := preload("res://scripts/player/level_run_result.gd")
const SLOTS_PER_ROW := 5
const TILE_SIZE := Vector2(168, 168)

static var pending_levels: Array[LevelData] = []
static var pending_user: User

@onready var _list: VBoxContainer = %List
@onready var _back: Button = %Back
@onready var _result_modal: ColorRect = %ResultModal
@onready var _result_title: Label = %ResultTitle
@onready var _result_action: Button = %ResultAction
@onready var _result_back: Button = %ResultBack

var _rows: Array[Dictionary] = []
var _levels: Array[LevelData] = []
var _user: User
var _selected_index := -1
var _active_playfield: Control
var _presented_outcome: LevelRunResultModel.Outcome = LevelRunResultModel.Outcome.LOST


static func launch(tree: SceneTree, levels: Array[LevelData], user: User = null) -> void:
	pending_levels = levels.duplicate()
	pending_user = user
	tree.change_scene_to_file(SCENE_PATH)


static func reopen(tree: SceneTree) -> void:
	tree.change_scene_to_file(SCENE_PATH)


func _ready() -> void:
	_back.pressed.connect(_on_back)
	_result_action.pressed.connect(_on_result_action)
	_result_back.pressed.connect(_on_result_back)
	if get_tree() != null and get_tree().current_scene == self:
		level_selected.connect(_play_level)
	if pending_user == null:
		pending_user = User.new()
	configure(pending_levels, pending_user)


func configure(levels: Array[LevelData], user: User = null) -> void:
	_levels = levels
	_user = user
	_clear_rows()
	if levels.is_empty() or _list == null:
		return
	var index := 0
	while index < levels.size():
		var line := HBoxContainer.new()
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_theme_constant_override("separation", 16)
		for slot in SLOTS_PER_ROW:
			if index < levels.size():
				_add_tile(line, levels[index], index, user)
				index += 1
			else:
				line.add_child(_empty_tile())
		_list.add_child(line)


func row_count() -> int:
	return _rows.size()


func group_count() -> int:
	if _list == null:
		return 0
	return _list.get_child_count()


func slots_in_group(group_index: int) -> int:
	if _list == null or group_index < 0 or group_index >= _list.get_child_count():
		return 0
	return _list.get_child(group_index).get_child_count()


func row_is_complete(index: int) -> bool:
	if index < 0 or index >= _rows.size():
		return false
	return _rows[index]["complete"]


func tile_check_visible(index: int) -> bool:
	if index < 0 or index >= _rows.size():
		return false
	var tile: Button = _rows[index]["tile"]
	var check := tile.get_node_or_null("Check") as Label
	return check != null and check.visible


func press_row(index: int) -> void:
	if index < 0 or index >= _rows.size():
		return
	var data: LevelData = _rows[index]["data"]
	var target: LevelCompletion = _rows[index]["target"]
	level_selected.emit(data, target)


func _play_level(data: LevelData, target: LevelCompletion) -> void:
	var selected_index := _levels.find(data)
	if selected_index < 0:
		return
	_selected_index = selected_index
	_result_modal.visible = false
	if _active_playfield != null:
		_active_playfield.queue_free()
		_active_playfield = null
	var playfield := Playfield.launch(data, target)
	playfield.connect("run_finished", _on_run_finished)
	add_child(playfield)
	move_child(playfield, _result_modal.get_index())
	_active_playfield = playfield


func _on_run_finished(result: LevelRunResultModel) -> void:
	if result == null or _selected_index < 0 or _selected_index >= _levels.size():
		return
	if result.level_id != _levels[_selected_index].id:
		return
	_presented_outcome = result.outcome
	match result.outcome:
		LevelRunResultModel.Outcome.WON:
			_result_title.text = "You won!"
			_result_action.text = "Next Level"
			_result_action.disabled = _selected_index + 1 >= _levels.size()
		LevelRunResultModel.Outcome.LOST:
			_result_title.text = "You lost!"
			_result_action.text = "Retry"
			_result_action.disabled = false
	_result_modal.visible = true


func _on_result_action() -> void:
	if not _result_modal.visible or _selected_index < 0 or _selected_index >= _levels.size():
		return
	var next_index := _selected_index
	if _presented_outcome == LevelRunResultModel.Outcome.WON:
		next_index += 1
	if next_index >= _levels.size():
		return
	var data: LevelData = _levels[next_index]
	var target: LevelCompletion = null
	if _user != null:
		target = _user.completion_for(data.id)
	_play_level(data, target)


func _on_result_back() -> void:
	if not _result_modal.visible:
		return
	_result_modal.visible = false
	if _active_playfield != null:
		_active_playfield.queue_free()
		_active_playfield = null
	_selected_index = -1


func _on_back() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)


func _add_tile(line: HBoxContainer, data: LevelData, index: int, user: User) -> void:
	var target: LevelCompletion = null
	if user != null:
		target = user.completion_for(data.id)
	var complete := target != null
	var tile := _square_tile(str(index + 1), true, complete)
	tile.pressed.connect(press_row.bind(_rows.size()))
	line.add_child(tile)
	_rows.append({
		"data": data,
		"target": target,
		"complete": complete,
		"tile": tile,
	})


func _empty_tile() -> Button:
	return _square_tile("", false, false)


func _square_tile(number: String, playable: bool, complete: bool) -> Button:
	var tile := Button.new()
	tile.custom_minimum_size = TILE_SIZE
	tile.text = number
	tile.disabled = not playable
	tile.add_theme_font_size_override("font_size", 48)
	var check := Label.new()
	check.name = "Check"
	check.text = "✓"
	check.visible = complete
	check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	check.add_theme_font_size_override("font_size", 28)
	check.add_theme_color_override("font_color", Color(0.28, 0.78, 0.42))
	check.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	check.set_anchors_preset(Control.PRESET_TOP_WIDE)
	check.offset_left = 8
	check.offset_top = 4
	check.offset_right = -8
	check.offset_bottom = 40
	tile.add_child(check)
	var stars := HBoxContainer.new()
	stars.name = "Stars"
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stars.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	stars.offset_top = -28
	stars.offset_bottom = -6
	tile.add_child(stars)
	return tile


func _clear_rows() -> void:
	_rows.clear()
	if _list == null:
		return
	for child in _list.get_children():
		_list.remove_child(child)
		child.free()
