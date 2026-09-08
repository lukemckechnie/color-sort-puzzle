extends GutTest
## Tutorial selector: rows of 5 numbered squares, check on the box.


var _SelectScene: PackedScene
const LevelRunResultModel := preload("res://scripts/player/level_run_result.gd")


func before_all() -> void:
	_SelectScene = load("res://scenes/level_select/level_select.tscn") as PackedScene


func after_each() -> void:
	var empty: Array[LevelData] = []
	LevelSelect.pending_levels = empty
	LevelSelect.pending_user = null


func _select() -> Node:
	var node: Node = _SelectScene.instantiate()
	add_child_autofree(node)
	return node


func test_empty_levels_creates_no_rows() -> void:
	var select: Node = _select()
	var levels: Array[LevelData] = []
	select.configure(levels, null)
	assert_eq(select.row_count(), 0)
	assert_eq(select.group_count(), 0)


func test_short_pack_still_uses_a_row_of_five_squares() -> void:
	var select: Node = _select()
	var levels: Array[LevelData] = []
	levels.append(TutorialLevel.data())
	levels.append(TutorialLevel2.data())
	select.configure(levels, null)
	assert_eq(select.row_count(), 2)
	assert_eq(select.group_count(), 1)
	assert_eq(select.slots_in_group(0), 5)


func test_checkmark_is_on_the_completed_square() -> void:
	var select: Node = _select()
	var levels: Array[LevelData] = []
	levels.append(TutorialLevel.data())
	levels.append(TutorialLevel2.data())
	var user := User.new()
	user.completions["tut1"] = LevelCompletion.new(10.0, 6, 5)
	select.configure(levels, user)
	assert_true(select.row_is_complete(0))
	assert_true(select.tile_check_visible(0))
	assert_false(select.row_is_complete(1))
	assert_false(select.tile_check_visible(1))


func test_pressing_a_completed_square_emits_that_completion() -> void:
	var select: Node = _select()
	var levels: Array[LevelData] = []
	levels.append(TutorialLevel.data())
	var user := User.new()
	var done := LevelCompletion.new(8.0, 5, 4)
	user.completions["tut1"] = done
	select.configure(levels, user)
	watch_signals(select)
	select.press_row(0)
	assert_signal_emitted(select, "level_selected")
	var params: Array = get_signal_parameters(select, "level_selected")
	assert_eq(params[0].id, "tut1")
	assert_same(params[1], done)


func test_null_user_lists_levels_with_no_checks() -> void:
	var select: Node = _select()
	var levels: Array[LevelData] = []
	levels.append(TutorialLevel.data())
	select.configure(levels, null)
	assert_eq(select.row_count(), 1)
	assert_false(select.row_is_complete(0))
	watch_signals(select)
	select.press_row(0)
	var params: Array = get_signal_parameters(select, "level_selected")
	assert_eq(params[0].id, "tut1")
	assert_null(params[1])


func _won(level_id: String) -> RefCounted:
	return LevelRunResultModel.new(
		level_id,
		LevelRunResultModel.Outcome.WON,
		10.0,
		5,
		3
	)


func _lost(level_id: String) -> RefCounted:
	return LevelRunResultModel.new(
		level_id,
		LevelRunResultModel.Outcome.LOST,
		10.0,
		5,
		3
	)


func test_terminal_outcomes_configure_the_shared_result_modal() -> void:
	var select: Node = _select()
	var levels: Array[LevelData] = [TutorialLevel.data()]
	select.configure(levels, User.new())

	select._play_level(levels[0], null)
	var win_playfield: Control = select._active_playfield
	assert(win_playfield != null, "selecting a level creates a child Playfield")
	win_playfield.run_finished.emit(_won(levels[0].id))
	var modal: ColorRect = select.get_node("%ResultModal")
	assert_true(modal.visible)
	assert_eq(select.get_node("%ResultTitle").text, "You won!")
	assert_eq(select.get_node("%ResultAction").text, "Next Level")
	assert_true(select.get_node("%ResultAction").disabled)

	select._play_level(levels[0], null)
	var loss_playfield: Control = select._active_playfield
	assert(loss_playfield != null, "replacing a level creates a child Playfield")
	loss_playfield.run_finished.emit(_lost(levels[0].id))
	assert_true(modal.visible)
	assert_eq(select.get_node("%ResultTitle").text, "You lost!")
	assert_eq(select.get_node("%ResultAction").text, "Retry")
	assert_false(select.get_node("%ResultAction").disabled)
	select.get_node("%ResultAction").pressed.emit()
	assert_eq(select._selected_index, 0, "Retry opens the current level")
	assert(select._active_playfield != loss_playfield, "Retry replaces the active Playfield")
	assert_false(modal.visible, "launching Retry hides the result modal")

	var retried_playfield: Control = select._active_playfield
	retried_playfield.run_finished.emit(_lost(levels[0].id))
	select.get_node("%ResultBack").pressed.emit()
	assert_false(modal.visible, "Back hides the result modal")
	assert_null(select._active_playfield, "Back removes the active Playfield")
	assert_eq(select._selected_index, -1, "Back returns to the level tiles")


func test_two_wins_advance_through_the_retained_three_level_pack() -> void:
	var select: Node = _select()
	var levels: Array[LevelData] = [
		TutorialLevel.data(),
		TutorialLevel2.data(),
		TutorialLevel3.data(),
	]
	select.configure(levels, User.new())
	select._play_level(levels[0], null)
	var first_playfield: Control = select._active_playfield
	assert(first_playfield != null, "selecting a level creates a child Playfield")
	assert_eq(select._selected_index, 0)

	first_playfield.run_finished.emit(_won(levels[0].id))
	assert_true(select.get_node("%ResultModal").visible)
	select.get_node("%ResultAction").pressed.emit()
	assert_eq(select._selected_index, 1, "Next after winning level 1 opens level 2")

	var second_playfield: Control = select._active_playfield
	assert(second_playfield != null, "opening the next level creates a child Playfield")
	second_playfield.run_finished.emit(_won(levels[1].id))
	select.get_node("%ResultAction").pressed.emit()
	assert_eq(select._selected_index, 2, "Next after winning level 2 opens level 3")
