extends ThrustWeapon
class_name Spear

@export var thrust_duration: float = 0.18
@export var thrust_recover_duration: float = 0.1
@export var blade_retract_x: float = 8.0
@export var blade_extend_x: float = 120.0
@export var thrust_extra_reach: float = 12.0
@export var check_interval: float = 1.2
@export var auto_attack_enabled: bool = true

func _get_thrust_duration() -> float:
	return thrust_duration

func _get_thrust_recover_duration() -> float:
	return thrust_recover_duration

func _get_blade_retract_x() -> float:
	return blade_retract_x

func _get_blade_extend_x() -> float:
	return blade_extend_x

func _get_thrust_extra_reach() -> float:
	return thrust_extra_reach

func _get_check_interval() -> float:
	return check_interval

func _get_auto_attack_enabled() -> bool:
	return auto_attack_enabled
