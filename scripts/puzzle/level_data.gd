class_name LevelData
extends RefCounted
## Immutable level description. Level.try_create builds a playable
## Level (and its Conveyor / Trucks / Blocks) from this.
##
## See docs/CORE_LOOP.md §2 and §7.

const ERR_CAPACITY := "capacity < 1"
const ERR_CONVEYOR_CAPACITY := "conveyor_capacity < 1"
const ERR_STACK_LENGTH := "stack longer than capacity"
const ERR_EMPTY_TRUCKS := "empty trucks"
const ERR_NONE_IN_STACK := "NONE in stack"

var id: String
var title: String
var conveyor_capacity: int
var trucks: Array[TruckSpec]


func _init(
	p_conveyor_capacity: int = 0,
	p_trucks: Array[TruckSpec] = [],
	p_id: String = "",
	p_title: String = ""
) -> void:
	conveyor_capacity = p_conveyor_capacity
	trucks = p_trucks
	id = p_id
	title = p_title


## Empty string if valid; otherwise one of the ERR_* constants.
func validation_error() -> String:
	if conveyor_capacity < 1:
		return ERR_CONVEYOR_CAPACITY
	if trucks.is_empty():
		return ERR_EMPTY_TRUCKS
	for spec in trucks:
		if spec.capacity < 1:
			return ERR_CAPACITY
		if spec.stack.size() > spec.capacity:
			return ERR_STACK_LENGTH
		for color in spec.stack:
			if color == CubeColor.Id.NONE:
				return ERR_NONE_IN_STACK
	return ""


class TruckSpec:
	## One truck in level data: capacity and starting stack (bottom first).
	var capacity: int
	var stack: Array[CubeColor.Id]

	func _init(
		p_capacity: int = 0,
		p_stack: Array[CubeColor.Id] = []
	) -> void:
		capacity = p_capacity
		stack = p_stack
