extends Node2D
## ヒット火花(コード描画)。放射状の短い線が広がって消える。

const LIFE := 0.15
const RAYS := 6
const RADIUS := 10.0
const COLOR := Color("fff2a8")

var color := COLOR

var _age := 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var t := _age / LIFE
	for i in RAYS:
		var dir := Vector2.RIGHT.rotated(TAU * i / RAYS)
		draw_line(dir * RADIUS * t, dir * RADIUS * (0.4 + t), Color(color, 1.0 - t), 2)
