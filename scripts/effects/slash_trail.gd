extends Node2D
## 居合の斬撃の軌跡(コード描画)。踏み込みの始点から終点へ一本の線を引いて消える。

const LIFE := 0.22
const WIDTH := 3.0
const ISSEN_WIDTH := 6.0
const COLOR := Color("e8f4ff")
const ISSEN_COLOR := Color("ffd84a")
const BODY_OFFSET := Vector2(0, -10)

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _is_issen := false
var _age := 0.0


func setup(from: Vector2, to: Vector2, is_issen: bool) -> void:
	_from = from + BODY_OFFSET
	_to = to + BODY_OFFSET
	_is_issen = is_issen


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var rest := 1.0 - _age / LIFE
	var color := ISSEN_COLOR if _is_issen else COLOR
	var width := ISSEN_WIDTH if _is_issen else WIDTH
	draw_line(_from, _to, Color(color, rest), maxf(width * rest, 1.0))
