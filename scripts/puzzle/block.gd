class_name Block
extends RefCounted
## One colored block. A Truck owns it while it is stacked; the Conveyor
## owns it after unload, until a truck accepts it again.

var color: CubeColor.Id


func _init(p_color: CubeColor.Id = CubeColor.Id.NONE) -> void:
	color = p_color
