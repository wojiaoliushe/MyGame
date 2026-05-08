extends CharacterBody2D

@export var speed: float = 100.0
@export var attack_power: int = 1
var player: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	# 假设玩家在 Main 场景中叫 "Player"
	player = get_tree().current_scene.find_child("Player", true, false)

func _physics_process(_delta: float) -> void:
	if player:
		var direction: Vector2 = (player.global_position - global_position).normalized()
		velocity = direction * speed
		
		# 处理图片翻转
		if direction.x > 0:
			$Sprite2D.flip_h = true
		elif direction.x < 0:
			$Sprite2D.flip_h = false
			
		move_and_slide()
		
		# 检测是否碰到玩家
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider() == player:
				if player.has_method("take_damage"):
					player.take_damage(attack_power)

func die() -> void:
	queue_free()
