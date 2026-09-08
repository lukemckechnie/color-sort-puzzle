extends GutTest


func test_block_keeps_only_its_color() -> void:
	var block := Block.new(CubeColor.Id.BLUE)
	assert_eq(block.color, CubeColor.Id.BLUE)
