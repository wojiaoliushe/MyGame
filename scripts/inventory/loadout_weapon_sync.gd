extends Node
class_name LoadoutWeaponSync

## 背包内每件带 weapon_scene 的物品，在 Player 下生成一个 Weapon 子节点（等同旧暂停菜单「添加武器」）。

const META_INVENTORY_ITEM_ID := "loadout_inventory_item_id"

@export var player_path: NodePath = NodePath("..")
@export var backpack_path: NodePath = NodePath("../Backpack")

var _backpack: Inventory
var _sync_pending: bool = false

func _ready() -> void:
	_backpack = get_node_or_null(backpack_path) as Inventory
	if _backpack == null:
		push_warning("LoadoutWeaponSync: 未找到背包 Inventory（path=%s）" % backpack_path)
		return
	_backpack.item_added.connect(_on_backpack_changed)
	_backpack.item_removed.connect(_on_backpack_changed)
	_backpack.item_moved.connect(_on_backpack_changed)
	_backpack.constraint_changed.connect(_on_backpack_changed)
	request_sync()

func _on_backpack_changed(_arg: Variant = null) -> void:
	request_sync()

func request_sync() -> void:
	if _sync_pending:
		return
	_sync_pending = true
	call_deferred("_run_deferred_sync")

func _run_deferred_sync() -> void:
	_sync_pending = false
	sync_from_backpack()

func sync_from_backpack() -> void:
	var player: Player = _resolve_player()
	if player == null:
		return
	if _backpack == null:
		push_warning("LoadoutWeaponSync: 背包未初始化")
		return

	for child: Node in player.get_children():
		if child is Weapon:
			player.remove_child(child)
			child.queue_free()

	for item: InventoryItem in _backpack.get_items():
		_spawn_weapon_for_item(player, item)

func _resolve_player() -> Player:
	var node: Node = get_node_or_null(player_path)
	if node is Player:
		return node as Player
	var parent: Node = get_parent()
	if parent is Player:
		return parent as Player
	push_warning("LoadoutWeaponSync: 无法解析 Player（player_path=%s）" % player_path)
	return null

func _spawn_weapon_for_item(player: Player, item: InventoryItem) -> void:
	var scene_path: String = str(item.get_property("weapon_scene", ""))
	if scene_path.is_empty():
		var proto_id: String = item.get_prototype().get_prototype_id() if item.get_prototype() else "?"
		push_warning("LoadoutWeaponSync: 物品 %s 无 weapon_scene" % proto_id)
		return
	if not ResourceLoader.exists(scene_path):
		push_warning("LoadoutWeaponSync: 无效 weapon_scene: %s" % scene_path)
		return
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		return
	var weapon: Node = packed.instantiate()
	if not weapon is Weapon:
		push_warning("LoadoutWeaponSync: 场景不是 Weapon: %s" % scene_path)
		weapon.queue_free()
		return
	weapon.set_meta(META_INVENTORY_ITEM_ID, item.get_instance_id())
	player.add_child(weapon)
