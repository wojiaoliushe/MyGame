extends "res://addons/gloot/ui/ctrl_draggable_inventory_item.gd"
class_name CtrlDraggableInventoryItemGridPreview

## 背包格内拖拽：预览复用 InventoryDragPreview（底层占格格子 + 上层贴图）。

var field_dimensions: Vector2 = Vector2(32, 32)
var item_spacing: int = 0

func _create_preview() -> Control:
	if item == null:
		return null
	return InventoryDragPreview.build(item, field_dimensions, item_spacing)
