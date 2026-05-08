extends Area2D
class_name FireBallProjectile

@export var speed: float = 400.0
var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 2秒后自动销毁，防止火球弹体无限飞行
	get_tree().create_timer(2.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body is Player:
		return

	if body.is_in_group("enemies"):
		if body.has_method("die"):
			body.die()
		else:
			body.queue_free()

	# 击中敌人或墙壁等任意物体后销毁
	queue_free()
