class_name LevelData
extends RefCounted
## Immutable level description. Level.try_create builds a playable
## Level (and its Conveyor / Trucks / Blocks) from this.
##
## See docs/CORE_LOOP.md §2 and §7.

const ERR_CAPACITY := "capacity < 1"
const ERR_CONVEYOR_MAX := "conveyor_max < 1"
const ERR_SLOT_COUNT := "slot_count < 1"
const ERR_STACK_LENGTH := "stack longer than capacity"
const ERR_EMPTY_TRUCKS := "empty trucks"
const ERR_DUPLICATE_POSITION := "duplicate positions"
const ERR_NONE_IN_STACK := "NONE in stack"
const ERR_POSITION_RANGE := "position out of range"

var conveyor_max: int
var slot_count: int
var trucks: Array[TruckSpec]


func _init(
	p_conveyor_max: int = 0,
	p_slot_count: int = 0,
	p_trucks: Array[TruckSpec] = []
) -> void:
	conveyor_max = p_conveyor_max
	slot_count = p_slot_count
	trucks = p_trucks


## Empty string if valid; otherwise one of the ERR_* constants.
func validation_error() -> String:
	push_error("not implemented")
	return "not implemented"


class TruckSpec:
	## One truck in level data: capacity, slot position, starting stack
	## (bottom first).
	var capacity: int
	var position: int
	var stack: Array[CubeColor.Id]

	func _init(
		p_capacity: int = 0,
		p_position: int = 0,
		p_stack: Array[CubeColor.Id] = []
	) -> void:
		capacity = p_capacity
		position = p_position
		stack = p_stack
