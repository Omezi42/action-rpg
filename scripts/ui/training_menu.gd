extends Control
## 修行の画面(GameDesign.md 2・6・8章)。上下で選び居合で買う。R で全部戻し、Esc で閉じる。

signal closed

const MSEC_PER_SEC := 1000.0
const HELP := "上下で選ぶ / 居合・クリックで買う / R で全部戻す / Esc で戻る"
const TOUCH_HELP := "項目をタップで買う"

@export var input_lock_time := 0.3
@export var back_color := Color(0.05, 0.06, 0.1, 0.92)
@export var row_color := Color("24243a")
@export var border_color := Color("8888a0")
@export var selected_color := Color("ffd84a")
@export var dim_text := Color(1, 1, 1, 0.6)
@export var title_top := 16.0
@export var merit_top := 40.0
@export var rows_top := 64.0
@export var row_size := Vector2(360, 36)
@export var row_gap := 6.0
@export var help_top := 238.0
@export var title_size := 16
@export var text_size := 10
@export var border_width := 1.0
@export var selected_width := 2.0
@export var padding := 6.0

var catalog: TrainingCatalog
var progress: TrainingProgress

var _selected := 0
var _opened_at := 0
var _last_mouse := Vector2.ZERO
var _merit_label: Label
var _rows: Array[Label] = []


func open(training: TrainingCatalog, saved: TrainingProgress) -> void:
	catalog = training
	progress = saved
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var screen := get_viewport_rect().size
	_add_label("修行", Vector2(0, title_top), Vector2(screen.x, title_size * 2.0), title_size)
	_merit_label = _add_label(
		"", Vector2(0, merit_top), Vector2(screen.x, text_size * 2.0), text_size
	)
	for i in catalog.items.size():
		var row := _add_label("", _row_rect(i).position, row_size, text_size)
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.position.x += padding
		row.size.x -= padding * 2.0
		_rows.append(row)
	add_to_group(TouchControls.GROUP)
	var help := _add_label(
		TOUCH_HELP if TouchControls.active() else HELP,
		Vector2(0, help_top),
		Vector2(screen.x, text_size * 2.0),
		text_size
	)
	help.add_theme_color_override("font_color", dim_text)
	_opened_at = Time.get_ticks_msec()
	_last_mouse = get_global_mouse_position()
	_refresh()


func touch_context() -> Dictionary:
	return TouchControls.context(false, [["全部戻す", &"reroll"], ["戻る", &"pause"]])


func touch_tap(at: Vector2) -> void:
	var row := _row_at(at)
	if row < 0 or Time.get_ticks_msec() - _opened_at < input_lock_time * MSEC_PER_SEC:
		return
	_select(row)
	buy(row)


func buy(index: int) -> void:
	if progress.buy(catalog.items[index]):
		Sfx.play(&"purchase")
	_refresh()


func refund() -> void:
	progress.refund_all(catalog)
	Sfx.play(&"confirm")
	_refresh()


func _process(_delta: float) -> void:
	if not progress:
		return
	var mouse := get_global_mouse_position()
	var hovered := _row_at(mouse)
	if mouse != _last_mouse and hovered >= 0:
		_select(hovered)
	_last_mouse = mouse
	if Input.is_action_just_pressed("move_up"):
		_select(_selected - 1)
	if Input.is_action_just_pressed("move_down"):
		_select(_selected + 1)
	if Time.get_ticks_msec() - _opened_at < input_lock_time * MSEC_PER_SEC:
		return
	if Input.is_action_just_pressed("iai"):
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or hovered >= 0:
			buy(_selected)
	elif Input.is_action_just_pressed("reroll"):
		refund()
	elif Input.is_action_just_pressed("pause"):
		Sfx.play(&"confirm")
		closed.emit()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), back_color)
	if not catalog:
		return
	for i in catalog.items.size():
		var rect := _row_rect(i)
		draw_rect(rect, row_color)
		if i == _selected:
			draw_rect(rect, selected_color, false, selected_width)
		else:
			draw_rect(rect, border_color, false, border_width)


func _refresh() -> void:
	_merit_label.text = "武功 %d" % progress.merit
	for i in catalog.items.size():
		var item := catalog.items[i]
		var cost := progress.next_cost(item)
		var price := "最大" if cost < 0 else "%d 武功" % cost
		_rows[i].text = (
			"%s  %d/%d   %s\n次:%s"
			% [item.label, progress.level_of(item), item.max_level(), item.description, price]
		)
	queue_redraw()


func _select(index: int) -> void:
	var clamped := clampi(index, 0, catalog.items.size() - 1)
	if clamped != _selected:
		Sfx.play(&"cursor")
	_selected = clamped
	queue_redraw()


func _row_rect(index: int) -> Rect2:
	var left := (get_viewport_rect().size.x - row_size.x) / 2.0
	return Rect2(Vector2(left, rows_top + index * (row_size.y + row_gap)), row_size)


func _row_at(point: Vector2) -> int:
	for i in catalog.items.size():
		if _row_rect(i).has_point(point):
			return i
	return -1


func _add_label(text: String, at: Vector2, label_size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.position = at
	label.size = label_size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label
