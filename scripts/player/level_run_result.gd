class_name LevelRunResult
extends RefCounted
## Immutable terminal result for one level attempt. See docs/LEVEL_SELECT.md.

enum Outcome { WON, LOST }

var _level_id: String
var _outcome: Outcome
var _ttc: float
var _taps: int
var _max_conveyor_load: int

var level_id: String:
	get:
		return _level_id

var outcome: Outcome:
	get:
		return _outcome

var ttc: float:
	get:
		return _ttc

var taps: int:
	get:
		return _taps

var max_conveyor_load: int:
	get:
		return _max_conveyor_load


func _init(
	p_level_id: String = "",
	p_outcome: Outcome = Outcome.LOST,
	p_ttc: float = 0.0,
	p_taps: int = 0,
	p_max_conveyor_load: int = 0
) -> void:
	_level_id = p_level_id
	_outcome = p_outcome
	_ttc = p_ttc
	_taps = p_taps
	_max_conveyor_load = p_max_conveyor_load
