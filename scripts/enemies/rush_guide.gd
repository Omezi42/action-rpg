extends Node2D
## 突進の予告線(GameDesign.md 5章)。予告の間、足元から突進の向きへ突進の距離ぶん赤く描く。

@export var color := Color(0.9, 0.15, 0.1, 0.55)
@export var width := 10.0

@onready var _enemy: Enemy = get_parent()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _enemy.state != Enemy.State.WINDUP:
		return
	var ratio := _enemy.windup_ratio()
	var tip := _enemy.aim_direction * _enemy.data.rush_distance
	draw_line(Vector2.ZERO, tip, Color(color, color.a * 0.4), width)
	draw_line(Vector2.ZERO, tip * ratio, color, width)
