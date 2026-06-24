extends "res://addons/gloot/ui/ctrl_inventory_grid_basic.gd"

const _CtrlDraggableGridPreview = preload("res://scripts/ui/ctrl_draggable_inventory_item_grid_preview.gd")

func _populate_list() -> void:
	var grid_constraint: GridConstraint = inventory.get_constraint(GridConstraint)
	if not is_instance_valid(inventory) or grid_constraint == null or not is_instance_valid(_ctrl_item_container):
		return

	for item: InventoryItem in inventory.get_items():
		var ctrl_draggable: CtrlDraggableInventoryItemGridPreview = _CtrlDraggableGridPreview.new()
		ctrl_draggable.item = item
		ctrl_draggable.field_dimensions = field_dimensions
		ctrl_draggable.item_spacing = item_spacing
		ctrl_draggable.ctrl_inventory_item_scene = custom_item_control_scene
		ctrl_draggable.activated.connect(_on_inventory_item_activated.bind(ctrl_draggable))
		ctrl_draggable.clicked.connect(_on_inventory_item_clicked.bind(ctrl_draggable))
		ctrl_draggable.mouse_entered.connect(_on_item_mouse_entered.bind(ctrl_draggable))
		ctrl_draggable.mouse_exited.connect(_on_item_mouse_exited.bind(ctrl_draggable))
		ctrl_draggable.size = _get_item_sprite_size(item)
		ctrl_draggable.position = _get_field_position(grid_constraint.get_item_position(item))
		ctrl_draggable.icon_stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		if stretch_item_icons:
			ctrl_draggable.icon_stretch_mode = TextureRect.STRETCH_SCALE
		ctrl_draggable.drag_tint = drag_tint
		_ctrl_item_container.add_child(ctrl_draggable)
