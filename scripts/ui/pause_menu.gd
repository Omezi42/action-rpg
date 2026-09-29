extends CanvasLayer
## ポーズ(GameDesign.md 2章)。ポーズ中も入力を受けるため process_mode は ALWAYS。


func _ready() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		visible = get_tree().paused
