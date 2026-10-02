class_name SweepAttack
extends Hitbox
## 青鬼の薙ぎ払い(GameDesign.md 5章)。正面(+X)の半円の当たり。予告と振りの見た目も描く。
## 向きは Enemy が aim() で合わせる。

const SEGMENTS := 16
const WARN_COLOR := Color(0.9, 0.15, 0.1, 0.45)
const SWING_COLOR := Color(1, 0.95, 0.85, 0.8)
const WARN_BACK_ALPHA := 0.35

var _points := PackedVector2Array()
var _shape: CollisionPolygon2D

@onready var _enemy: Enemy = get_parent()


func setup(radius: float, damage: int) -> void:
	power = damage
	hit_once_per_activation = true
	collision_layer = Arrow.ENEMY_ATTACK_LAYER
	collision_mask = 0
	monitoring = false
	show_behind_parent = true
	_points.append(Vector2.ZERO)
	for i in SEGMENTS + 1:
		_points.append(Vector2.RIGHT.rotated(-PI / 2 + PI * i / SEGMENTS) * radius)
	_shape = CollisionPolygon2D.new()
	_shape.polygon = _points
	add_child(_shape)
	aim(Vector2.RIGHT)
	deactivate()


## 半円は足元に描き、当たりは体の高さへ画面上で真上にずらす(回転しても向きを変えない)
func aim(dir: Vector2) -> void:
	rotation = dir.angle()
	_shape.position = GROUND_TO_BODY.rotated(-rotation)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	match _enemy.state:
		Enemy.State.WINDUP:
			draw_colored_polygon(_points, Color(WARN_COLOR, WARN_COLOR.a * WARN_BACK_ALPHA))
			var ratio := _enemy.windup_ratio()
			var inner := PackedVector2Array()
			for p in _points:
				inner.append(p * ratio)
			if ratio > 0.0:
				draw_colored_polygon(inner, WARN_COLOR)
		Enemy.State.SWEEP:
			draw_colored_polygon(_points, SWING_COLOR)
