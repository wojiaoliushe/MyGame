extends "res://addons/gloot/ui/ctrl_draggable_inventory_item.gd"
class_name CtrlDraggableInventoryItemGridPreview

## 背包格内拖拽：预览与旋转逻辑统一由 InventoryDragSession 接管。

const _CtrlDraggableInventoryItem = preload("res://addons/gloot/ui/ctrl_draggable_inventory_item.gd")

var field_dimensions: Vector2 = Vector2(32, 32)
var item_spacing: int = 0
var inventory_grid_basic: Control

static func register_external_grab_offset(grab_offset_local: Vector2, source: Control) -> void:
	_grab_offset = grab_offset_local * source.get_global_transform().get_scale()

static func get_grab_offset_local_to(control: Control) -> Vector2:
	return _CtrlDraggableInventoryItem.get_grab_offset_local_to(control)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item == null or inventory_grid_basic == null:
		return null
	return InventoryDragSession.start_drag_from_control(
		self, item, inventory_grid_basic, field_dimensions, item_spacing
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		if get_viewport().gui_get_drag_data() == item:
			modulate = drag_tint
	elif what == NOTIFICATION_DRAG_END:
		modulate = _initial_modulate
		InventoryDragSession.end_drag()
