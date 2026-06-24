extends RefCounted
class_name InventoryDragSession

## 统一背包内/右侧列表的拖拽：预览、R 旋转、落格确认均走此会话。
## 拖动过程中只维护待确认旋转，松手落格时才写入道具。

static var _active: bool = false
static var _item: InventoryItem
static var _grid_basic: Control
static var _field_dimensions: Vector2 = Vector2(48, 48)
static var _item_spacing: int = 0
static var _preview_root: Control
static var _offset_source: Control
static var _was_in_inventory: bool = false
static var _start_rotated: bool = false
static var _start_positive: bool = false
static var _start_position: Vector2i = Vector2i.ZERO
static var _pending_rotated: bool = false
static var _pending_positive: bool = true
static var _grid_drop_handled: bool = false
static var _delete_drop_handled: bool = false

static func start_drag_from_control(
	source: Control,
	item: InventoryItem,
	grid_basic: Control,
	field_dimensions: Vector2,
	item_spacing: int,
) -> Variant:
	if item == null or grid_basic == null or source == null:
		return null
	_begin(item, grid_basic, field_dimensions, item_spacing, source)
	var wrapped: Control = _build_drag_preview_wrapper()
	source.set_drag_preview(wrapped)
	return item

static func try_rotate_clockwise() -> bool:
	if not _active or _item == null:
		return false
	if _is_square(_item):
		return false
	_pending_rotated = not _pending_rotated
	if _pending_rotated:
		_pending_positive = true
	_refresh_drag_preview()
	return true

static func apply_pending_rotation() -> void:
	if not _active or _item == null:
		return
	_set_rotation_state(_item, _pending_rotated, _pending_positive)

static func mark_grid_drop_handled() -> void:
	_grid_drop_handled = true

static func mark_delete_drop_handled() -> void:
	_delete_drop_handled = true

static func finalize_grid_drop(
	item: InventoryItem,
	over_grid: bool,
	field_coords: Vector2i,
	pos_before: Vector2i,
	was_in_inventory: bool,
) -> void:
	if not _active or item != _item:
		return
	mark_grid_drop_handled()
	if not was_in_inventory:
		return
	if not over_grid:
		restore_start_rotation()
		return
	if _was_drop_successful(item, pos_before, field_coords):
		return
	restore_start_rotation()

static func end_drag() -> void:
	if not _active:
		return
	if not _grid_drop_handled and not _delete_drop_handled and _was_in_inventory:
		restore_start_rotation()
	_clear()

static func restore_start_rotation() -> void:
	if _item == null:
		return
	_set_rotation_state(_item, _start_rotated, _start_positive)

static func is_active() -> bool:
	return _active

static func _begin(
	item: InventoryItem,
	grid_basic: Control,
	field_dimensions: Vector2,
	item_spacing: int,
	offset_source: Control,
) -> void:
	_active = true
	_item = item
	_grid_basic = grid_basic
	_field_dimensions = field_dimensions
	_item_spacing = item_spacing
	_offset_source = offset_source
	_grid_drop_handled = false
	_delete_drop_handled = false
	var grid: GridConstraint = _get_grid_constraint()
	_was_in_inventory = grid != null and grid.inventory.has_item(item)
	_start_rotated = GridConstraint.is_item_rotated(item)
	_start_positive = GridConstraint.is_item_rotation_positive(item)
	_pending_rotated = _start_rotated
	_pending_positive = _start_positive
	_start_position = grid.get_item_position(item) if _was_in_inventory else Vector2i.ZERO

static func _build_drag_preview_wrapper() -> Control:
	var preview_size: Vector2 = InventoryDragPreview.item_sprite_size_px(
		_item, _field_dimensions, _item_spacing, _pending_rotated
	)
	var grab_offset: Vector2 = preview_size * 0.5
	CtrlDraggableInventoryItemGridPreview.register_external_grab_offset(grab_offset, _offset_source)
	var preview: Control = InventoryDragPreview.build(
		_item, _field_dimensions, _item_spacing, _pending_rotated, _pending_positive
	)
	_preview_root = InventoryDragPreview.anchor_preview(preview, grab_offset)
	return _preview_root

static func _was_drop_successful(
	item: InventoryItem,
	pos_before: Vector2i,
	field_coords: Vector2i,
) -> bool:
	var grid: GridConstraint = _get_grid_constraint()
	if grid == null or not grid.inventory.has_item(item):
		return false
	var pos_after: Vector2i = grid.get_item_position(item)
	if pos_after != pos_before:
		return true
	if pos_after == field_coords:
		return _can_place_at_with_rotation(grid, item, field_coords, _pending_rotated)
	return false

static func _get_grid_constraint() -> GridConstraint:
	if _grid_basic == null or _grid_basic.inventory == null:
		return null
	return _grid_basic.inventory.get_constraint(GridConstraint) as GridConstraint

static func _can_place_at_with_rotation(
	grid: GridConstraint,
	item: InventoryItem,
	field_coords: Vector2i,
	rotated: bool,
) -> bool:
	var rect := Rect2i(field_coords, _effective_item_size(item, rotated))
	var exception: InventoryItem = item if grid.inventory.has_item(item) else null
	return grid.rect_free(rect, exception)

static func _effective_item_size(item: InventoryItem, rotated: bool) -> Vector2i:
	var size_value: Variant = item.get_property(GridConstraint._KEY_SIZE, Vector2i.ONE)
	var base_size: Vector2i = size_value if size_value is Vector2i else Vector2i.ONE
	if rotated:
		return Vector2i(base_size.y, base_size.x)
	return base_size

static func _is_square(item: InventoryItem) -> bool:
	var size_value: Variant = item.get_property(GridConstraint._KEY_SIZE, Vector2i.ONE)
	var base_size: Vector2i = size_value if size_value is Vector2i else Vector2i.ONE
	return base_size.x == base_size.y

static func _set_rotation_state(item: InventoryItem, rotated: bool, positive: bool) -> void:
	if rotated:
		item.set_property(GridConstraint._KEY_ROTATED, true)
		GridConstraint.set_item_rotation_direction(item, positive)
	else:
		item.clear_property(GridConstraint._KEY_ROTATED)
		item.clear_property(GridConstraint._KEY_POSITIVE_ROTATION)

static func _refresh_drag_preview() -> void:
	if _preview_root == null or _item == null:
		return
	var preview_size: Vector2 = InventoryDragPreview.item_sprite_size_px(
		_item, _field_dimensions, _item_spacing, _pending_rotated
	)
	var grab_offset: Vector2 = preview_size * 0.5
	CtrlDraggableInventoryItemGridPreview.register_external_grab_offset(grab_offset, _offset_source)
	for child: Node in _preview_root.get_children():
		child.queue_free()
	var preview: Control = InventoryDragPreview.build(
		_item, _field_dimensions, _item_spacing, _pending_rotated, _pending_positive
	)
	preview.position = -grab_offset
	_preview_root.add_child(preview)

static func _clear() -> void:
	_active = false
	_item = null
	_grid_basic = null
	_preview_root = null
	_offset_source = null
	_was_in_inventory = false
	_grid_drop_handled = false
	_delete_drop_handled = false
