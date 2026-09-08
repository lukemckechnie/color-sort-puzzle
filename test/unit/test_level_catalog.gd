extends GutTest
## Lint for Main's shipped level sets. See docs/LEVEL_SELECT.md.


var _MainScene: PackedScene


func before_all() -> void:
	_MainScene = load("res://scenes/main/main.tscn") as PackedScene


func test_tutorial_pack_contains_the_shipped_tutorials() -> void:
	var main := _MainScene.instantiate() as Control
	add_child_autofree(main)
	var ids: Array[String] = []
	for data in main.tutorial_levels():
		ids.append(data.id)
	assert_eq(ids, ["tut1", "tut2", "tut3", "tut4"])


func test_every_main_owned_level_is_unique_valid_and_playable() -> void:
	var main := _MainScene.instantiate() as Control
	add_child_autofree(main)
	var ids: Dictionary = {}
	var packs: Array[Array] = [main.tutorial_levels(), main.play_levels()]
	for pack in packs:
		for data: LevelData in pack:
			assert_ne(data.id, "", "catalogued levels need stable ids")
			assert_false(ids.has(data.id), "level ids must be unique across packs")
			ids[data.id] = true
			assert_eq(data.validation_error(), "")
			assert_not_null(Level.try_create(data))
