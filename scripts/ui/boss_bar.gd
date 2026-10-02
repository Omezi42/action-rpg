extends Control
## 下端の大鬼のHPバー(GameDesign.md 6章)。大鬼が出ている間だけ表示する。

@export var back_color := Color(0, 0, 0, 0.6)
@export var fill_color := Color("b04dc0")
@export var name_color := Color.WHITE
@export var label := "大鬼"
@export var font_size := 10
@export var label_gap := 2.0

var _ratio := 1.0


func _ready() -> void:
	visible = false


func bind(health: Health) -> void:
	health.changed.connect(_on_health_changed)
	_on_health_changed(health.hp, health.max_hp)
	visible = true


func _on_health_changed(hp: int, max_hp: int) -> void:
	_ratio = clampf(float(hp) / max_hp, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), back_color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * _ratio, size.y)), fill_color)
	var font := ThemeDB.fallback_font
	draw_string(
		font, Vector2(0, -label_gap), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, name_color
	)
