extends Control
## 上端のレベルと経験値のバー(GameDesign.md 6・8章)。Control の幅いっぱいに描く。

@export var label_width := 26.0
@export var bar_height := 4.0
@export var font_size := 10
@export var fill_color := Color("7fe0ff")
@export var empty_color := Color(0, 0, 0, 0.45)
@export var outline_color := Color("1b1b1b")
@export var text_color := Color.WHITE

var _level := 1
var _ratio := 0.0


func show_growth(level: int, xp: int, xp_to_next: int) -> void:
	_level = level
	_ratio = clampf(float(xp) / xp_to_next, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	var baseline := (size.y + font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	var text_pos := Vector2(0, baseline)
	draw_string_outline(
		font, text_pos, "Lv%d" % _level, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 2, outline_color
	)
	draw_string(
		font, text_pos, "Lv%d" % _level, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color
	)
	var bar := Rect2(label_width, (size.y - bar_height) / 2.0, size.x - label_width, bar_height)
	draw_rect(bar, empty_color)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _ratio, bar.size.y)), fill_color)
	draw_rect(bar, outline_color, false, 1.0)
