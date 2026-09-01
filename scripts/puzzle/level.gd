class_name Level
extends RefCounted
## One playable puzzle. Owns the Conveyor. tap / advance are the only
## mutations; they delegate to the conveyor and trucks.
##
## Built from LevelData. See docs/CORE_LOOP.md.

enum Status { PLAYING, WON, LOST }

enum TapResult {
	ACCEPTED,
	INVALID_INDEX,
	FINISHED,
	EMPTY,
	CONVEYOR_FULL,
}


static func try_create(data: LevelData) -> Level:
	push_error("not implemented")
	return null


func tap(truck_index: int) -> TapResult:
	push_error("not implemented")
	return TapResult.INVALID_INDEX


func advance(n: int) -> Conveyor.AdvanceResult:
	push_error("not implemented")
	return Conveyor.AdvanceResult.INVALID_TICKS


func status() -> Status:
	push_error("not implemented")
	return Status.PLAYING


func last_tap_result() -> TapResult:
	push_error("not implemented")
	return TapResult.INVALID_INDEX


func conveyor() -> Conveyor:
	push_error("not implemented")
	return null


## CubeColor.Id -> set size, counted once from LevelData at create.
func set_sizes() -> Dictionary:
	push_error("not implemented")
	return {}
