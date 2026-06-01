extends SlashWeapon
class_name Sword

@export var swing_arc_deg: float = 90.0
@export var swing_duration: float = 0.22
## 作为持剑者子节点时，自动索敌挥剑的间隔（秒）
@export var check_interval: float = 1.0
@export var auto_attack_enabled: bool = true

func _get_swing_arc_deg() -> float:
	return swing_arc_deg

func _get_swing_duration() -> float:
	return swing_duration

func _get_check_interval() -> float:
	return check_interval

func _get_auto_attack_enabled() -> bool:
	return auto_attack_enabled
