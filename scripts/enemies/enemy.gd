extends CharacterBody2D
class_name Enemy

const HEALTH_BAR_HEIGHT: float = 6.0

var max_hp: int = 0
var current_hp: int = 0
var speed: float = 0.0
var attack_power: int = 0

## 血条宽度与头顶间距，由子类在 _apply_stats 中按需覆盖
var health_bar_width: float = 44.0
var health_bar_padding: float = 8.0

var _health_bar_fill: ColorRect = null


func _ready() -> void:
	_apply_stats()
	current_hp = max_hp
	_create_health_bar()


## 子类在此设置 max_hp、speed、attack_power
func _apply_stats() -> void:
	pass


func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	current_hp -= amount
	_update_health_bar()
	if current_hp <= 0:
		die()


func die() -> void:
	queue_free()


## 在怪物头顶创建红色血条（背景 + 红色填充）
func _create_health_bar() -> void:
	# 血条顶部位置：默认在原点上方留出间距，若有精灵则按其半高上移
	var top_y: float = -health_bar_padding
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite and sprite.texture:
		top_y = -sprite.texture.get_height() * 0.5 * sprite.scale.y - health_bar_padding

	var container := Node2D.new()
	container.name = "HealthBar"
	container.z_index = 100
	add_child(container)

	var background := ColorRect.new()
	background.color = Color(0, 0, 0, 0.6)
	background.size = Vector2(health_bar_width, HEALTH_BAR_HEIGHT)
	background.position = Vector2(-health_bar_width * 0.5, top_y - HEALTH_BAR_HEIGHT)
	container.add_child(background)

	_health_bar_fill = ColorRect.new()
	_health_bar_fill.color = Color(1, 0, 0)
	_health_bar_fill.size = Vector2(health_bar_width, HEALTH_BAR_HEIGHT)
	_health_bar_fill.position = Vector2(-health_bar_width * 0.5, top_y - HEALTH_BAR_HEIGHT)
	container.add_child(_health_bar_fill)

	_update_health_bar()


## 按当前 HP 与最大 HP 的比值刷新红色填充宽度
func _update_health_bar() -> void:
	if _health_bar_fill == null:
		return
	var ratio: float = 0.0
	if max_hp > 0:
		ratio = clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
	_health_bar_fill.size.x = health_bar_width * ratio
