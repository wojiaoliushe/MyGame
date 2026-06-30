extends Weapon
class_name RangeWeapon

## 子类覆盖：发射的弹体场景。
func _get_projectile_scene() -> PackedScene:
	return null

func _get_shoot_interval() -> float:
	return 1.0

func _get_max_range() -> float:
	return 400.0

func _get_auto_shoot_enabled() -> bool:
	return true

var _shoot_timer: float = 0.0
var _next_shoot_wait: float = 0.0

func _ready() -> void:
	_apply_weapon_stats()
	_next_shoot_wait = sample_next_attack_interval(_get_shoot_interval())
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	if not _get_auto_shoot_enabled():
		return
	var wielder: Node2D = get_parent() as Node2D
	if wielder == null:
		return
	_shoot_timer += _delta
	if _shoot_timer < _next_shoot_wait:
		return
	_shoot_timer = 0.0
	_next_shoot_wait = sample_next_attack_interval(_get_shoot_interval())
	var target: Node2D = _find_nearest_enemy_in_range(wielder, _get_max_range())
	if target == null:
		return
	_fire_projectile(wielder, target)

func _find_nearest_enemy_in_range(origin: Node2D, range_max: float) -> Node2D:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var min_dist: float = range_max
	for enemy: Node2D in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = origin.global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = enemy
	return nearest

func _fire_projectile(from: Node2D, target: Node2D) -> void:
	var scene: PackedScene = _get_projectile_scene()
	if scene == null:
		return
	var to_target: Vector2 = target.global_position - from.global_position
	var angle: float = to_target.angle()
	var dir: Vector2 = to_target.normalized()
	var projectile: Node2D = scene.instantiate() as Node2D
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = from.global_position
	projectile.global_rotation = angle
	projectile.set("direction", dir)
	projectile.set("damage", damage)
