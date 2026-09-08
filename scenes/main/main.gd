extends Control
## Title menu. Main owns the shipped tutorial and play level sets.


const TutorialLevel4Data := preload("res://scripts/puzzle/tutorial_level_4.gd")


func _ready() -> void:
	%Tutorial.pressed.connect(_on_tutorial_pressed)
	%Play.pressed.connect(_on_play_pressed)


func _on_tutorial_pressed() -> void:
	_launch(tutorial_levels())


func _on_play_pressed() -> void:
	_launch(play_levels())


func tutorial_levels() -> Array[LevelData]:
	return [
		TutorialLevel.data(),
		TutorialLevel2.data(),
		TutorialLevel3.data(),
		TutorialLevel4Data.data(),
	]


func play_levels() -> Array[LevelData]:
	return []


func _launch(levels: Array[LevelData]) -> void:
	LevelSelect.launch(get_tree(), levels, User.new())
