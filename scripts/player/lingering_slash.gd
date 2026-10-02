class_name LingeringSlash
extends Hitbox
## 斬痕(GameDesign.md 8章)。斬り抜けた線に残り、触れた敵に1度だけ当たる。

## Architecture.md 1章の player_attack(4番)
const PLAYER_ATTACK_LAYER := 1 << 3
## 敵の Hurtbox は足元より上にあるので、線を体の高さへずらす
const BODY_OFFSET := Vector2(0, -10)
const COLOR := Color(0.9, 0.96, 1.0, 0.6)
const WIDTH := 2.0

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _life := 0.0
var _age := 0.0


func setup(from: Vector2, to: Vector2, strike_power: int, life: float) -> void:
	_from = from + BODY_OFFSET
	_to = to + BODY_OFFSET
	_life = life
	power = strike_power
	direction = from.direction_to(to)
	hit_once_per_activation = true
	collision_layer = PLAYER_ATTACK_LAYER
	collision_mask = 0
	monitoring = false
	var segment := SegmentShape2D.new()
	segment.a = _from
	segment.b = _to
	var shape := CollisionShape2D.new()
	shape.shape = segment
	add_child(shape)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= _life:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var rest := clampf(1.0 - _age / _life, 0.0, 1.0)
	draw_line(_from, _to, Color(COLOR, COLOR.a * rest), WIDTH)
