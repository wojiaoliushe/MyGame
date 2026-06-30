class_name LevelConfig

## 背景图 bg_level_grass.png 的像素尺寸
const MAP_WIDTH: float = 2732.0
const MAP_HEIGHT: float = 1534.0

## 中央草地矩形边界（按图片像素分析得出，相对地图左上角）
const PLAY_LEFT: float = 513.0
const PLAY_TOP: float = 323.0
const PLAY_RIGHT: float = 2163.0
const PLAY_BOTTOM: float = 1270.0

## 角色碰撞体半宽 + 缓冲，避免贴森林边缘穿模
const PLAY_MARGIN: float = 48.0
## 刷怪点与可活动区内侧保持距离
const SPAWN_CLEARANCE: float = 16.0


static func play_inner_left() -> float:
	return PLAY_LEFT + PLAY_MARGIN


static func play_inner_right() -> float:
	return PLAY_RIGHT - PLAY_MARGIN


static func play_inner_top() -> float:
	return PLAY_TOP + PLAY_MARGIN


static func play_inner_bottom() -> float:
	return PLAY_BOTTOM - PLAY_MARGIN


static func play_center() -> Vector2:
	return Vector2(
		(play_inner_left() + play_inner_right()) * 0.5,
		(play_inner_top() + play_inner_bottom()) * 0.5
	)
