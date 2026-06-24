extends ScrollContainer
class_name PickableItemList

const PICKABLE_ITEMS: Array[Dictionary] = [
	{"id": "weapons/sword", "name": "剑"},
	{"id": "weapons/poleaxe", "name": "长柄斧"},
	{"id": "weapons/spear", "name": "长矛"},
	{"id": "weapons/fire_ball", "name": "火球"},
]

@export var field_dimensions: Vector2 = Vector2(48, 48)
@export var item_spacing: int = 2

var backpack: Inventory
var inventory_grid_basic: Control

@onready var _list: VBoxContainer = %ItemVBox

func _ready() -> void:
	_rebuild_rows()

func setup(source_backpack: Inventory) -> void:
	backpack = source_backpack
	for row: Node in _list.get_children():
		if row is PickableItemRow:
			var pickable_row: PickableItemRow = row as PickableItemRow
			pickable_row.backpack = backpack
			pickable_row.inventory_grid_basic = inventory_grid_basic
	_rebuild_rows()

func _rebuild_rows() -> void:
	for child: Node in _list.get_children():
		child.queue_free()
	for entry: Dictionary in PICKABLE_ITEMS:
		var row := PickableItemRow.new()
		row.name = str(entry["id"]).replace("/", "_")
		row.prototype_id = str(entry["id"])
		row.display_name = str(entry["name"])
		row.field_dimensions = field_dimensions
		row.item_spacing = item_spacing
		row.backpack = backpack
		row.inventory_grid_basic = inventory_grid_basic
		row.custom_minimum_size = Vector2(0, 40)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var panel := PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var margin := MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_bottom", 6)
		var label := Label.new()
		label.text = str(entry["name"])
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(label)
		panel.add_child(margin)
		row.add_child(panel)
		_list.add_child(row)
