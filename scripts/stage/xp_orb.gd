class_name XpOrb
extends Node2D
## 経験値の玉(GameDesign.md 8章)。主人公の回収範囲に入ったら吸い寄せ、足元に届いたら collected を出して消える。

signal collected(value: int)

const COLOR := Color("7fe0ff")
const OUTLINE := Color("1b4a5c")
const HALF_SIZE := 3.0
const LIFT := Vector2(0, -3)

var value := 0
var magnet_speed := 0.0
var collect_distance := 0.0

var _attracted := false


func setup(xp: int, growth: GrowthData) -> void:
	value = xp
	magnet_speed = growth.magnet_speed
	collect_distance = growth.collect_distance


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	var distance := global_position.distance_to(player.global_position)
	_attracted = _attracted or distance <= player.pickup_radius()
	if not _attracted:
		return
	global_position = global_position.move_toward(player.global_position, magnet_speed * delta)
	if global_position.distance_to(player.global_position) <= collect_distance:
		collected.emit(value)
		queue_free()


func _draw() -> void:
	var diamond := PackedVector2Array(
		[
			LIFT + Vector2(0, -HALF_SIZE),
			LIFT + Vector2(HALF_SIZE, 0),
			LIFT + Vector2(0, HALF_SIZE),
			LIFT + Vector2(-HALF_SIZE, 0),
		]
	)
	draw_colored_polygon(diamond, COLOR)
	draw_polyline(diamond + PackedVector2Array([diamond[0]]), OUTLINE, 1.0)
