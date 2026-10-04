extends Control
## レベルアップ画面の強化カード1枚(GameDesign.md 6・8章)。枠はコード描画。

@export var panel_color := Color("24243a")
@export var border_color := Color("8888a0")
@export var selected_color := Color("ffd84a")
## 奥義のカードの枠(GameDesign.md 6章)
@export var ougi_color := Color("e0b040")
@export var border_width := 1.0
@export var selected_width := 2.0
@export var padding := 6.0
@export var title_size := 14
@export var body_size := 10

var upgrade: UpgradeData
var selected := false:
	set(value):
		selected = value
		queue_redraw()


func setup(data: UpgradeData, current_level: int, key_number: int) -> void:
	upgrade = data
	var level_text := ""
	if data.max_level > 1:
		level_text = (
			"新規" if current_level == 0 else "Lv %d → %d" % [current_level, current_level + 1]
		)
	_add_label("%d" % key_number, body_size, HORIZONTAL_ALIGNMENT_LEFT, 0.0)
	_add_label(data.label, title_size, HORIZONTAL_ALIGNMENT_CENTER, padding)
	_add_label(level_text, body_size, HORIZONTAL_ALIGNMENT_CENTER, padding + title_size * 1.6)
	_add_label(
		data.description,
		body_size,
		HORIZONTAL_ALIGNMENT_CENTER,
		padding + title_size * 3.0,
		TextServer.AUTOWRAP_WORD_SMART
	)


## 折り返しはサイズより先に決める。後から決めると、ラベルの幅が最長行の幅まで広がったまま残る
func _add_label(
	text: String,
	font_size: int,
	align: HorizontalAlignment,
	top: float,
	autowrap := TextServer.AUTOWRAP_OFF
) -> Label:
	var label := Label.new()
	label.autowrap_mode = autowrap
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.position = Vector2(padding, top)
	label.size = Vector2(size.x - padding * 2.0, size.y - top - padding)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, panel_color)
	if selected:
		draw_rect(rect, selected_color, false, selected_width)
	elif upgrade and upgrade.kind == UpgradeData.Kind.OUGI:
		draw_rect(rect, ougi_color, false, selected_width)
	else:
		draw_rect(rect, border_color, false, border_width)
