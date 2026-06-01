extends Weapon
class_name ThrustWeapon

signal thrust_finished

func _get_thrust_duration() -> float:
	return 0.18

func _get_thrust_recover_duration() -> float:
	return 0.1

func _get_blade_retract_x() -> float:
	return 8.0

func _get_blade_extend_x() -> float:
	return 36.0

func _get_thrust_extra_reach() -> float:
	return 12.0

func _get_check_interval() -> float:
	return 1.2

func _get_auto_attack_enabled() -> bool:
	return true

## 伸出姿态下读取 .tscn 里 Hitbox / CollisionShape2D（不覆盖场景尺寸）。
func get_attack_range() -> float:
	var saved_blade_pos: Vector2 = blade.position
	var saved_hitbox_pos: Vector2 = hitbox.position
	if _wielder == null or hitbox_shape == null or hitbox_shape.shape == null:
		return 0.0
	blade.position = _get_extended_blade_position()
	_sync_hitbox_to_blade()
	var range_val: float = Weapon.compute_attack_reach_from_wielder(_wielder, self, hitbox_shape)
	blade.position = saved_blade_pos
	hitbox.position = saved_hitbox_pos
	return range_val

@onready var blade: Sprite2D = $Blade
@onready var hitbox: Area2D = $Hitbox

var hitbox_shape: CollisionShape2D
var _wielder: Node2D
var _thrust_active: bool = false
var _hit_instance_ids: Dictionary = {}
var _attack_range: float = 0.0
var _check_timer: float = 0.0
var _next_check_wait: float = 0.0
var _scene_retracted_blade_pos: Vector2 = Vector2.ZERO
var _hitbox_offset_from_blade: Vector2 = Vector2.ZERO

func _ready() -> void:
	_wielder = get_parent() as Node2D
	if _wielder == null:
		push_error("ThrustWeapon: 须作为 Player 等 Node2D 的子节点（%s）" % get_path())
	hitbox_shape = _find_collision_shape(hitbox)
	if hitbox_shape == null:
		push_error("ThrustWeapon: Hitbox 下缺少 CollisionShape2D（%s）" % get_path())
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.monitoring = false
	visible = false
	_scene_retracted_blade_pos = blade.position
	_hitbox_offset_from_blade = hitbox.position - blade.position
	blade.position = _get_retracted_blade_position()
	_sync_hitbox_to_blade()
	_attack_range = get_attack_range()
	_next_check_wait = sample_next_attack_interval(_get_check_interval())
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _thrust_active:
		_sync_hitbox_to_blade()
		_poll_hitbox_overlaps()
	if not _get_auto_attack_enabled() or _thrust_active or _wielder == null:
		return
	_check_timer += delta
	if _check_timer < _next_check_wait:
		return
	_check_timer = 0.0
	_next_check_wait = sample_next_attack_interval(_get_check_interval())
	var target: Node2D = Weapon.find_nearest_enemy_in_range(_wielder, _attack_range)
	if target == null:
		return
	begin_thrust(_wielder, target.global_position)

func begin_thrust(wielder: Node2D, target_global: Vector2) -> void:
	position = Vector2.ZERO
	rotation = (target_global - wielder.global_position).angle()
	blade.position = _get_retracted_blade_position()
	_sync_hitbox_to_blade()
	_hit_instance_ids.clear()
	_thrust_active = true
	visible = true
	hitbox.monitoring = true
	_poll_hitbox_overlaps()
	call_deferred("_poll_hitbox_overlaps")
	var retracted: Vector2 = _get_retracted_blade_position()
	var extended: Vector2 = _get_extended_blade_position()
	var tween: Tween = create_tween()
	tween.tween_property(blade, "position", extended, _get_thrust_duration())
	tween.tween_callback(_on_thrust_extended)
	tween.tween_property(blade, "position", retracted, _get_thrust_recover_duration())
	tween.tween_callback(_finish_thrust)

func _on_thrust_extended() -> void:
	hitbox.monitoring = false

func _finish_thrust() -> void:
	_thrust_active = false
	hitbox.monitoring = false
	visible = false
	blade.position = _get_retracted_blade_position()
	_sync_hitbox_to_blade()
	thrust_finished.emit()

func _sync_hitbox_to_blade() -> void:
	hitbox.position = blade.position + _hitbox_offset_from_blade

func _find_collision_shape(area: Area2D) -> CollisionShape2D:
	for child: Node in area.get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null

func _get_retracted_blade_position() -> Vector2:
	var marker: Node2D = get_node_or_null("RangeSampleRetract") as Node2D
	if marker != null:
		return marker.position
	return _scene_retracted_blade_pos

func _get_extended_blade_position() -> Vector2:
	var marker: Node2D = get_node_or_null("RangeSampleExtended") as Node2D
	if marker != null:
		return marker.position
	# 无 Marker 时：保持场景里收回姿态的 Y/对齐方式，仅沿局部 +X 伸出
	var thrust_delta_x: float = (_get_blade_extend_x() + _get_thrust_extra_reach()) - _get_blade_retract_x()
	return _get_retracted_blade_position() + Vector2(thrust_delta_x, 0.0)

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
	if body.has_method("die"):
		body.die()
	else:
		body.queue_free()
