extends CanvasLayer
## 結果表示(ゲームオーバー / クリア・生存時間・撃破数・到達レベル)。居合ボタンで最初からやり直す(GameDesign.md 4章)。
## 表示中はツリーが止まるので process_mode は ALWAYS。

@onready var _label: Label = $Label


func _ready() -> void:
	visible = false


func open(cleared: bool, survived: float, kills: int, level: int) -> void:
	var title := "クリア!" if cleared else "ゲームオーバー"
	_label.text = ("%s\n生存 %.1f秒  撃破 %d  Lv %d\n居合ボタンでやり直す" % [title, survived, kills, level])
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("iai"):
		get_tree().reload_current_scene()
