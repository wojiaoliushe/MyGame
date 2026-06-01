extends Node2D
class_name Weapon

## 武器通用基类；具体逻辑由挥砍（SlashWeapon）、戳刺（ThrustWeapon）、远程（RangeWeapon）等子类实现。

func sample_next_attack_interval(base_seconds: float) -> float:
	return base_seconds * randf_range(0.9, 1.1)

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

## 待机姿态下，从持有者到 Hitbox 最远点的世界距离（与 find_nearest_enemy_in_range 的圆心一致）。
static func compute_attack_reach_from_wielder(
	wielder: Node2D,
	weapon: Node2D,
	collision_shape: CollisionShape2D,
) -> float:
	if collision_shape == null or collision_shape.shape == null:
		return 0.0
	var saved_rot: float = weapon.rotation
	weapon.rotation = 0.0
	var best: float = 0.0
	for corner: Vector2 in _shape_corners_in_shape_local_space(collision_shape.shape):
		var global_point: Vector2 = collision_shape.global_transform * corner
		best = maxf(best, wielder.global_position.distance_to(global_point))
	weapon.rotation = saved_rot
	return best

static func _shape_corners_in_shape_local_space(shape: Shape2D) -> PackedVector2Array:
	if shape is RectangleShape2D:
		var rect: RectangleShape2D = shape as RectangleShape2D
		return PackedVector2Array([
			Vector2(rect.size.x, 0)
		])
	return PackedVector2Array()
