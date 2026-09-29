extends CanvasLayer
## ポーズ(GameDesign.md 2章)。ポーズ中も入力を受けるため process_mode は ALWAYS。
## 結果表示中は locked にして切り替えさせない。

var locked := false


func _ready() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if locked or not event.is_action_pressed("pause"):
		return
	get_tree().paused = not get_tree().paused
	visible = get_tree().paused
