extends SceneTree
## 見た目確認用のスクリーンショット(logs/shot_*.png)。ウィンドウありで起動する。
## 起動直後 → 右へ歩いて構え(弐まで溜め) → 一閃の受付中 → 踏み込み直後 の4枚。

const SCALE := 3
const PHYSICS_FPS := 60.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await _wait(0.5)
	await _shot("1_start")
	Input.action_press("move_right")
	await _wait(0.4)
	Input.action_press("iai")
	await _wait(0.6)
	Input.action_release("move_right")
	await _shot("2_charge")
	await _wait(0.45)
	await _shot("3_issen_window")
	Input.action_release("iai")
	await _wait(0.12)
	await _shot("4_slash")
	quit()


func _shot(label: String) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	image.save_png("res://logs/shot_%s.png" % label)


func _wait(seconds: float) -> void:
	for i in roundi(seconds * PHYSICS_FPS):
		await physics_frame
