extends Node2D
## 構え中に踏み込む線を足元から点線で予告する(GameDesign.md 3・6章)。長さは今離したときの踏み込み距離。

@export var color := Color(1, 1, 1, 0.55)
@export var issen_color := Color("ffd84a")
@export var dash_length := 4.0
@export var width := 1.0
@export var tip_radius := 2.0

@onready var _player: Player = get_parent()


func _process(_delta: float) -> void:
	visible = _player.state == Player.State.CHARGE
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var tip := _player.facing * _player.strike_distance(_player.charge.release())
	var c := issen_color if _player.charge.is_issen_window() else color
	draw_dashed_line(Vector2.ZERO, tip, c, width, dash_length)
	draw_circle(tip, tip_radius, c)
