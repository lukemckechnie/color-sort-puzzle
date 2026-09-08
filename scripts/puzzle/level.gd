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

var _conveyor: Conveyor
var _set_sizes: Dictionary
var _status: Status = Status.PLAYING
var _last_tap: TapResult = TapResult.INVALID_INDEX


static func try_create(data: LevelData) -> Level:
	if data == null or data.validation_error() != "":
		return null
	var trucks: Array[Truck] = []
	var sizes: Dictionary = {}
	for spec in data.trucks:
		var stacked: Array[Block] = []
		for color in spec.stack:
			stacked.append(Block.new(color))
			sizes[color] = sizes.get(color, 0) + 1
		trucks.append(Truck.new(spec.capacity, stacked))
	var level := Level.new()
	level._conveyor = Conveyor.new(data.conveyor_capacity, trucks)
	level._set_sizes = sizes
	level._status = Status.PLAYING
	return level


func tap(truck_index: int) -> TapResult:
	if _status != Status.PLAYING:
		_last_tap = TapResult.INVALID_INDEX
		return _last_tap
	if truck_index < 0 or truck_index >= _conveyor.trucks.size():
		_last_tap = TapResult.INVALID_INDEX
		return _last_tap
	var truck: Truck = _conveyor.trucks[truck_index]
	if truck.is_finished(_set_sizes):
		_last_tap = TapResult.FINISHED
		return _last_tap
	if truck.is_empty():
		_last_tap = TapResult.EMPTY
		return _last_tap
	if _conveyor.is_at_capacity():
		_last_tap = TapResult.CONVEYOR_FULL
		return _last_tap
	var room: int = _conveyor.conveyor_capacity - _conveyor.in_transit_count()
	var taken: Array[Block] = truck.unload(room)
	if taken.is_empty():
		_last_tap = TapResult.EMPTY
		return _last_tap
	_conveyor.load(taken, truck_index, _set_sizes)
	_last_tap = TapResult.ACCEPTED
	if _is_won():
		_status = Status.WON
	elif _is_lost():
		_status = Status.LOST
	return _last_tap


func advance(n: int) -> Conveyor.AdvanceResult:
	var result: Conveyor.AdvanceResult = _conveyor.advance(n, _set_sizes)
	if result == Conveyor.AdvanceResult.ADVANCED and _status == Status.PLAYING and _is_won():
		_status = Status.WON
	return result


func status() -> Status:
	return _status


func last_tap_result() -> TapResult:
	return _last_tap


func conveyor() -> Conveyor:
	return _conveyor


## CubeColor.Id -> set size, counted once from LevelData at create.
func set_sizes() -> Dictionary:
	return _set_sizes


func _is_won() -> bool:
	if _conveyor.in_transit_count() > 0:
		return false
	for truck in _conveyor.trucks:
		if not truck.is_empty() and not truck.is_finished(_set_sizes):
			return false
	return true


func _is_lost() -> bool:
	return _conveyor.is_at_capacity() and not _conveyor.any_block_can_exit(_set_sizes)
