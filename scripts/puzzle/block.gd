class_name Block
extends RefCounted
## One colored block. A Truck owns it while it is stacked; the Conveyor
## owns it after unload, until a truck accepts it again.
##
## approaching_truck_index and ticks_into_hop are path on the conveyor,
## not a reserved destination. They are only meaningful while the
## Conveyor owns this block.

var color: CubeColor.Id
var approaching_truck_index: int
var ticks_into_hop: int


func _init(
	p_color: CubeColor.Id = CubeColor.Id.NONE,
	p_approaching_truck_index: int = 0,
	p_ticks_into_hop: int = 0
) -> void:
	color = p_color
	approaching_truck_index = p_approaching_truck_index
	ticks_into_hop = p_ticks_into_hop
