extends GutTest
## Playfield occupancy and target-completion labels.


var _PlayScene: PackedScene
const Playfield := preload("res://scenes/playfield/playfield.gd")


func before_all() -> void:
	_PlayScene = load("res://scenes/playfield/playfield.tscn") as PackedScene


func _playfield(data: LevelData, target: LevelCompletion = null) -> Node:
	var node: Node = Playfield.launch(data, target)
	add_child_autofree(node)
	return node


func test_occupancy_starts_empty_and_updates_after_tap() -> void:
	var play: Node = _playfield(TutorialLevel.data())
	assert_eq(play.occupancy_text(), "0/5")
	play._on_tap(0)
	assert_eq(play.occupancy_text(), "1/5")
	assert_eq(play.get_node("%Occupancy").text, "1/5")


func test_target_line_shown_when_launch_has_a_completion() -> void:
	var play: Node = _playfield(TutorialLevel.data(), LevelCompletion.new(12.4, 8, 5))
	assert_eq(play.target_text(), "Target: 12.4s · 8 taps · peak 5")
	var label: Label = play.get_node("%Target")
	assert_eq(label.text, "Target: 12.4s · 8 taps · peak 5")
	assert_true(label.visible)


func test_target_hidden_when_there_is_no_completion() -> void:
	var play: Node = _playfield(TutorialLevel.data())
	assert_eq(play.target_text(), "")
	assert_false(play.get_node("%Target").visible)
