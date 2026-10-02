extends CanvasLayer
## レベルアップ画面(GameDesign.md 2・6・8章)。強化カードから1枚を選ぶ。
## ツリー停止中に動くので process_mode は ALWAYS。開いた直後の誤操作防止はツリー停止・ヒットストップに
## 左右されないよう実時間で測る。

signal chosen(upgrade: UpgradeData)
## 修行の引き直し・封じ(GameDesign.md 8章)。使えるかは受け手が判断して開き直す
signal reroll_requested
signal seal_requested(index: int)

const UpgradeCard = preload("res://scripts/ui/upgrade_card.gd")
const MSEC_PER_SEC := 1000.0
const NUMBER_KEYS := [KEY_1, KEY_2, KEY_3]

@export var growth: GrowthData
@export var dim_color := Color(0, 0, 0, 0.6)
@export var card_size := Vector2(128, 112)
@export var card_gap := 12.0
@export var card_top := 84.0
@export var title_top := 48.0
@export var title_size := 16
@export var footer_top := 216.0
@export var footer_size := 10

var _cards: Array = []
var _selected := 0
var _opened_at := 0
var _last_mouse := Vector2.ZERO
var _root: Control


func _ready() -> void:
	visible = false
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)


func open(
	choices: Array[UpgradeData],
	levels: Array[int],
	is_scroll := false,
	rerolls := 0,
	seals := 0,
	selected := 0
) -> void:
	for child in _root.get_children():
		child.free()
	_cards.clear()
	var screen := _root.get_viewport_rect().size
	var dim := ColorRect.new()
	dim.color = dim_color
	dim.size = screen
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)
	var title := Label.new()
	title.text = "巻物" if is_scroll else "レベルアップ!"
	title.add_theme_font_size_override("font_size", title_size)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(screen.x, title_size * 2.0)
	title.position = Vector2(0, title_top)
	_root.add_child(title)
	var total := choices.size() * card_size.x + (choices.size() - 1) * card_gap
	for i in choices.size():
		var card := UpgradeCard.new()
		card.size = card_size
		card.position = Vector2((screen.x - total) / 2.0 + i * (card_size.x + card_gap), card_top)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(card)
		card.setup(choices[i], levels[i], i + 1)
		_cards.append(card)
	_add_footer(screen, rerolls, seals)
	_select(selected)
	_opened_at = Time.get_ticks_msec()
	_last_mouse = _root.get_global_mouse_position()
	visible = true


func is_locked() -> bool:
	return Time.get_ticks_msec() - _opened_at < growth.choose_lock_time * MSEC_PER_SEC


func choose(index: int) -> void:
	if not visible or index < 0 or index >= _cards.size():
		return
	visible = false
	chosen.emit(_cards[index].upgrade)


func _process(_delta: float) -> void:
	if not visible:
		return
	var mouse := _root.get_global_mouse_position()
	var hovered := _card_at(mouse)
	if mouse != _last_mouse and hovered >= 0:
		_select(hovered)
	_last_mouse = mouse
	if Input.is_action_just_pressed("move_left"):
		_select(_selected - 1)
	if Input.is_action_just_pressed("move_right"):
		_select(_selected + 1)
	if is_locked():
		return
	if Input.is_action_just_pressed("reroll"):
		reroll_requested.emit()
		return
	if Input.is_action_just_pressed("seal"):
		seal_requested.emit(_selected)
		return
	if not Input.is_action_just_pressed("iai"):
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		choose(hovered)
	else:
		choose(_selected)


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not visible or not key or not key.pressed or key.echo:
		return
	var index := NUMBER_KEYS.find(key.physical_keycode)
	if index < 0:
		return
	get_viewport().set_input_as_handled()
	if not is_locked():
		choose(index)


func _add_footer(screen: Vector2, rerolls: int, seals: int) -> void:
	var parts: Array[String] = []
	if rerolls > 0:
		parts.append("R 引き直し 残り%d" % rerolls)
	if seals > 0:
		parts.append("F 封じ 残り%d" % seals)
	if parts.is_empty():
		return
	var footer := Label.new()
	footer.text = "   ".join(parts)
	footer.add_theme_font_size_override("font_size", footer_size)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.size = Vector2(screen.x, footer_size * 2.0)
	footer.position = Vector2(0, footer_top)
	_root.add_child(footer)


func _card_at(point: Vector2) -> int:
	for i in _cards.size():
		if _cards[i].get_global_rect().has_point(point):
			return i
	return -1


func _select(index: int) -> void:
	_selected = clampi(index, 0, _cards.size() - 1)
	for i in _cards.size():
		_cards[i].selected = i == _selected
