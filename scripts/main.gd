extends Node2D

@export var level_data: LevelData

@onready var _player: Player = $Player
@onready var _level_runtime: LevelRuntime = $LevelRuntime
@onready var _health_label: Label = $CanvasLayer/HealthLabel
@onready var _backpack_panel: BackpackPanel = $BackpackPanel

var _spawn_controller: SpawnController


func _ready() -> void:
	if level_data == null:
		push_error("Main: level_data is not assigned")
		return
	if not level_data.validate():
		return
	_level_runtime.setup(self, level_data, _player)
	_setup_spawn_controller()
	_player.health_changed.connect(_on_player_health_changed)


func _setup_spawn_controller() -> void:
	var controller: Node = level_data.spawn_controller.new() as Node
	_spawn_controller = controller as SpawnController
	if _spawn_controller == null:
		push_error("Main: spawn_controller script must extend SpawnController")
		if controller != null:
			controller.queue_free()
		return
	add_child(_spawn_controller)
	_spawn_controller.configure(level_data, self)


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


func trigger_game_over() -> void:
	if _spawn_controller != null:
		_spawn_controller.stop()
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
