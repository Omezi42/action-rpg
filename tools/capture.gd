extends SceneTree
## 見た目確認用のスクリーンショット(logs/shot_*.png)。ウィンドウありで起動する。
## 起動直後 → 群れを湧かせて寄ってきたところ → 斜めに構えて弐(予告線)→ 一閃の受付中 → 踏み込み直後
## → 斬り抜けた後 → 残り時間を飛ばしてクリアの結果表示 の7枚。
## マウスの狙いは実カーソルを動かさないよう facing を直接向ける。

const ALL_KINDS_TIME := 25.0
const SCALE := 3
const PHYSICS_FPS := 60.0
const CROWD := 24
const ALMOST_CLEAR := 0.1
const AIM := Vector2(1.0, -0.45)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await _wait(0.5)
	await _shot("1_start")
	var arena := current_scene
	arena.schedule.elapsed = ALL_KINDS_TIME
	for i in CROWD:
		arena.spawn_enemy()
	await _wait(1.8)
	await _shot("2_crowd")
	Input.action_press("move_right")
	await _wait(0.05)
	Input.action_press("iai")
	await _wait(0.05)
	Input.action_release("move_right")
	arena.get_node("Entities/Player").facing = AIM.normalized()
	await _wait(0.55)
	await _shot("3_charge_guide")
	await _wait(0.4)
	await _shot("3b_issen_window")
	Input.action_release("iai")
	await _wait(0.12)
	await _shot("4_slash")
	await _wait(0.4)
	await _shot("5_after")
	arena.schedule.elapsed = arena.survival.clear_time - ALMOST_CLEAR
	await _wait(0.3)
	await _shot("6_result")
	quit()


func _shot(label: String) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	image.save_png("res://logs/shot_%s.png" % label)


func _wait(seconds: float) -> void:
	for i in roundi(seconds * PHYSICS_FPS):
		await physics_frame
