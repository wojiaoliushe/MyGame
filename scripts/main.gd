extends Node2D

var monster_scene: PackedScene = preload("res://scenes/enemies/monster.tscn")

const MAP_WIDTH: float = 2560.0
const MAP_HEIGHT: float = 1920.0
const WALL_MARGIN: float = 32.0
## 生成点与围墙内侧保持距离（与可走区域 clamp 一致，避免出生卡在墙里）
const SPAWN_CLEARANCE: float = 16.0

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
	var inner_left: float = WALL_MARGIN + SPAWN_CLEARANCE
	var inner_right: float = MAP_WIDTH - WALL_MARGIN - SPAWN_CLEARANCE
	var inner_top: float = WALL_MARGIN + SPAWN_CLEARANCE
	var inner_bottom: float = MAP_HEIGHT - WALL_MARGIN - SPAWN_CLEARANCE

	# 整张地图可走区域内边界上生成 (0: 上, 1: 下, 2: 左, 3: 右)
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
	# 居中显示
	label.anchors_preset = Control.PRESET_CENTER
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	label.visible = true
	get_tree().paused = true
