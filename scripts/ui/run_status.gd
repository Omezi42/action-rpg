extends Label
## 右上のレベル・残り時間・撃破数(GameDesign.md 6章)。大鬼が出ている間は残り時間の代わりに「大鬼」。

const SECONDS_PER_MINUTE := 60


func show_status(level: int, time_left: float, kills: int, boss := false) -> void:
	var seconds := ceili(time_left)
	var clock := "残り %d:%02d" % [seconds / SECONDS_PER_MINUTE, seconds % SECONDS_PER_MINUTE]
	text = "Lv %d  %s  撃破 %d" % [level, "大鬼" if boss else clock, kills]
