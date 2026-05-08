extends Weapon
class_name MeleeWeapon

signal swing_finished

## 子类覆盖以提供挥扫总角度（度）。
func _get_swing_arc_deg() -> float:
	return 90.0

## 子类覆盖以提供挥击动画时长（秒）。
func _get_swing_duration() -> float:
	return 0.22

## 相对贴图矩形多扩一圈碰撞，减少漏判。
func _get_hitbox_padding_px() -> float:
	return 14.0

## 作为持有者子节点时，自动索敌攻击的间隔（秒）。
func _get_check_interval() -> float:
	return 1.0

func _get_auto_attack_enabled() -> bool:
	return true

## 刃部贴图相对挥击枢轴的水平偏移。
func _get_blade_extend_x() -> float:
	return 30.0

## 与 _align_blade_and_hitbox 布局一致：枢轴在武器节点原点，返回挥扫时刃部最远端相对枢轴的距离（矩形四角到原点距离的最大值）。
static func compute_attack_range_from_blade(texture: Texture2D, blade_extend_x: float, padding_px: float) -> float:
	if texture == null:
		return blade_extend_x
	var sz: Vector2 = texture.get_size()
	var w: float = sz.x + padding_px * 2.0
	var h: float = sz.y + padding_px * 2.0
	var x0: float = blade_extend_x
	var y0: float = -sz.y * 0.5
	var corners: Array[Vector2] = [
		Vector2(x0, y0),
		Vector2(x0 + w, y0),
		Vector2(x0, y0 + h),
		Vector2(x0 + w, y0 + h),
	]
	var best: float = 0.0
	for c: Vector2 in corners:
		best = maxf(best, c.length())
	return best

func get_attack_range() -> float:
	return compute_attack_range_from_blade(blade.texture, _get_blade_extend_x(), _get_hitbox_padding_px())

## 在攻击距离内找最近的 enemies 组成员。
static func find_nearest_enemy_in_range(origin: Node2D, max_range: float) -> Node2D:
	var enemies: Array = origin.get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var min_dist: float = INF
	for enemy: Node2D in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = origin.global_position.distance_to(enemy.global_position)
		if dist <= max_range and (nearest == null or dist < min_dist):
			min_dist = dist
			nearest = enemy
	return nearest

@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var blade: Sprite2D = $Blade

var _swing_active: bool = false
var _hit_instance_ids: Dictionary = {}
var _attack_range: float = 0.0
var _check_timer: float = 0.0
var _next_check_wait: float = 0.0

func _ready() -> void:
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.monitoring = false
	visible = false
	_align_blade_and_hitbox()
	_attack_range = get_attack_range()
	_next_check_wait = sample_next_attack_interval(_get_check_interval())
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _swing_active:
		_poll_hitbox_overlaps()
	if not _get_auto_attack_enabled() or _swing_active:
		return
	var wielder: Node2D = get_parent() as Node2D
	if wielder == null:
		return
	_check_timer += delta
	if _check_timer < _next_check_wait:
		return
	_check_timer = 0.0
	_next_check_wait = sample_next_attack_interval(_get_check_interval())
	var target: Node2D = find_nearest_enemy_in_range(wielder, _attack_range)
	if target == null:
		return
	begin_swing(wielder, target.global_position)

## 需已挂为 wielder 的子节点，挥击时随 wielder 移动；目标为世界坐标。
func begin_swing(wielder: Node2D, target_global: Vector2) -> void:
	position = Vector2.ZERO
	var wielder_global: Vector2 = wielder.global_position
	var to_target: float = (target_global - wielder_global).angle()
	var half_arc: float = deg_to_rad(_get_swing_arc_deg() * 0.5)
	var start_rot: float = to_target - half_arc
	var end_rot: float = to_target + half_arc
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

func _align_blade_and_hitbox() -> void:
	if blade.texture == null:
		return
	var sz: Vector2 = blade.texture.get_size()
	var extend_x: float = _get_blade_extend_x()
	blade.centered = false
	blade.offset = Vector2.ZERO
	blade.rotation = 0.0
	# 水平向右刃部、贴图内容垂直居中：顶边 y=-h/2，使纹理垂直中心落在旋转点 (0,0)
	blade.position = Vector2(extend_x, -sz.y * 0.5)
	# Hitbox 与贴图左上角对齐，矩形覆盖整张贴图 AABB（含 padding），随父节点旋转即扫过区域
	hitbox.position = blade.position
	hitbox.rotation = blade.rotation
	var rect: RectangleShape2D = hitbox_shape.shape as RectangleShape2D
	if rect:
		var pad: float = _get_hitbox_padding_px()
		rect.size = Vector2(sz.x + pad * 2.0, sz.y + pad * 2.0)
		hitbox_shape.position = Vector2(rect.size.x * 0.5, rect.size.y * 0.5)

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
