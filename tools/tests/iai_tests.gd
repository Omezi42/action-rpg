extends RefCounted
## IaiCharge の段階判定と一閃の受付、パチンコ式の狙い(GameDesign.md 2・3章)。

const IAI := preload("res://data/iai.tres")


func run(check: Callable) -> void:
	var charge := IaiCharge.new(IAI)
	check.call(charge.release().label == "抜き打ち", "押してすぐ離すと抜き打ち")
	check.call(charge.advance(0.15), "0.15秒で段階が上がる")
	check.call(charge.release().label == "壱", "0.15秒で壱")
	charge.advance(0.40)
	check.call(charge.release().label == "弐", "0.55秒で弐")
	charge.advance(0.45)
	check.call(charge.is_issen_window(), "参に到達した瞬間は一閃の受付中")
	check.call(charge.release().power == 8, "受付中に離すと一閃(威力8)")
	charge.advance(0.15)
	check.call(not charge.is_issen_window(), "0.15秒で受付が終わる")
	check.call(charge.release().label == "参", "受付後は参のまま")
	charge.reset()
	check.call(charge.stage_index() == 0, "reset で抜き打ちへ戻る")
	check.call(is_equal_approx(charge.fill_of(1), 0.0), "溜め始めのゲージは空")
	var origin := Vector2(100, 100)
	var aim := Player.cursor_direction(origin, Vector2(130, 70), IAI.aim_deadzone)
	check.call(aim.is_equal_approx(Vector2(1, -1).normalized()), "右上のカーソルへ踏み込む")
	aim = Player.cursor_direction(origin, Vector2(104, 96), IAI.aim_deadzone)
	check.call(aim == Vector2.ZERO, "カーソルが遊び未満の近さなら向きを変えない")
