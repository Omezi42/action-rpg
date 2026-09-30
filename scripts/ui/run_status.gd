extends Label
## 右上のレベル・残り時間・撃破数(GameDesign.md 6章)。

const SECONDS_PER_MINUTE := 60


func show_status(level: int, time_left: float, kills: int) -> void:
	var seconds := ceili(time_left)
	text = (
		"Lv %d  残り %d:%02d  撃破 %d"
		% [level, seconds / SECONDS_PER_MINUTE, seconds % SECONDS_PER_MINUTE, kills]
	)
