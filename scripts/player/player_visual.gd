extends Node2D
## 絵が届くまでの主人公の仮の姿(GameDesign.md 7章)。足元が原点。

const BLINK_RATE := 20.0
const CHARGE_SQUAT := 2.0

@export var kimono_color := Color("2b3a67")
@export var skin_color := Color("f2d0a4")
@export var hair_color := Color("1b1b1b")
@export var blade_color := Color("e8f4ff")
@export var glow_color := Color("ffd84a")
@export var hurt_color := Color(1, 0.3, 0.3, 0.5)
@export var shadow_color := Color(0, 0, 0, 0.3)

@onready var _player: Player = get_parent()


func _process(_delta: float) -> void:
	var blinking := _player.invincible_left > 0.0 and _player.state != Player.State.DEAD
	visible = not blinking or int(_player.invincible_left * BLINK_RATE) % 2 == 0
	queue_redraw()


func _draw() -> void:
	var state := _player.state
	_draw_ellipse(Vector2.ZERO, Vector2(7, 2.5), shadow_color)
	if state == Player.State.DEAD:
		draw_rect(Rect2(-9, -8, 18, 8), kimono_color)
		draw_circle(Vector2(8, -5), 5, skin_color)
		return
	var squat := CHARGE_SQUAT if state == Player.State.CHARGE else 0.0
	var side := _side()
	draw_rect(Rect2(-6, -13 + squat, 12, 13 - squat), kimono_color)
	var head := Vector2(0, -19 + squat)
	draw_circle(head, 7, skin_color)
	draw_rect(Rect2(head.x - 7, head.y - 7, 14, 4), hair_color)
	_draw_eyes(head, side)
	var hilt := Vector2(5 if side >= 0 else -5, -8 + squat)
	if state == Player.State.DASH:
		var root := Vector2(0, -9)
		draw_line(root, root + _player.facing * 18, blade_color, 2)
	else:
		draw_line(hilt, hilt + Vector2(3 if side >= 0 else -3, -3), hair_color, 2)
	if state == Player.State.CHARGE and _player.charge.is_issen_window():
		draw_circle(hilt, 5, Color(glow_color, 0.8))
	if state == Player.State.HURT:
		draw_rect(Rect2(-7, -26, 14, 26), hurt_color)
	if _player.flash_left > 0.0:
		var alpha := _player.flash_left / Player.STAGE_FLASH_TIME
		draw_circle(Vector2(0, -12), 12, Color(1, 1, 1, alpha))


## 横向きなら ±1、縦向きなら 0(斜めは横向きの絵で表す)
func _side() -> int:
	if absf(_player.facing.x) > 0.1:
		return 1 if _player.facing.x > 0 else -1
	return 0


func _draw_eyes(head: Vector2, side: int) -> void:
	if side != 0:
		draw_rect(Rect2(head.x + 3 * side - 1, head.y, 2, 2), hair_color)
	elif _player.facing.y > 0:
		draw_rect(Rect2(head.x - 3, head.y, 2, 2), hair_color)
		draw_rect(Rect2(head.x + 1, head.y, 2, 2), hair_color)


func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	draw_set_transform(center, 0, Vector2(1, radius.y / radius.x))
	draw_circle(Vector2.ZERO, radius.x, color)
	draw_set_transform(Vector2.ZERO)
