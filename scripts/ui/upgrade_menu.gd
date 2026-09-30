extends Control
## 強化の3択(GameDesign.md 2・6・8章)。札をコード描画し、選ばれたら chosen を出す。
## 表示中はツリーが止まるので process_mode は ALWAYS。開いてから lock_time の間は入力を無視する。

signal chosen(upgrade: UpgradeData)

const CHOOSE_ACTIONS: Array[StringName] = [&"choose_1", &"choose_2", &"choose_3"]
const TEXT_BREAK := TextServer.BREAK_MANDATORY | TextServer.BREAK_GRAPHEME_BOUND

@export var card_size := Vector2(136, 132)
@export var card_gap := 12.0
@export var card_top := 76.0
@export var card_padding := 8.0
@export var heading_y := 56.0
@export var heading_font_size := 14
@export var title_font_size := 12
@export var body_font_size := 10
@export var dim_color := Color(0, 0, 0, 0.55)
@export var card_color := Color("2a2530")
@export var border_color := Color("6b6275")
@export var selected_border_color := Color("ffd84a")
@export var text_color := Color.WHITE
@export var sub_text_color := Color("c8c0d0")

var _choices: Array[UpgradeData] = []
var _levels: Array[int] = []
var _selected := 0
var _lock_left := 0.0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## levels[i] は choices[i] の今の段
func open(choices: Array[UpgradeData], levels: Array[int], lock_time: float) -> void:
	_choices = choices
	_levels = levels
	_selected = 0
	_lock_left = lock_time
	visible = true
	queue_redraw()


func choose(index: int) -> void:
	if not visible or index < 0 or index >= _choices.size():
		return
	visible = false
	chosen.emit(_choices[index])


func card_rect(index: int) -> Rect2:
	var total := _choices.size() * card_size.x + (_choices.size() - 1) * card_gap
	var left := (size.x - total) / 2.0
	return Rect2(Vector2(left + index * (card_size.x + card_gap), card_top), card_size)


func _process(delta: float) -> void:
	_lock_left = maxf(_lock_left - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _lock_left > 0.0:
		return
	if event is InputEventMouse:
		_handle_mouse(make_input_local(event))
		return
	for i in CHOOSE_ACTIONS.size():
		if event.is_action_pressed(CHOOSE_ACTIONS[i]):
			choose(i)
			return
	if event.is_action_pressed("move_left"):
		_select(_selected - 1)
	elif event.is_action_pressed("move_right"):
		_select(_selected + 1)
	elif event.is_action_pressed("iai"):
		choose(_selected)


## 居合に左クリックが入っているので、マウスは札の上のときだけ扱う
func _handle_mouse(event: InputEventMouse) -> void:
	var index := _card_at(event.position)
	if index < 0:
		return
	_select(index)
	var button := event as InputEventMouseButton
	if button and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		choose(index)


func _card_at(point: Vector2) -> int:
	for i in _choices.size():
		if card_rect(i).has_point(point):
			return i
	return -1


func _select(index: int) -> void:
	_selected = clampi(index, 0, _choices.size() - 1)
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var font := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, size), dim_color)
	draw_string(
		font,
		Vector2(0, heading_y),
		"レベルアップ!  強化を1つ選ぶ",
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		heading_font_size,
		text_color
	)
	for i in _choices.size():
		_draw_card(font, i)


func _draw_card(font: Font, index: int) -> void:
	var upgrade := _choices[index]
	var rect := card_rect(index)
	var border := selected_border_color if index == _selected else border_color
	draw_rect(rect, card_color)
	draw_rect(rect, border, false, 2.0 if index == _selected else 1.0)
	var inner_width := rect.size.x - card_padding * 2.0
	var x := rect.position.x + card_padding
	var y := rect.position.y + card_padding + font.get_ascent(title_font_size)
	draw_string(
		font,
		Vector2(x, y),
		upgrade.title,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		title_font_size,
		text_color
	)
	y += font.get_height(title_font_size)
	draw_multiline_string(
		font,
		Vector2(x, y),
		upgrade.description,
		HORIZONTAL_ALIGNMENT_LEFT,
		inner_width,
		body_font_size,
		-1,
		text_color,
		TEXT_BREAK
	)
	var footer_y := rect.end.y - card_padding - font.get_descent(body_font_size)
	draw_string(
		font,
		Vector2(x, footer_y),
		_level_text(upgrade, _levels[index]),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		body_font_size,
		sub_text_color
	)
	draw_string(
		font,
		Vector2(x, footer_y),
		str(index + 1),
		HORIZONTAL_ALIGNMENT_RIGHT,
		inner_width,
		body_font_size,
		sub_text_color
	)


func _level_text(upgrade: UpgradeData, level: int) -> String:
	if upgrade.max_level <= 0:
		return ""
	return "段 %d → %d / %d" % [level, level + 1, upgrade.max_level]
