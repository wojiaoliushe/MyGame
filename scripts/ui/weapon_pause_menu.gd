extends CanvasLayer
class_name WeaponPauseMenu

const _SWORD_SCENE: PackedScene = preload("res://scenes/weapons/sword.tscn")
const _POLEAXE_SCENE: PackedScene = preload("res://scenes/weapons/poleaxe.tscn")
const _FIRE_BALL_SCENE: PackedScene = preload("res://scenes/weapons/fire_ball.tscn")

@export var player_path: NodePath = NodePath("../Player")

@onready var _item_list: ItemList = %WeaponItemList
@onready var _btn_remove: Button = %BtnRemoveLast
@onready var _btn_add_sword: Button = %BtnAddSword
@onready var _btn_add_fireball: Button = %BtnAddFireBall
@onready var _btn_add_poleaxe: Button = %BtnAddPoleaxe
@onready var _btn_resume: Button = %BtnResume

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_pause_immune_process(self)
	visible = false
	_btn_remove.pressed.connect(_on_remove_last_pressed)
	_btn_add_sword.pressed.connect(_on_add_sword_pressed)
	_btn_add_fireball.pressed.connect(_on_add_fireball_pressed)
	_btn_add_poleaxe.pressed.connect(_on_add_poleaxe_pressed)
	_btn_resume.pressed.connect(close)

func _set_pause_immune_process(n: Node) -> void:
	for c: Node in n.get_children():
		c.process_mode = Node.PROCESS_MODE_ALWAYS
		_set_pause_immune_process(c)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()

func open() -> void:
	visible = true
	_refresh_weapon_list()
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

func _player() -> Player:
	return get_node_or_null(player_path) as Player

func _weapon_children() -> Array[Weapon]:
	var p: Player = _player()
	var out: Array[Weapon] = []
	if p == null:
		return out
	for c: Node in p.get_children():
		if c is Weapon:
			out.append(c as Weapon)
	return out

func _weapon_label(w: Weapon) -> String:
	if w is Sword:
		return "剑"
	if w is Poleaxe:
		return "长柄斧"
	if w is FireBall:
		return "火球"
	return w.name

func _refresh_weapon_list() -> void:
	_item_list.clear()
	for w: Weapon in _weapon_children():
		_item_list.add_item(_weapon_label(w))
	_item_list.queue_redraw()

func _on_remove_last_pressed() -> void:
	var p: Player = _player()
	if p == null:
		return
	var list: Array[Weapon] = _weapon_children()
	if list.is_empty():
		return
	var last: Weapon = list[list.size() - 1]
	p.remove_child(last)
	last.queue_free()
	_refresh_weapon_list()

func _on_add_sword_pressed() -> void:
	var p: Player = _player()
	if p == null:
		return
	var inst: Node = _SWORD_SCENE.instantiate()
	p.add_child(inst)
	_refresh_weapon_list()

func _on_add_fireball_pressed() -> void:
	var p: Player = _player()
	if p == null:
		return
	var inst: Node = _FIRE_BALL_SCENE.instantiate()
	p.add_child(inst)
	_refresh_weapon_list()

func _on_add_poleaxe_pressed() -> void:
	var p: Player = _player()
	if p == null:
		return
	var inst: Node = _POLEAXE_SCENE.instantiate()
	p.add_child(inst)
	_refresh_weapon_list()
