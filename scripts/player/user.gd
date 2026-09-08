class_name User
extends RefCounted
## Caller-owned play record holder. completions maps level id to
## LevelCompletion. Does not persist and does not own sessions.
## See docs/LEVEL_SELECT.md.


var completions: Dictionary = {}


func completion_for(level_id: String) -> LevelCompletion:
	if level_id.is_empty() or not completions.has(level_id):
		return null
	var found: Variant = completions[level_id]
	if found is LevelCompletion:
		return found
	return null
