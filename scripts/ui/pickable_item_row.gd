extends Control
class_name PickableItemRow

const LONG_PRESS_SEC: float = 0.35

@export var prototype_id: String = ""
@export var display_name: String = ""

var backpack: Inventory
var field_dimensions: Vector2 = Vector2(48, 48)
var item_spacing: int = 2

var _hold_timer: float = -1.0
var _press_pos: Vector2 = Vector2.ZERO
var _drag_item: InventoryItem

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_press_pos = mb.position
			_hold_timer = 0.0
		else:
			_hold_timer = -1.0
	elif event is InputEventMouseMotion and _hold_timer >= 0.0:
		var motion: InputEventMouseMotion = event
		if motion.position.distance_to(_press_pos) > 8.0:
			_hold_timer = -1.0

func _process(delta: float) -> void:
	if _hold_timer < 0.0:
		return
	_hold_timer += delta
	if _hold_timer < LONG_PRESS_SEC:
		return
	_hold_timer = -1.0
	_begin_drag()

func _begin_drag() -> void:
	if backpack == null or prototype_id.is_empty():
		return
	var item: InventoryItem = backpack.create_item(prototype_id)
	if item == null:
		return
	_drag_item = item
	var preview_size: Vector2 = InventoryDragPreview.item_sprite_size_px(
		item, field_dimensions, item_spacing
	)
	var grab_offset: Vector2 = Vector2(preview_size.x * 0.5, preview_size.y * 0.5)
	var preview: Control = InventoryDragPreview.build(item, field_dimensions, item_spacing)
	var wrapped: Control = InventoryDragPreview.anchor_preview(preview, grab_offset)
	force_drag(item, wrapped)

func _notification(what: int) -> void:
	if what != NOTIFICATION_DRAG_END:
		return
	if _drag_item == null:
		return
	if _drag_item.get_inventory() == null:
		_drag_item = null
