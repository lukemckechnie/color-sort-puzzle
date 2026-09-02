extends GutTest
## Block is a color + slot. Constructor stores both.


func test_constructor_stores_color_and_position() -> void:
	var block := Block.new(CubeColor.Id.RED, 3)
	assert_eq(block.color, CubeColor.Id.RED)
	assert_eq(block.position, 3)


func test_position_defaults_to_zero() -> void:
	var block := Block.new(CubeColor.Id.BLUE)
	assert_eq(block.color, CubeColor.Id.BLUE)
	assert_eq(block.position, 0)


func test_position_is_writable_after_construct() -> void:
	var block := Block.new(CubeColor.Id.GREEN, 1)
	block.position = 5
	assert_eq(block.position, 5)
	assert_eq(block.color, CubeColor.Id.GREEN)
