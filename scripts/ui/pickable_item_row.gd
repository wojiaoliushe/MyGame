extends Control
class_name PickableItemRow

@export var prototype_id: String = ""
@export var display_name: String = ""

var backpack: Inventory
var field_dimensions: Vector2 = Vector2(48, 48)
var item_spacing: int = 2

var _drag_item: InventoryItem

func _get_drag_data(at_position: Vector2) -> Variant:
	if backpack == null or prototype_id.is_empty():
		return null
	var item: InventoryItem = backpack.create_item(prototype_id)
	if item == null:
		return null
	_drag_item = item
	var preview_size: Vector2 = InventoryDragPreview.item_sprite_size_px(
		item, field_dimensions, item_spacing
	)
	var grab_offset: Vector2 = preview_size * 0.5
	CtrlDraggableInventoryItemGridPreview.register_external_grab_offset(grab_offset, self)
	var preview: Control = InventoryDragPreview.build(item, field_dimensions, item_spacing)
	var wrapped: Control = InventoryDragPreview.anchor_preview(preview, grab_offset)
	set_drag_preview(wrapped)
	return item

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_drag_item = null
