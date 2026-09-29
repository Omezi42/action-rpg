extends Control
## 左上のハート表示(GameDesign.md 4・6章)。HP 2 でハート1個、1で半分。

const HP_PER_HEART := 2
const HEART_POINTS := 24

@export var heart_size := 12.0
@export var spacing := 2.0
@export var full_color := Color("e0303a")
@export var empty_color := Color(0, 0, 0, 0.45)
@export var outline_color := Color("1b1b1b")

var _hp := 0
var _max_hp := 0


func bind(health: Health) -> void:
	health.changed.connect(_on_health_changed)
	_on_health_changed(health.hp, health.max_hp)


func _on_health_changed(hp: int, max_hp: int) -> void:
	_hp = hp
	_max_hp = max_hp
	queue_redraw()


func _draw() -> void:
	var count := ceili(float(_max_hp) / HP_PER_HEART)
	for i in count:
		var center := Vector2(heart_size / 2.0 + i * (heart_size + spacing), heart_size / 2.0)
		var value := clampi(_hp - i * HP_PER_HEART, 0, HP_PER_HEART)
		var outline := _heart(center, 0.0, TAU)
		draw_colored_polygon(outline, empty_color)
		if value == HP_PER_HEART:
			draw_colored_polygon(outline, full_color)
		elif value > 0:
			draw_colored_polygon(_heart(center, PI, TAU), full_color)
		draw_polyline(outline + PackedVector2Array([outline[0]]), outline_color, 1.0)


## ハート曲線の t_from〜t_to 部分(t=0 が上の中央、t=PI が下の先端、PI〜TAU が左半分)
func _heart(center: Vector2, t_from: float, t_to: float) -> PackedVector2Array:
	var scale := heart_size / 34.0
	var points := PackedVector2Array()
	for i in HEART_POINTS + 1:
		var t := lerpf(t_from, t_to, float(i) / HEART_POINTS)
		var x := 16.0 * pow(sin(t), 3)
		var y := 13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t)
		points.append(center + Vector2(x, -y - 3.0) * scale)
	return points
