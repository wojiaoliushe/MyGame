extends RefCounted
class_name InventoryDragPreview

## 拖拽预览：底层绘制真实占格格子，道具贴图居中叠在格子上方。

static func item_sprite_size_px(
	item: InventoryItem,
	field_dimensions: Vector2,
	item_spacing: int,
	preview_rotated: Variant = null,
) -> Vector2:
	var grid_size: Vector2i = _item_grid_size(item, preview_rotated)
	var sprite_size: Vector2 = Vector2(grid_size) * field_dimensions
	sprite_size += (Vector2(grid_size) - Vector2.ONE) * float(item_spacing)
	return sprite_size

static func build(
	item: InventoryItem,
	field_dimensions: Vector2,
	item_spacing: int,
	preview_rotated: Variant = null,
	preview_positive: bool = true,
) -> Control:
	var rotated: bool = preview_rotated if preview_rotated != null else GridConstraint.is_item_rotated(item)
	var positive: bool = preview_positive if preview_rotated != null else GridConstraint.is_item_rotation_positive(item)
	var grid_size: Vector2i = _item_grid_size(item, rotated)
	var footprint_size: Vector2 = item_sprite_size_px(item, field_dimensions, item_spacing, rotated)

	var root := Control.new()
	root.custom_minimum_size = footprint_size
	root.size = footprint_size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var grid_layer: Control = _build_grid_cells_layer(grid_size, field_dimensions, item_spacing)
	grid_layer.z_index = 0
	root.add_child(grid_layer)

	var icon_layer: Control = _build_icon_layer(item, footprint_size, rotated, positive)
	icon_layer.z_index = 1
	root.add_child(icon_layer)

	return root

static func anchor_preview(preview: Control, grab_offset: Vector2) -> Control:
	var root := Control.new()
	preview.position = -grab_offset
	root.add_child(preview)
	return root

static func _build_icon_layer(
	item: InventoryItem,
	footprint_size: Vector2,
	rotated: bool,
	positive: bool,
) -> Control:
	var layer := Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.size = footprint_size

	var texture_rect := TextureRect.new()
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.modulate = Color(1.0, 1.0, 1.0, 0.95)
	texture_rect.texture = item.get_texture() if item != null else null

	if rotated:
		texture_rect.size = Vector2(footprint_size.y, footprint_size.x)
		if positive:
			texture_rect.position = Vector2(texture_rect.size.y, 0.0)
			texture_rect.rotation = PI * 0.5
		else:
			texture_rect.position = Vector2(0.0, texture_rect.size.x)
			texture_rect.rotation = -PI * 0.5
	else:
		texture_rect.size = footprint_size

	layer.add_child(texture_rect)
	return layer

static func _build_grid_cells_layer(
	grid_size: Vector2i,
	field_dimensions: Vector2,
	item_spacing: int,
) -> Control:
	var layer := Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var cell_style := StyleBoxFlat.new()
	cell_style.bg_color = Color(0.2, 0.2, 0.24, 0.82)
	cell_style.border_color = Color(0.58, 0.58, 0.65, 0.95)
	cell_style.set_border_width_all(1)

	for y: int in grid_size.y:
		for x: int in grid_size.x:
			var cell := Panel.new()
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.position = _cell_position(Vector2i(x, y), field_dimensions, item_spacing)
			cell.size = field_dimensions
			cell.add_theme_stylebox_override("panel", cell_style)
			layer.add_child(cell)

	return layer

static func _cell_position(
	cell: Vector2i,
	field_dimensions: Vector2,
	item_spacing: int,
) -> Vector2:
	return Vector2(cell) * field_dimensions + Vector2(cell) * float(item_spacing)

static func _item_grid_size(item: InventoryItem, preview_rotated: Variant = null) -> Vector2i:
	var size_value: Variant = item.get_property(GridConstraint._KEY_SIZE, Vector2i.ONE)
	var base_size: Vector2i = size_value if size_value is Vector2i else Vector2i.ONE
	var rotated: bool = preview_rotated if preview_rotated != null else GridConstraint.is_item_rotated(item)
	if rotated:
		return Vector2i(base_size.y, base_size.x)
	return base_size
