class_name Block
extends RefCounted
## One colored block. A Truck owns it while it is stacked; the Conveyor
## owns it after unload, until a truck accepts it again.
##
## position is the belt slot while the Conveyor owns this block.

var color: CubeColor.Id
var position: int


func _init(
	p_color: CubeColor.Id = CubeColor.Id.NONE,
	p_position: int = 0
) -> void:
	color = p_color
	position = p_position
