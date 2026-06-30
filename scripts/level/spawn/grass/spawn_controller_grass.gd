class_name SpawnControllerGrass
extends SpawnController

## 暂未接入难度选怪时使用；后续由难度逻辑替换 _pick_spawn_key()
@export var default_spawn_key: SpawnKey = SpawnKey.MONSTER

@export var initial_interval: float = 1.0
@export var ramp_every_sec: float = 10.0
@export var ramp_factor: float = 0.75
@export var min_interval: float = 0.05


func on_configure() -> void:
	if not has_spawn_key(default_spawn_key):
		push_error(
			"SpawnControllerGrass: default_spawn_key '%s' has no scene path"
			% SpawnKey.keys()[default_spawn_key]
		)
		return
	create_spawn_timer(initial_interval)
	create_ramp_timer(ramp_every_sec)


func on_spawn_tick() -> void:
	var bounds: Rect2 = get_spawn_bounds()
	var inner_left: float = bounds.position.x
	var inner_top: float = bounds.position.y
	var inner_right: float = bounds.end.x
	var inner_bottom: float = bounds.end.y

	var edge: int = randi() % 4
	var spawn_pos: Vector2
	match edge:
		0:
			spawn_pos = Vector2(randf_range(inner_left, inner_right), inner_top)
		1:
			spawn_pos = Vector2(randf_range(inner_left, inner_right), inner_bottom)
		2:
			spawn_pos = Vector2(inner_left, randf_range(inner_top, inner_bottom))
		3:
			spawn_pos = Vector2(inner_right, randf_range(inner_top, inner_bottom))

	spawn_enemy(_pick_spawn_key(), spawn_pos)


func on_ramp_tick() -> void:
	var spawn_timer: Timer = get_spawn_timer()
	if spawn_timer == null:
		return
	var new_interval: float = maxf(spawn_timer.wait_time * ramp_factor, min_interval)
	spawn_timer.wait_time = new_interval
	print("怪物生成间隔已更新: ", new_interval, " 秒")


func _pick_spawn_key() -> SpawnKey:
	return default_spawn_key
