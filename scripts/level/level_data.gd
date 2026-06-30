class_name LevelData
extends Resource

@export var id: String = ""
@export var display_name: String = ""

@export var background: Texture2D
@export var map_size: Vector2
@export var play_rect: Rect2
@export var play_margin: float
@export var spawn_clearance: float

@export var spawn_controller: Script


func validate() -> bool:
	if id.is_empty():
		push_error("LevelData: id is required")
		return false
	if background == null:
		push_error("LevelData '%s': background is required" % id)
		return false
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		push_error("LevelData '%s': map_size must be set in level resource" % id)
		return false
	if play_rect.size.x <= 0.0 or play_rect.size.y <= 0.0:
		push_error("LevelData '%s': play_rect must be set in level resource" % id)
		return false
	if spawn_controller == null:
		push_error("LevelData '%s': spawn_controller script is required" % id)
		return false
	return true


func play_inner_rect() -> Rect2:
	return play_rect.grow(-play_margin)


func spawn_bounds() -> Rect2:
	return play_inner_rect().grow(-spawn_clearance)


func play_center() -> Vector2:
	return play_inner_rect().get_center()
