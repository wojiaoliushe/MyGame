extends MeleeWeapon
class_name Sword

@export var swing_arc_deg: float = 90.0
@export var swing_duration: float = 0.22
## 相对贴图矩形多扩一圈碰撞，减少漏判
@export var hitbox_padding_px: float = 14.0
## 作为持剑者子节点时，自动索敌挥剑的间隔（秒）
@export var check_interval: float = 1.0
@export var auto_attack_enabled: bool = true
## 剑身贴图相对挥剑枢轴的水平偏移（原 BLADE_EXTEND_X）
@export var blade_extend_x: float = 30.0

func _get_swing_arc_deg() -> float:
	return swing_arc_deg

func _get_swing_duration() -> float:
	return swing_duration

func _get_hitbox_padding_px() -> float:
	return hitbox_padding_px

func _get_check_interval() -> float:
	return check_interval

func _get_auto_attack_enabled() -> bool:
	return auto_attack_enabled

func _get_blade_extend_x() -> float:
	return blade_extend_x
