extends PanelContainer
class_name InventoryDeleteDropZone

signal item_deleted(item: InventoryItem)

@export var inventory: Inventory

var _can_accept_drop: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(56, 210)
	_apply_style(false)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var accepted := _accepts_item(data)
	_set_drop_highlight(accepted)
	return accepted

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_set_drop_highlight(false)
	if inventory == null or not data is InventoryItem:
		return
	var item: InventoryItem = data as InventoryItem
	if inventory.remove_item(item):
		item_deleted.emit(item)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_set_drop_highlight(false)

func _accepts_item(data: Variant) -> bool:
	if inventory == null or not data is InventoryItem:
		return false
	return inventory.has_item(data as InventoryItem)

func _set_drop_highlight(active: bool) -> void:
	if active == _can_accept_drop:
		return
	_can_accept_drop = active
	_apply_style(active)

func _apply_style(highlight: bool) -> void:
	var style := StyleBoxFlat.new()
	if highlight:
		style.bg_color = Color(0.55, 0.18, 0.18, 0.95)
		style.border_color = Color(0.95, 0.35, 0.35, 1)
	else:
		style.bg_color = Color(0.2, 0.14, 0.14, 0.9)
		style.border_color = Color(0.45, 0.28, 0.28, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	add_theme_stylebox_override("panel", style)
