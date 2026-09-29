extends Node2D
## 絵が届くまでの敵の仮の姿(GameDesign.md 7章)。足元が原点。色は EnemyData.color。

@export var horn_color := Color("f0e6c8")
@export var eye_color := Color("1b1b1b")
@export var hurt_color := Color.WHITE
@export var doomed_tint := Color(0.45, 0.45, 0.45)
@export var shadow_color := Color(0, 0, 0, 0.3)

@onready var _enemy: Enemy = get_parent()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var body_color := _enemy.data.color
	match _enemy.state:
		Enemy.State.HURT:
			body_color = hurt_color
		Enemy.State.DOOMED:
			body_color = body_color * doomed_tint
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 7, shadow_color)
	draw_set_transform(Vector2.ZERO)
	var center := Vector2(0, -8)
	draw_circle(center, 8, body_color)
	for side in [-1, 1]:
		var base := center + Vector2(4 * side, -6)
		draw_colored_polygon(
			PackedVector2Array(
				[base + Vector2(-2, 1), base + Vector2(2, 1), base + Vector2(side, -4)]
			),
			horn_color
		)
		draw_rect(Rect2(center.x + 3 * side - 1, center.y - 1, 2, 2), eye_color)
