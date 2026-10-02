class_name Shockwave
extends Hitbox
## 残心の衝撃波(GameDesign.md 8章)。止まった位置から半径まで広がり、範囲の敵に1度だけ当たる。

## Architecture.md 1章の player_attack(4番)
const PLAYER_ATTACK_LAYER := 1 << 3
const BODY_OFFSET := Vector2(0, -8)
const COLOR := Color(1.0, 0.95, 0.75, 0.8)
const WIDTH := 2.0

var _radius := 0.0
var _life := 0.0
var _age := 0.0
var _circle := CircleShape2D.new()


func setup(strike_power: int, radius: float, life: float) -> void:
	_radius = radius
	_life = life
	power = strike_power
	hit_once_per_activation = true
	collision_layer = PLAYER_ATTACK_LAYER
	collision_mask = 0
	monitoring = false
	_circle.radius = radius
	var shape := CollisionShape2D.new()
	shape.shape = _circle
	shape.position = BODY_OFFSET
	add_child(shape)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= _life:
		queue_free()
	queue_redraw()


func try_hit(hurtbox: Hurtbox) -> bool:
	direction = global_position.direction_to(hurtbox.global_position)
	return super.try_hit(hurtbox)


func _draw() -> void:
	var t := clampf(_age / _life, 0.0, 1.0)
	draw_arc(BODY_OFFSET, _radius * t, 0.0, TAU, 32, Color(COLOR, COLOR.a * (1.0 - t)), WIDTH)
