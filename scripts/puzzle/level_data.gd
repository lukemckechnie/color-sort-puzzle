class_name LevelData
extends RefCounted
## Immutable level description. Level.try_create builds a playable
## Level (and its Conveyor / Trucks / Blocks) from this.
##
## See docs/CORE_LOOP.md §2 and §7.

var conveyor_max: int
var hop_duration: int
var trucks: Array[TruckSpec]


func _init(
	p_conveyor_max: int = 0,
	p_hop_duration: int = 0,
	p_trucks: Array[TruckSpec] = []
) -> void:
	conveyor_max = p_conveyor_max
	hop_duration = p_hop_duration
	trucks = p_trucks


## Empty string if the level is valid; otherwise a reason it must not start.
func validation_error() -> String:
	push_error("not implemented")
	return "not implemented"


class TruckSpec:
	## One truck in level data: capacity, conveyor position, starting stack
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
