class_name PuzzleSession
extends RefCounted
## One play record: what happened when, and the Level(s) involved.
##
## A future User may own many of these. This class does not own puzzle
## rules; each Level does.

static func try_create(data: LevelData) -> PuzzleSession:
	push_error("not implemented")
	return null


func levels() -> Array[Level]:
	push_error("not implemented")
	return []


func current_level() -> Level:
	push_error("not implemented")
	return null


## Ordered record of what happened this play. Event schema is not
## specified yet — do not invent one in implementation.
func history() -> Array:
	push_error("not implemented")
	return []
