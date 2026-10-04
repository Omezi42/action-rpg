extends CanvasLayer
## ポーズ(GameDesign.md 2章)と音量の設定(10章)。ポーズ中も入力を受けるため process_mode は ALWAYS。
## 結果表示中は locked にして切り替えさせない。

const ROWS := ["BGM", "効果音"]
const HINT := "上下で選ぶ / 左右で音量 / Escで戻る"

@export var rows_top := 156.0
@export var row_height := 16.0
@export var font_size := 10
@export var selected_color := Color.WHITE
@export var dim_color := Color(1, 1, 1, 0.6)

var locked := false
var settings: AudioSettings
var _selected := 0
var _labels: Array[Label] = []


func _ready() -> void:
	visible = false
	add_to_group(TouchControls.GROUP)
	settings = AudioSettings.load_saved()
	for i in ROWS.size():
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", font_size)
		label.position = Vector2(0, rows_top + i * row_height)
		label.size = Vector2(get_viewport().get_visible_rect().size.x, row_height)
		add_child(label)
		_labels.append(label)
	var hint := Label.new()
	hint.text = HINT
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", font_size - 2)
	hint.add_theme_color_override("font_color", dim_color)
	hint.position = Vector2(0, rows_top + ROWS.size() * row_height)
	hint.size = Vector2(get_viewport().get_visible_rect().size.x, row_height)
	add_child(hint)
	_refresh()


func touch_context() -> Dictionary:
	if locked:
		return TouchControls.context(false)
	return TouchControls.context(true, [["再開" if visible else "ポーズ", &"pause"]])


func _unhandled_input(event: InputEvent) -> void:
	if locked:
		return
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		visible = get_tree().paused
	elif not visible:
		return
	elif event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
		var step := -1 if event.is_action_pressed("move_up") else 1
		var next := clampi(_selected + step, 0, ROWS.size() - 1)
		if next != _selected:
			_selected = next
			Sfx.play(&"cursor")
			_refresh()
	elif event.is_action_pressed("move_left"):
		change_level(_selected, -1)
	elif event.is_action_pressed("move_right"):
		change_level(_selected, 1)


func change_level(row: int, step: int) -> void:
	if row == 0:
		settings.bgm = clampi(settings.bgm + step, 0, AudioSettings.MAX_LEVEL)
	else:
		settings.se = clampi(settings.se + step, 0, AudioSettings.MAX_LEVEL)
	settings.apply()
	settings.save()
	Sfx.play(&"cursor")
	_refresh()


func _refresh() -> void:
	var levels := [settings.bgm, settings.se]
	for i in ROWS.size():
		var mark := "▶ " if i == _selected else "  "
		_labels[i].text = "%s%s  ◀ %d ▶" % [mark, ROWS[i], levels[i]]
		_labels[i].add_theme_color_override(
			"font_color", selected_color if i == _selected else dim_color
		)
