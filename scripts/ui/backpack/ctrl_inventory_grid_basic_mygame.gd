extends "res://addons/gloot/ui/ctrl_inventory_grid_basic.gd"

const _CtrlDraggableGridPreview = preload("res://scripts/ui/backpack/ctrl_draggable_inventory_item_grid_preview.gd")

func _populate_list() -> void:
	var grid_constraint: GridConstraint = inventory.get_constraint(GridConstraint)
	if not is_instance_valid(inventory) or grid_constraint == null or not is_instance_valid(_ctrl_item_container):
		return

	for item: InventoryItem in inventory.get_items():
		var ctrl_draggable: CtrlDraggableInventoryItemGridPreview = _CtrlDraggableGridPreview.new()
		ctrl_draggable.item = item
		ctrl_draggable.field_dimensions = field_dimensions
		ctrl_draggable.item_spacing = item_spacing
		ctrl_draggable.inventory_grid_basic = self
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

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var item: InventoryItem = data as InventoryItem
	if not is_instance_valid(item):
		return
	var local_offset: Vector2 = _CtrlDraggableInventoryItem.get_grab_offset_local_to(self)
	at_position -= local_offset
	var grid_constraint: GridConstraint = inventory.get_constraint(GridConstraint)
	var was_in_inventory: bool = inventory.has_item(item)
	var pos_before: Vector2i = grid_constraint.get_item_position(item) if was_in_inventory else Vector2i.ZERO
	var drop_position: Vector2 = at_position + field_dimensions * 0.5
	var over_grid: bool = _is_hovering(drop_position)
	var field_coords: Vector2i = get_field_coords(drop_position) if over_grid else Vector2i.ZERO

	if InventoryDragSession.is_active():
		InventoryDragSession.apply_pending_rotation()
	_on_item_dropped(item, at_position)
	InventoryDragSession.finalize_grid_drop(
		item, over_grid, field_coords, pos_before, was_in_inventory
	)
