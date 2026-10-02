class_name Arrow
extends Hitbox
## 弓鬼の矢(GameDesign.md 5章)。直進し、主人公に当たる・壁や岩に当たる・射程を進むと消える。

## Architecture.md 1章の enemy_attack(5番)と world(1番)
const ENEMY_ATTACK_LAYER := 1 << 4
const WORLD_LAYER := 1
const RADIUS := 2.0
const LENGTH := 8.0
const SHAFT_COLOR := Color("8a5a2b")
const TIP_COLOR := Color("e8e8e8")

var _speed := 0.0
var _range := 0.0
var _traveled := 0.0


func setup(dir: Vector2, speed: float, max_range: float, damage: int) -> void:
	direction = dir
	rotation = dir.angle()
	_speed = speed
	_range = max_range
	power = damage
	collision_layer = ENEMY_ATTACK_LAYER
	collision_mask = WORLD_LAYER
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	var shape := CollisionShape2D.new()
	shape.shape = circle
	add_child(shape)
	landed.connect(queue_free.unbind(1))
	body_entered.connect(queue_free.unbind(1))


func _physics_process(delta: float) -> void:
	var step := _speed * delta
	position += direction * step
	_traveled += step
	if _traveled >= _range:
		queue_free()


func _draw() -> void:
	draw_line(Vector2(-LENGTH, 0), Vector2.ZERO, SHAFT_COLOR, 1.0)
	draw_rect(Rect2(-1, -1, 2, 2), TIP_COLOR)
