class_name LevelRuntime
extends Node

const BACKGROUND_Z_INDEX: int = -10


func setup(parent: Node2D, data: LevelData, player: Player) -> void:
	if data == null:
		push_error("LevelRuntime.setup: level_data is null")
		return
	if not data.validate():
		return
	_setup_background(parent, data)
	_setup_forest_collision(parent, data)
	player.global_position = data.play_center()
	player.configure_camera(data.map_size)


func _setup_background(parent: Node2D, data: LevelData) -> void:
	var bg := Sprite2D.new()
	bg.name = "Background"
	bg.texture = data.background
	bg.centered = false
	bg.z_index = BACKGROUND_Z_INDEX
	parent.add_child(bg)
	parent.move_child(bg, 0)


func _setup_forest_collision(parent: Node2D, data: LevelData) -> void:
	var bounds := StaticBody2D.new()
	bounds.name = "ForestBounds"
	bounds.collision_layer = 1
	bounds.collision_mask = 0
	parent.add_child(bounds)
	parent.move_child(bounds, 0)

	var play_top: float = data.play_rect.position.y
	var play_bottom: float = data.play_rect.position.y + data.play_rect.size.y
	var play_left: float = data.play_rect.position.x
	var play_right: float = data.play_rect.position.x + data.play_rect.size.x
	var map_w: float = data.map_size.x
	var map_h: float = data.map_size.y

	_add_rect_collision(bounds, Vector2(map_w * 0.5, play_top * 0.5), Vector2(map_w, play_top))
	_add_rect_collision(
		bounds,
		Vector2(map_w * 0.5, play_bottom + (map_h - play_bottom) * 0.5),
		Vector2(map_w, map_h - play_bottom)
	)
	_add_rect_collision(
		bounds,
		Vector2(play_left * 0.5, (play_top + play_bottom) * 0.5),
		Vector2(play_left, play_bottom - play_top)
	)
	_add_rect_collision(
		bounds,
		Vector2(play_right + (map_w - play_right) * 0.5, (play_top + play_bottom) * 0.5),
		Vector2(map_w - play_right, play_bottom - play_top)
	)


func _add_rect_collision(body: StaticBody2D, center: Vector2, size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.position = center
	collider.shape = shape
	body.add_child(collider)
