extends Weapon
class_name SlashWeapon

signal swing_finished

## 子类覆盖以提供挥扫总角度（度）。
func _get_swing_arc_deg() -> float:
	return 90.0

## 子类覆盖以提供挥击动画时长（秒）。
func _get_swing_duration() -> float:
	return 0.22

## 作为持有者子节点时，自动索敌攻击的间隔（秒）。
func _get_check_interval() -> float:
	return 1.0

func _get_auto_attack_enabled() -> bool:
	return true

## 索敌半径：场景中 Hitbox 最远点相对持有者（Player）的距离，与索敌圆心一致。
func get_attack_range() -> float:
	if _wielder == null or hitbox_shape == null or hitbox_shape.shape == null:
		return 0.0
	return Weapon.compute_attack_reach_from_wielder(_wielder, self, hitbox_shape)

@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

var _wielder: Node2D
var _swing_active: bool = false
var _hit_instance_ids: Dictionary = {}
var _attack_range: float = 0.0
var _check_timer: float = 0.0
var _next_check_wait: float = 0.0

func _ready() -> void:
	_apply_weapon_stats()
	_wielder = get_parent() as Node2D
	if _wielder == null:
		push_error("SlashWeapon: 须作为 Player 等 Node2D 的子节点（%s）" % get_path())
	if hitbox_shape == null:
		push_error("SlashWeapon: Hitbox 下缺少 CollisionShape2D（%s）" % get_path())
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.monitoring = false
	visible = false
	_attack_range = get_attack_range()
	_next_check_wait = sample_next_attack_interval(_get_check_interval())
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _swing_active:
		_poll_hitbox_overlaps()
	if not _get_auto_attack_enabled() or _swing_active or _wielder == null:
		return
	_check_timer += delta
	if _check_timer < _next_check_wait:
		return
	_check_timer = 0.0
	_next_check_wait = sample_next_attack_interval(_get_check_interval())
	var target: Node2D = Weapon.find_nearest_enemy_in_range(_wielder, _attack_range)
	if target == null:
		return
	begin_swing(_wielder, target.global_position)

## 持有者朝右为 true（与 Player 的 Sprite2D.flip_h 一致：向右时 flip_h=true）。
func _wielder_faces_right(wielder: Node2D, target_global: Vector2) -> bool:
	if wielder is Player:
		var player: Player = wielder as Player
		if player.sprite_2d != null:
			return player.sprite_2d.flip_h
	return (target_global.x - wielder.global_position.x) >= 0.0

## 需已挂为 wielder 的子节点，挥击时随 wielder 移动；目标为世界坐标。
## 朝右：顺时针挥扫（rotation 增大）；朝左：逆时针挥扫（rotation 减小）。
func begin_swing(wielder: Node2D, target_global: Vector2) -> void:
	position = Vector2.ZERO
	var wielder_global: Vector2 = wielder.global_position
	var to_target: float = (target_global - wielder_global).angle()
	var half_arc: float = deg_to_rad(_get_swing_arc_deg() * 0.5)
	var start_rot: float
	var end_rot: float
	if _wielder_faces_right(wielder, target_global):
		start_rot = to_target - half_arc
		end_rot = to_target + half_arc
	else:
		start_rot = to_target + half_arc
		end_rot = to_target - half_arc
	rotation = start_rot
	_hit_instance_ids.clear()
	_swing_active = true
	visible = true
	hitbox.monitoring = true
	_poll_hitbox_overlaps()
	call_deferred("_poll_hitbox_overlaps")
	var tween: Tween = create_tween()
	tween.tween_property(self, "rotation", end_rot, _get_swing_duration())
	tween.tween_callback(_finish_swing)

func _finish_swing() -> void:
	_swing_active = false
	hitbox.monitoring = false
	visible = false
	swing_finished.emit()

func _poll_hitbox_overlaps() -> void:
	if not hitbox.monitoring:
		return
	for body: Node2D in hitbox.get_overlapping_bodies():
		_try_hit_enemy(body)

func _on_hitbox_body_entered(body: Node) -> void:
	_try_hit_enemy(body)

func _try_hit_enemy(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return
	var id: int = body.get_instance_id()
	if _hit_instance_ids.has(id):
		return
	_hit_instance_ids[id] = true
	apply_damage_to(body)
