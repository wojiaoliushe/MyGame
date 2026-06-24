extends CanvasLayer
class_name BackpackPanel

const FIELD_DIMENSIONS := Vector2(48, 48)
const ITEM_SPACING := 2

@export var player_backpack_path: NodePath = NodePath("../Player/Backpack")
@export var loadout_sync_path: NodePath = NodePath("../Player/LoadoutWeaponSync")

@onready var _inventory_grid: MyGameCtrlInventoryGrid = %InventoryGrid
@onready var _pickable_list: PickableItemList = %PickableItemList
@onready var _delete_zone: InventoryDeleteDropZone = %DeleteDropZone
@onready var _btn_resume: Button = %BtnResume

var _backpack: Inventory

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_pause_immune_process(self)
	visible = false
	_backpack = get_node_or_null(player_backpack_path) as Inventory
	if _backpack != null:
		_inventory_grid.inventory = _backpack
		_inventory_grid.field_dimensions = FIELD_DIMENSIONS
		_inventory_grid.item_spacing = ITEM_SPACING
		_inventory_grid.stretch_item_icons = true
		_pickable_list.field_dimensions = FIELD_DIMENSIONS
		_pickable_list.item_spacing = ITEM_SPACING
		_pickable_list.inventory_grid_basic = _inventory_grid.get_inventory_grid_basic()
		_pickable_list.setup(_backpack)
		_delete_zone.inventory = _backpack
		_delete_zone.item_deleted.connect(_on_inventory_item_deleted)
		_inventory_grid.item_dropped.connect(_on_inventory_item_dropped)
	else:
		push_warning("BackpackPanel: 未绑定玩家背包")
	_btn_resume.pressed.connect(close)

func _set_pause_immune_process(n: Node) -> void:
	for c: Node in n.get_children():
		c.process_mode = Node.PROCESS_MODE_ALWAYS
		_set_pause_immune_process(c)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R and InventoryDragSession.try_rotate_clockwise():
			get_viewport().set_input_as_handled()

func open() -> void:
	if _backpack == null:
		_backpack = get_node_or_null(player_backpack_path) as Inventory
		if _backpack != null:
			_inventory_grid.inventory = _backpack
			_pickable_list.inventory_grid_basic = _inventory_grid.get_inventory_grid_basic()
			_pickable_list.setup(_backpack)
			_delete_zone.inventory = _backpack
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	_request_loadout_sync()
	get_tree().paused = false

func _on_inventory_item_dropped(_item: InventoryItem, _offset: Vector2) -> void:
	_request_loadout_sync()

func _on_inventory_item_deleted(_item: InventoryItem) -> void:
	_request_loadout_sync()

func _request_loadout_sync() -> void:
	var sync: LoadoutWeaponSync = get_node_or_null(loadout_sync_path) as LoadoutWeaponSync
	if sync != null:
		sync.request_sync()

func toggle() -> void:
	if visible:
		close()
	else:
		open()
