extends Node2D
## 「N人斬り」の文字(GameDesign.md 3章、コード描画)。上へ動きながら消える。

const LIFE := 0.8
const RISE := 8.0
const FONT_SIZE := 8
const OUTLINE_SIZE := 2
const WIDTH := 64.0
const COLOR := Color("ffffff")
const ISSEN_COLOR := Color("ffd24a")
const OUTLINE_COLOR := Color("1a1a1a")

var _text := ""
var _color := COLOR
var _age := 0.0


func setup(count: int, is_issen: bool) -> void:
	_text = "%d人斬り" % count
	_color = ISSEN_COLOR if is_issen else COLOR


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var t := _age / LIFE
	var at := Vector2(-WIDTH / 2.0, -RISE * t)
	var font := ThemeDB.fallback_font
	var align := HORIZONTAL_ALIGNMENT_CENTER
	var outline := Color(OUTLINE_COLOR, 1.0 - t)
	draw_string_outline(font, at, _text, align, WIDTH, FONT_SIZE, OUTLINE_SIZE, outline)
	draw_string(font, at, _text, align, WIDTH, FONT_SIZE, Color(_color, 1.0 - t))
