extends GutTest
## LevelCompletion fields and shared display line.


func test_stores_ttc_taps_and_peak_load() -> void:
	var completion := LevelCompletion.new(12.4, 8, 5)
	assert_eq(completion.ttc, 12.4)
	assert_eq(completion.taps, 8)
	assert_eq(completion.max_conveyor_load, 5)


func test_defaults_are_zero() -> void:
	var completion := LevelCompletion.new()
	assert_eq(completion.ttc, 0.0)
	assert_eq(completion.taps, 0)
	assert_eq(completion.max_conveyor_load, 0)


func test_summary_line_formats_the_three_fields() -> void:
	var completion := LevelCompletion.new(12.4, 8, 5)
	assert_eq(completion.summary_line(), "12.4s · 8 taps · peak 5")
