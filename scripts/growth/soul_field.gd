class_name SoulField
extends Node2D
## 敵が落とす魂をまとめて持ち、吸い寄せと取得を受け持つ(GameDesign.md 8章)。
## 最大 max_souls 個をノードにせず、配列で持って自分の _draw で描く。

signal collected(value: int)

@export var growth: GrowthData
@export var color := Color("9fe8ff")
@export var core_color := Color.WHITE
@export var radius := 2.0
@export var large_radius := 3.0

var player: Player

var _positions: Array[Vector2] = []
var _values: Array[int] = []


func count() -> int:
	return _positions.size()


func drop(at: Vector2, value: int) -> void:
	if value <= 0:
		return
	_positions.append(at)
	_values.append(value)
	while count() > growth.max_souls:
		_collect(0)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not player or count() == 0:
		return
	var target := player.global_position
	var dashing := player.is_striking()
	for i in range(count() - 1, -1, -1):
		var distance := _positions[i].distance_to(target)
		if distance > growth.pickup_radius:
			continue
		if dashing or distance <= growth.collect_distance:
			_collect(i)
			continue
		_positions[i] = _positions[i].move_toward(target, growth.pull_speed * delta)
		if _positions[i].distance_to(target) <= growth.collect_distance:
			_collect(i)
	queue_redraw()


func _collect(index: int) -> void:
	var value := _values[index]
	_positions.remove_at(index)
	_values.remove_at(index)
	collected.emit(value)


func _draw() -> void:
	for i in count():
		var r := large_radius if _values[i] > 1 else radius
		draw_circle(_positions[i], r, color)
		draw_circle(_positions[i], r / 2.0, core_color)
