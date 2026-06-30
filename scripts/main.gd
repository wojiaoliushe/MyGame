extends Node2D

var monster_scene: PackedScene = preload("res://scenes/enemies/monster.tscn")

const INITIAL_SPAWN_INTERVAL: float = 1.0
const SPAWN_INTERVAL_RAMP_EVERY_SEC: float = 10.0
const SPAWN_INTERVAL_RAMP_FACTOR: float = 0.75
const MIN_SPAWN_INTERVAL: float = 0.05

var _spawn_timer: Timer
var _spawn_ramp_timer: Timer

@onready var _player: Player = $Player
@onready var _health_label: Label = $CanvasLayer/HealthLabel
@onready var _backpack_panel: BackpackPanel = $BackpackPanel

func _ready() -> void:
	_setup_forest_collision()
	_player.health_changed.connect(_on_player_health_changed)
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = INITIAL_SPAWN_INTERVAL
	_spawn_timer.autostart = true
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)

	_spawn_ramp_timer = Timer.new()
	_spawn_ramp_timer.wait_time = SPAWN_INTERVAL_RAMP_EVERY_SEC
	_spawn_ramp_timer.autostart = true
	_spawn_ramp_timer.timeout.connect(_on_spawn_ramp_timer_timeout)
	add_child(_spawn_ramp_timer)


func _setup_forest_collision() -> void:
	var bounds := StaticBody2D.new()
	bounds.name = "ForestBounds"
	bounds.collision_layer = 1
	bounds.collision_mask = 0
	add_child(bounds)
	move_child(bounds, 0)

	var play_top: float = LevelConfig.PLAY_TOP
	var play_bottom: float = LevelConfig.PLAY_BOTTOM
	var play_left: float = LevelConfig.PLAY_LEFT
	var play_right: float = LevelConfig.PLAY_RIGHT
	var map_w: float = LevelConfig.MAP_WIDTH
	var map_h: float = LevelConfig.MAP_HEIGHT

	_add_rect_collision(bounds, Vector2(map_w * 0.5, play_top * 0.5), Vector2(map_w, play_top))
	_add_rect_collision(
		bounds,
		Vector2(map_w * 0.5, play_bottom + (map_h - play_bottom) * 0.5),
		Vector2(map_w, map_h - play_bottom)
	)
	_add_rect_collision(
		bounds,
		Vector2(play_left * 0.5, (play_top + play_bottom) * 0.5),
		Vector2(play_left, play_bottom - play_top)
	)
	_add_rect_collision(
		bounds,
		Vector2(play_right + (map_w - play_right) * 0.5, (play_top + play_bottom) * 0.5),
		Vector2(map_w - play_right, play_bottom - play_top)
	)


func _add_rect_collision(body: StaticBody2D, center: Vector2, size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.position = center
	collider.shape = shape
	body.add_child(collider)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.keycode != KEY_ESCAPE:
		return
	if _is_game_over_ui_visible():
		return
	if get_tree().paused:
		return
	_backpack_panel.open()
	get_viewport().set_input_as_handled()


func _is_game_over_ui_visible() -> bool:
	return $CanvasLayer/GameOverLabel.visible


func _on_player_health_changed(current: int) -> void:
	_health_label.text = str(current)


func _on_spawn_ramp_timer_timeout() -> void:
	var new_interval: float = maxf(_spawn_timer.wait_time * SPAWN_INTERVAL_RAMP_FACTOR, MIN_SPAWN_INTERVAL)
	_spawn_timer.wait_time = new_interval
	print("怪物生成间隔已更新: ", new_interval, " 秒")


func _on_spawn_timer_timeout() -> void:
	spawn_monster()


func spawn_monster() -> void:
	var monster: CharacterBody2D = monster_scene.instantiate()
	var inner_left: float = LevelConfig.play_inner_left() + LevelConfig.SPAWN_CLEARANCE
	var inner_right: float = LevelConfig.play_inner_right() - LevelConfig.SPAWN_CLEARANCE
	var inner_top: float = LevelConfig.play_inner_top() + LevelConfig.SPAWN_CLEARANCE
	var inner_bottom: float = LevelConfig.play_inner_bottom() - LevelConfig.SPAWN_CLEARANCE

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

	monster.global_position.x = clamp(spawn_pos.x, inner_left, inner_right)
	monster.global_position.y = clamp(spawn_pos.y, inner_top, inner_bottom)
	add_child(monster)


func trigger_game_over() -> void:
	_backpack_panel.visible = false
	var label: Label = $CanvasLayer/GameOverLabel
	label.text = "GAME OVER"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_CENTER
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	label.visible = true
	get_tree().paused = true
