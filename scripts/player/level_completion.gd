class_name LevelCompletion
extends RefCounted
## One recorded successful play. Display-only until a later step
## writes these on win. See docs/LEVEL_SELECT.md.


var ttc: float
var taps: int
var max_conveyor_load: int


func _init(
	p_ttc: float = 0.0,
	p_taps: int = 0,
	p_max_conveyor_load: int = 0
) -> void:
	ttc = p_ttc
	taps = p_taps
	max_conveyor_load = p_max_conveyor_load


func summary_line() -> String:
	return "%.1fs · %d taps · peak %d" % [ttc, taps, max_conveyor_load]
