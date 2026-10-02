class_name JumpAttack
extends Hitbox
## 赤鬼のジャンプ斬りの着地の一撃(GameDesign.md 5章)。着地点の円の当たり。予告と振りの見た目も描く。
## 敵と一緒に動かないよう top_level にし、Enemy が予告の始めに着地点へ置く。

const WARN_COLOR := Color(0.9, 0.15, 0.1, 0.45)
const SWING_COLOR := Color(1, 0.95, 0.85, 0.8)
const WARN_BACK_ALPHA := 0.35
## 円は足元に描くが、当たりは主人公の Hurtbox と同じ体の高さに置く
const BODY_OFFSET := Vector2(0, -10)

var _radius := 0.0

@onready var _enemy: Enemy = get_parent()


func setup(radius: float, damage: int) -> void:
	_radius = radius
	power = damage
	hit_once_per_activation = true
	top_level = true
	show_behind_parent = true
	collision_layer = Arrow.ENEMY_ATTACK_LAYER
	collision_mask = 0
	monitoring = false
	var circle := CircleShape2D.new()
	circle.radius = radius
	var shape := CollisionShape2D.new()
	shape.shape = circle
	shape.position = BODY_OFFSET
	add_child(shape)
	deactivate()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	match _enemy.state:
		Enemy.State.WINDUP, Enemy.State.JUMP:
			draw_circle(Vector2.ZERO, _radius, Color(WARN_COLOR, WARN_COLOR.a * WARN_BACK_ALPHA))
			draw_arc(Vector2.ZERO, _radius, 0, TAU, 32, WARN_COLOR, 1.0)
		Enemy.State.LAND:
			draw_circle(Vector2.ZERO, _radius, SWING_COLOR)
