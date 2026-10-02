class_name Scroll
extends Node2D
## 精鋭鬼が落とす巻物(GameDesign.md 8章)。消えず、主人公が近づいたら拾う(踏み込み中も)。絵はコード描画。

signal picked

@export var pickup_radius := 16.0
@export var paper_color := Color("f0e2b8")
@export var rod_color := Color("8a4a2a")
@export var glow_color := Color(1.0, 0.85, 0.3, 0.35)
@export var paper := Rect2(-5, -9, 10, 6)
@export var rod_size := Vector2(2, 8)
@export var glow_radius := 8.0
@export var bob_height := 1.5
@export var bob_speed := 4.0

var player: Node2D

var _age := 0.0


func _physics_process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if player and global_position.distance_to(player.global_position) <= pickup_radius:
		picked.emit()
		queue_free()


func _draw() -> void:
	var bob := Vector2(0, -bob_height * (1.0 + sin(_age * bob_speed)))
	var center := paper.get_center() + bob
	draw_circle(center, glow_radius, glow_color)
	draw_rect(Rect2(paper.position + bob, paper.size), paper_color)
	for x in [paper.position.x, paper.end.x]:
		var rod := Rect2(Vector2(x - rod_size.x / 2.0, center.y - rod_size.y / 2.0), rod_size)
		draw_rect(rod, rod_color)
