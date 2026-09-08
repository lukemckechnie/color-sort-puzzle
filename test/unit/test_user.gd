extends GutTest
## User.completion_for looks up by level id.


func test_completion_for_returns_stored_entry() -> void:
	var user := User.new()
	var done := LevelCompletion.new(9.0, 4, 3)
	user.completions["tut1"] = done
	assert_same(user.completion_for("tut1"), done)


func test_completion_for_unknown_or_empty_id_is_null() -> void:
	var user := User.new()
	user.completions["tut1"] = LevelCompletion.new(1.0, 1, 1)
	assert_null(user.completion_for("tut2"))
	assert_null(user.completion_for(""))
	assert_null(User.new().completion_for("tut1"))
