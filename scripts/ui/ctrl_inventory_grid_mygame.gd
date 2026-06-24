@tool
extends CtrlInventoryGrid
class_name MyGameCtrlInventoryGrid

const _MyCtrlInventoryGridBasic = preload("res://scripts/ui/ctrl_inventory_grid_basic_mygame.gd")

func _ready() -> void:
	_background = CustomizablePanel.new()
	_background.name = "Background"
	_background.set_style(_get_background_style())
	add_child(_background)

	_field_background_grid = Control.new()
	_field_background_grid.name = "FieldBackgrounds"
	add_child(_field_background_grid)

	_ctrl_inventory_grid_basic = _MyCtrlInventoryGridBasic.new()
	_ctrl_inventory_grid_basic.custom_item_control_scene = custom_item_control_scene
	_ctrl_inventory_grid_basic.drag_tint = drag_tint
	_ctrl_inventory_grid_basic.inventory = inventory
	_ctrl_inventory_grid_basic.field_dimensions = field_dimensions
	_ctrl_inventory_grid_basic.item_spacing = item_spacing
	_ctrl_inventory_grid_basic.stretch_item_icons = stretch_item_icons
	_ctrl_inventory_grid_basic.name = "_CtrlInventoryGridBasic"
	_ctrl_inventory_grid_basic.resized.connect(_update_size)
	_ctrl_inventory_grid_basic.item_dropped.connect(func(item: InventoryItem, drop_position: Vector2):
		item_dropped.emit(item, drop_position)
	)
	_ctrl_inventory_grid_basic.inventory_item_activated.connect(func(item: InventoryItem):
		inventory_item_activated.emit(item)
	)
	_ctrl_inventory_grid_basic.inventory_item_clicked.connect(func(item: InventoryItem, at_position: Vector2, mouse_button_index: int):
		inventory_item_clicked.emit(item, at_position, mouse_button_index)
	)
	_ctrl_inventory_grid_basic.inventory_item_selected.connect(func(item: InventoryItem):
		inventory_item_selected.emit(item)
	)
	_ctrl_inventory_grid_basic.item_mouse_entered.connect(_on_item_mouse_entered)
	_ctrl_inventory_grid_basic.item_mouse_exited.connect(_on_item_mouse_exited)
	_ctrl_inventory_grid_basic.selection_changed.connect(_on_selection_changed)
	_ctrl_inventory_grid_basic.select_mode = select_mode
	_ctrl_inventory_grid_basic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ctrl_inventory_grid_basic)

	_selection_panels = Control.new()
	_selection_panels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selection_panels.name = "SelectionPanels"
	add_child(_selection_panels)

	_update_size()
	_queue_refresh()
