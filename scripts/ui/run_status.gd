extends Label
## 右上の経過時間 / 制限時間と撃破数(GameDesign.md 6章)。


func show_status(elapsed: float, clear_time: float, kills: int) -> void:
	text = "%d / %d秒  撃破 %d" % [floori(minf(elapsed, clear_time)), roundi(clear_time), kills]
