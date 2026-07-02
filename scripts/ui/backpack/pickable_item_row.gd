extends Control
class_name PickableItemRow

@export var prototype_id: String = ""
@export var display_name: String = ""

var backpack: Inventory
var inventory_grid_basic: Control
var field_dimensions: Vector2 = Vector2(48, 48)
var item_spacing: int = 2

func _get_drag_data(_at_position: Vector2) -> Variant:
	if backpack == null or prototype_id.is_empty() or inventory_grid_basic == null:
		return null
	var item: InventoryItem = backpack.create_item(prototype_id)
	if item == null:
		return null
	return InventoryDragSession.start_drag_from_control(
		self, item, inventory_grid_basic, field_dimensions, item_spacing
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		InventoryDragSession.end_drag()
