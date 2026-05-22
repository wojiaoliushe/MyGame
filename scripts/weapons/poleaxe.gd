extends SlashWeapon
class_name Poleaxe

@export var swing_arc_deg: float = 240.0
@export var swing_duration: float = 0.4
## 相对贴图矩形多扩一圈碰撞，减少漏判
@export var hitbox_padding_px: float = 14.0
## 作为持有者子节点时，自动索敌攻击的间隔（秒）
@export var check_interval: float = 2.0
@export var auto_attack_enabled: bool = true
## 斧刃贴图相对挥击枢轴的水平偏移（与剑 blade_extend_x 含义一致）
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
