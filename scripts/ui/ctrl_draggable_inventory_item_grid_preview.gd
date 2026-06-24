extends "res://addons/gloot/ui/ctrl_draggable_inventory_item.gd"
class_name CtrlDraggableInventoryItemGridPreview

## 背包格内拖拽：预览复用 InventoryDragPreview（底层占格格子 + 上层贴图）。

var field_dimensions: Vector2 = Vector2(32, 32)
var item_spacing: int = 0

## 外部 force_drag 时须注册抓取偏移，与 GLoot 网格 _drop_data 的落点计算一致。
static func register_external_grab_offset(grab_offset_local: Vector2, source: Control) -> void:
	_grab_offset = grab_offset_local * source.get_global_transform().get_scale()

func _create_preview() -> Control:
	if item == null:
		return null
	return InventoryDragPreview.build(item, field_dimensions, item_spacing)
