extends SlashWeapon
class_name Poleaxe

@export var swing_arc_deg: float = 240.0
@export var swing_duration: float = 0.4
## 作为持有者子节点时，自动索敌攻击的间隔（秒）
@export var check_interval: float = 2.0
@export var auto_attack_enabled: bool = true

func _apply_weapon_stats() -> void:
	damage = 10

func _get_swing_arc_deg() -> float:
	return swing_arc_deg

func _get_swing_duration() -> float:
	return swing_duration

func _get_check_interval() -> float:
	return check_interval

func _get_auto_attack_enabled() -> bool:
	return auto_attack_enabled
