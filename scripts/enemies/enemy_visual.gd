extends Node2D
## 絵が届くまでの敵の仮の姿(GameDesign.md 7章)。足元が原点。色は EnemyData.color。

@export var horn_color := Color("f0e6c8")
@export var eye_color := Color("1b1b1b")
@export var hurt_color := Color.WHITE
@export var doomed_tint := Color(0.45, 0.45, 0.45)
@export var shadow_color := Color(0, 0, 0, 0.3)
## 気づいた瞬間の頭上の「!」
@export var notice_color := Color("ffe14d")
@export var notice_mark := Rect2(-1, -27, 2, 5)
@export var notice_dot := Rect2(-1, -21, 2, 2)
## 弓鬼の構え:弓の向きに出す線
@export var aim_color := Color(1, 0.9, 0.6, 0.8)
@export var aim_length := 18.0
## 精鋭鬼の金の縁取り
@export var elite_color := Color("e0b040")
@export var elite_outline := 1.0
## 影縫いで止まっている間の足元の影
@export var bind_color := Color(0.1, 0.0, 0.2, 0.75)
@export var bind_radius := 11.0

@onready var _enemy: Enemy = get_parent()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var body_color := _enemy.data.color
	match _enemy.state:
		Enemy.State.HURT:
			if not _enemy.bound:
				body_color = hurt_color
		Enemy.State.DOOMED:
			body_color = body_color * doomed_tint
	if _enemy.flash_left > 0.0:
		body_color = hurt_color
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 7, shadow_color)
	if _enemy.bound:
		draw_circle(Vector2.ZERO, bind_radius, bind_color)
	draw_set_transform(Vector2(0, -_enemy.air_height()))
	var center := Vector2(0, -8)
	if _enemy.elite:
		draw_circle(center, 8 + elite_outline, elite_color)
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
	if _enemy.state == Enemy.State.AIM:
		draw_line(center, center + _enemy.aim_direction * aim_length, aim_color, 1.0)
	if _enemy.state == Enemy.State.NOTICE:
		draw_rect(notice_mark, notice_color)
		draw_rect(notice_dot, notice_color)
