extends StaticBody2D
## 子の矩形コリジョンをそのまま塗る(壁・岩の仮の絵)。配置はシーンのコリジョンが唯一の情報源。

@export var color := Color("3b3b44")
@export var top_color := Color("55555f")
@export var top_height := 3.0


func _draw() -> void:
	for child in get_children():
		var shape_node := child as CollisionShape2D
		if not shape_node or not shape_node.shape is RectangleShape2D:
			continue
		var size: Vector2 = shape_node.shape.size
		var rect := Rect2(shape_node.position - size / 2.0, size)
		draw_rect(rect, color)
		draw_rect(Rect2(rect.position, Vector2(size.x, top_height)), top_color)
