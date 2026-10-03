extends CanvasLayer
## 結果表示(GameDesign.md 9章)。居合ボタンでもう一度、Escでタイトルへ。
## 表示中はツリーが止まるので process_mode は ALWAYS。開いた直後の読み飛ばし防止は実時間で測る。

const Title = preload("res://scripts/ui/title.gd")
const MSEC_PER_SEC := 1000.0
const NEW_MARK := " 新記録!"

@export_file("*.tscn") var title_scene := "res://scenes/ui/title.tscn"
@export var input_lock_time := 0.5

var _opened_at := 0

@onready var _label: Label = $Label


func _ready() -> void:
	visible = false


func open(
	cleared: bool,
	survived: float,
	kills: int,
	level: int,
	hitokiri := 0,
	updated: Array[String] = [],
	merit := 0
) -> void:
	_opened_at = Time.get_ticks_msec()
	Bgm.stop()
	Sfx.play(&"clear" if cleared else &"game_over")
	var title := "クリア!" if cleared else "ゲームオーバー"
	var lines := [
		title,
		"",
		"生存 %s%s" % [Title.format_time(survived), _mark(updated, "best_time")],
		"撃破 %d%s" % [kills, _mark(updated, "best_kills")],
		"到達 Lv %d%s" % [level, _mark(updated, "best_level")],
		"最多人斬り %d%s" % [hitokiri, _mark(updated, "best_hitokiri")],
		"武功 +%d" % merit,
		"",
		"居合ボタンでもう一度 / Escでタイトルへ",
	]
	_label.text = "\n".join(lines)
	visible = true


func _mark(updated: Array[String], key: String) -> String:
	return NEW_MARK if key in updated else ""


func _unhandled_input(event: InputEvent) -> void:
	if not visible or Time.get_ticks_msec() - _opened_at < input_lock_time * MSEC_PER_SEC:
		return
	if event.is_action_pressed("iai"):
		Sfx.play(&"confirm")
		get_tree().reload_current_scene()
	elif event.is_action_pressed("pause"):
		Sfx.play(&"confirm")
		get_tree().change_scene_to_file(title_scene)
