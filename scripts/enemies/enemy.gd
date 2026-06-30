extends CharacterBody2D
class_name Enemy

var max_hp: int = 0
var current_hp: int = 0
var speed: float = 0.0
var attack_power: int = 0


func _ready() -> void:
	_apply_stats()
	current_hp = max_hp


## 子类在此设置 max_hp、speed、attack_power
func _apply_stats() -> void:
	pass


func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	current_hp -= amount
	if current_hp <= 0:
		die()


func die() -> void:
	queue_free()
