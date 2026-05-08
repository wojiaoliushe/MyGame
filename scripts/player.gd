extends CharacterBody2D
class_name Player

signal health_changed(current: int)

@export var speed: float = 300.0
@export var max_health: int = 3
## 受伤后的无敌时间，避免与怪物重叠时每帧多次扣血
@export var invulnerability_duration: float = 0.75

var health: int = 0
var _iframes_remaining: float = 0.0

@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	health = max_health
	health_changed.emit(health)
	if has_node("Camera2D"):
		var camera: Camera2D = $Camera2D
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = 2560
		camera.limit_bottom = 1920

func _physics_process(delta: float) -> void:
	# 获取输入向量 (支持箭头键和 WASD)
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if direction == Vector2.ZERO:
		var x: float = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
		var y: float = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
		direction = Vector2(x, y).normalized()

	# 处理图片翻转
	if direction.x > 0:
		sprite_2d.flip_h = true
	elif direction.x < 0:
		sprite_2d.flip_h = false

	# 设置速度并移动
	velocity = direction * speed
	move_and_slide()

	if _iframes_remaining > 0.0:
		_iframes_remaining -= delta

func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	if _iframes_remaining > 0.0:
		return
	health -= amount
	health_changed.emit(health)
	if health <= 0:
		game_over()
	else:
		_iframes_remaining = invulnerability_duration

func game_over() -> void:
	var main = get_tree().current_scene
	if main.has_method("trigger_game_over"):
		main.trigger_game_over()
