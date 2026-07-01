extends Enemy

var player: Node2D = null


func _apply_stats() -> void:
	max_hp = 10
	speed = 100.0
	attack_power = 1
	health_bar_width = 44.0
	health_bar_padding = 8.0


func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	player = get_tree().current_scene.find_child("Player", true, false)


func _physics_process(_delta: float) -> void:
	if player:
		var direction: Vector2 = (player.global_position - global_position).normalized()
		velocity = direction * speed

		if direction.x > 0:
			$Sprite2D.flip_h = true
		elif direction.x < 0:
			$Sprite2D.flip_h = false

		move_and_slide()

		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider() == player:
				if player.has_method("take_damage"):
					player.take_damage(attack_power)
