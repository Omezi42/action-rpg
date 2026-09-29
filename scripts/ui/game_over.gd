extends CanvasLayer
## ゲームオーバー表示。居合ボタンで試作場を最初からやり直す(GameDesign.md 4章)。


func _ready() -> void:
	visible = false


func open() -> void:
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("iai"):
		get_tree().reload_current_scene()
