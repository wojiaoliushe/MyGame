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

## 按场景中 CollisionShape2D 的位置、旋转与形状，计算相对武器原点最远索敌距离。
static func compute_attack_range_from_collision_shape(
	weapon: Node2D,
	collision_shape: CollisionShape2D,
) -> float:
	if weapon == null or collision_shape == null or collision_shape.shape == null:
		return 0.0
	var best: float = 0.0
	for corner: Vector2 in _shape_corners_in_shape_local_space(collision_shape.shape):
		var global_point: Vector2 = collision_shape.global_transform * corner
		var local_weapon: Vector2 = weapon.to_local(global_point)
		best = maxf(best, local_weapon.length())
	return best

static func _shape_corners_in_shape_local_space(shape: Shape2D) -> PackedVector2Array:
	if shape is RectangleShape2D:
		var rect: RectangleShape2D = shape as RectangleShape2D
		var half: Vector2 = rect.size * 0.5
		return PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(-half.x, half.y),
			Vector2(half.x, half.y),
		])
	if shape is CircleShape2D:
		var circle: CircleShape2D = shape as CircleShape2D
		var r: float = circle.radius
		return PackedVector2Array([
			Vector2(-r, 0.0), Vector2(r, 0.0),
			Vector2(0.0, -r), Vector2(0.0, r),
		])
	if shape is CapsuleShape2D:
		var cap: CapsuleShape2D = shape as CapsuleShape2D
		var r: float = cap.radius
		var half_h: float = maxf(0.0, cap.height * 0.5 - r)
		return PackedVector2Array([
			Vector2(-r, -half_h), Vector2(r, -half_h),
			Vector2(-r, half_h), Vector2(r, half_h),
			Vector2(0.0, -half_h - r), Vector2(0.0, half_h + r),
		])
	return PackedVector2Array()
