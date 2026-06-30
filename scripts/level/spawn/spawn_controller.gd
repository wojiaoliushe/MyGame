class_name SpawnController
extends Node

enum SpawnKey {
	MONSTER,
}

const ENEMY_SCENE_PATHS: Dictionary = {
	SpawnKey.MONSTER: "res://scenes/enemies/monster.tscn",
}

var level_data: LevelData
var _spawn_parent: Node
var _spawn_timer: Timer
var _ramp_timer: Timer
var _active: bool = false
var _enemy_scene_cache: Dictionary = {}


func configure(data: LevelData, spawn_parent: Node) -> void:
	level_data = data
	_spawn_parent = spawn_parent
	on_configure()
	start()


func start() -> void:
	_active = true
	if is_instance_valid(_spawn_timer):
		_spawn_timer.start()
	if is_instance_valid(_ramp_timer):
		_ramp_timer.start()


func stop() -> void:
	_active = false
	if is_instance_valid(_spawn_timer):
		_spawn_timer.stop()
	if is_instance_valid(_ramp_timer):
		_ramp_timer.stop()


## 子类初始化：创建 Timer 等
func on_configure() -> void:
	pass


## 主刷怪 Timer 每次触发时调用
func on_spawn_tick() -> void:
	pass


## 加速 Timer 每次触发时调用（可选）
func on_ramp_tick() -> void:
	pass


func has_spawn_key(key: SpawnKey) -> bool:
	return ENEMY_SCENE_PATHS.has(key)


func create_spawn_timer(interval: float) -> Timer:
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = interval
	_spawn_timer.one_shot = false
	_spawn_timer.autostart = false
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)
	return _spawn_timer


func create_ramp_timer(interval: float) -> Timer:
	_ramp_timer = Timer.new()
	_ramp_timer.wait_time = interval
	_ramp_timer.one_shot = false
	_ramp_timer.autostart = false
	_ramp_timer.timeout.connect(_on_ramp_timer_timeout)
	add_child(_ramp_timer)
	return _ramp_timer


func get_spawn_timer() -> Timer:
	return _spawn_timer


func get_spawn_bounds() -> Rect2:
	return level_data.spawn_bounds()


func spawn_enemy(key: SpawnKey, position: Vector2) -> void:
	if not _active:
		return
	var enemy_scene: PackedScene = _resolve_enemy_scene(key)
	if enemy_scene == null:
		return
	var bounds: Rect2 = get_spawn_bounds()
	var monster: CharacterBody2D = enemy_scene.instantiate() as CharacterBody2D
	monster.global_position.x = clamp(position.x, bounds.position.x, bounds.end.x)
	monster.global_position.y = clamp(position.y, bounds.position.y, bounds.end.y)
	_spawn_parent.add_child(monster)


func _resolve_enemy_scene(key: SpawnKey) -> PackedScene:
	if _enemy_scene_cache.has(key):
		return _enemy_scene_cache[key] as PackedScene
	if not ENEMY_SCENE_PATHS.has(key):
		push_error("SpawnController: no scene path for spawn key '%s'" % _spawn_key_name(key))
		return null
	var path: String = ENEMY_SCENE_PATHS[key]
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		push_error("SpawnController: failed to load '%s' for spawn key '%s'" % [path, _spawn_key_name(key)])
		return null
	_enemy_scene_cache[key] = scene
	return scene


func _spawn_key_name(key: SpawnKey) -> String:
	var names: Array = SpawnKey.keys()
	if key < 0 or key >= names.size():
		return str(key)
	return names[key]


func _on_spawn_timer_timeout() -> void:
	if not _active:
		return
	on_spawn_tick()


func _on_ramp_timer_timeout() -> void:
	if not _active:
		return
	on_ramp_tick()
