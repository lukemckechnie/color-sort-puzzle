class_name PuzzleSession
extends RefCounted
## One play record: what happened when, and the Level(s) involved.
##
## A future User may own many of these. This class does not own puzzle
## rules; each Level does.

var _levels: Array[Level] = []


static func try_create(data: LevelData) -> PuzzleSession:
	var level := Level.try_create(data)
	if level == null:
		return null
	var session := PuzzleSession.new()
	session._levels.append(level)
	return session


func levels() -> Array[Level]:
	return _levels


func current_level() -> Level:
	if _levels.is_empty():
		return null
	return _levels[0]


## Ordered record of what happened this play. Event schema is not
## specified yet — do not invent one in implementation.
func history() -> Array:
	return []
