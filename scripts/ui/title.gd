extends Control
## タイトル画面(GameDesign.md 9章)。居合で挑戦を始め、Escで終える。最高記録を出す。

const TrainingMenu = preload("res://scripts/ui/training_menu.gd")
const MSEC_PER_SEC := 1000.0
const SECONDS_PER_MINUTE := 60

@export_file("*.tscn") var arena_scene := "res://scenes/stage/arena.tscn"
@export var training: TrainingCatalog = preload("res://data/training.tres")
@export var game_title := "居合サバイバー"
@export var input_lock_time := 0.3
@export var back_color := Color("1d2330")
@export var moon_color := Color("e8dcc0")
@export var moon_center := Vector2(360, 78)
@export var moon_radius := 40.0
@export var slash_color := Color("f4f1e8")
@export var slash_from := Vector2(70, 112)
@export var slash_to := Vector2(410, 96)
@export var title_size := 32
@export var title_top := 56.0
@export var prompt_top := 132.0
@export var prompt_blink_time := 0.5
@export var records_top := 168.0
@export var help_top := 244.0
@export var merit_top := 222.0
@export var credit_top := 256.0
@export var credit_text := "BGM: jobro (CC-BY 3.0) / TAD (CC-BY 4.0)"
@export var small_size := 10
@export var dim_text := Color(1, 1, 1, 0.7)

var _opened_at := 0
var _prompt: Label
var _merit: Label
var _training_menu: Control


func _ready() -> void:
	_opened_at = Time.get_ticks_msec()
	get_tree().paused = false
	Engine.time_scale = 1.0
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_add_label(game_title, title_top, title_size, Color.WHITE)
	_prompt = _add_label("居合ボタンで始める", prompt_top, small_size + 2, Color.WHITE)
	_add_label(_records_text(RunRecords.load_saved()), records_top, small_size, dim_text)
	_merit = _add_label("", merit_top, small_size, Color.WHITE)
	var help := "WASD 移動 / 左クリック・J・Space 長押しで溜め、離して居合 / Tab 修行"
	if can_quit():
		help += " / Esc 終了"
	_add_label(help, help_top, small_size, dim_text)
	_add_label(credit_text, credit_top, small_size - 2, dim_text)
	_show_merit()
	Bgm.play(&"title")


func _process(_delta: float) -> void:
	var blink := int(Time.get_ticks_msec() / (prompt_blink_time * MSEC_PER_SEC)) % 2
	_prompt.visible = blink == 0


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), back_color)
	draw_circle(moon_center, moon_radius, moon_color)
	draw_line(slash_from, slash_to, slash_color, 2.0)


func _unhandled_input(event: InputEvent) -> void:
	if _training_menu or Time.get_ticks_msec() - _opened_at < input_lock_time * MSEC_PER_SEC:
		return
	if event.is_action_pressed("training"):
		open_training()
	elif event.is_action_pressed("iai"):
		Sfx.play(&"confirm")
		get_tree().change_scene_to_file(arena_scene)
	elif event.is_action_pressed("pause") and can_quit():
		get_tree().quit()


## ブラウザのゲームは終了できず、quit() すると画面が固まる(GameDesign.md 9章)
static func can_quit() -> bool:
	return not OS.has_feature("web")


func open_training() -> void:
	Sfx.play(&"confirm")
	_training_menu = TrainingMenu.new()
	add_child(_training_menu)
	_training_menu.open(training, TrainingProgress.load_saved())
	_training_menu.closed.connect(_close_training)


func _close_training() -> void:
	_training_menu.queue_free()
	_training_menu = null
	_opened_at = Time.get_ticks_msec()
	_show_merit()


func _show_merit() -> void:
	_merit.text = "武功 %d" % TrainingProgress.load_saved().merit


func _add_label(text: String, top: float, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.position = Vector2(0, top)
	label.size = Vector2(get_viewport_rect().size.x, font_size * 2.0)
	add_child(label)
	return label


static func format_time(seconds: float) -> String:
	var whole := floori(seconds)
	return "%d:%02d" % [whole / SECONDS_PER_MINUTE, whole % SECONDS_PER_MINUTE]


func _records_text(records: RunRecords) -> String:
	if records.plays == 0:
		return "記録なし"
	return (
		"最長生存 %s   最多撃破 %d   最高Lv %d\n最多人斬り %d   クリア %d回 / 挑戦 %d回"
		% [
			format_time(records.best_time),
			records.best_kills,
			records.best_level,
			records.best_hitokiri,
			records.clears,
			records.plays
		]
	)
