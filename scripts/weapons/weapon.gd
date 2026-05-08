extends Node2D
class_name Weapon

## 武器通用基类；具体逻辑由近战、枪械等子类实现。

## 下一次自动攻击前的等待时长（秒）：在基础间隔上乘以 [0.9, 1.1] 随机倍率，错开多把同种武器的索敌节奏。
func sample_next_attack_interval(base_seconds: float) -> float:
	return base_seconds * randf_range(0.9, 1.1)
