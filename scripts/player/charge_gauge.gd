extends Node2D
## 主人公の頭上に出す溜めゲージ(GameDesign.md 6章)。構え中だけ表示する。

@export var segment_size := Vector2(7, 3)
@export var segment_gap := 1.0
@export var back_color := Color(0, 0, 0, 0.6)
@export var fill_color := Color("7fd4ff")
@export var full_color := Color("ffffff")
@export var issen_color := Color("ffd84a")

@onready var _player: Player = get_parent()


func _process(_delta: float) -> void:
	visible = _player.state == Player.State.CHARGE
	queue_redraw()


func _draw() -> void:
	var charge := _player.charge
	var count := charge.top_stage_index()
	var width := count * segment_size.x + (count - 1) * segment_gap
	var issen := charge.is_issen_window()
	for i in count:
		var pos := Vector2(-width / 2.0 + i * (segment_size.x + segment_gap), 0)
		draw_rect(Rect2(pos - Vector2.ONE, segment_size + Vector2(2, 2)), back_color)
		var fill := charge.fill_of(i + 1)
		var color := issen_color if issen else (full_color if fill >= 1.0 else fill_color)
		draw_rect(Rect2(pos, Vector2(segment_size.x * fill, segment_size.y)), color)
