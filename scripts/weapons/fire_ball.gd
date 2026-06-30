extends RangeWeapon
class_name FireBall

@export var fire_ball_projectile_scene: PackedScene = preload("res://scenes/projectiles/fire_ball_projectile.tscn")
## 自动发射间隔（秒）
@export var shoot_interval: float = 1.0
## 只瞄准该距离内的敌人
@export var max_range: float = 400.0
@export var auto_shoot_enabled: bool = true

func _apply_weapon_stats() -> void:
	damage = 5

func _get_projectile_scene() -> PackedScene:
	return fire_ball_projectile_scene

func _get_shoot_interval() -> float:
	return shoot_interval

func _get_max_range() -> float:
	return max_range

func _get_auto_shoot_enabled() -> bool:
	return auto_shoot_enabled
