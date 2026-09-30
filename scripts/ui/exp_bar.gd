extends Control
## 上端の経験値バー(GameDesign.md 6・8章)。次のレベルまでの溜まり具合。

@export var back_color := Color(0, 0, 0, 0.55)
@export var fill_color := Color("9fe8ff")

var _ratio := 0.0


func show_ratio(ratio: float) -> void:
	_ratio = clampf(ratio, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), back_color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * _ratio, size.y)), fill_color)
