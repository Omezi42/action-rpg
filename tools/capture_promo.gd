extends SceneTree
## 紹介用GIFのコマ撮り(build/promo/frames/*.png)。ウィンドウありで起動する。
## 全種類の群れを寄せ、敵が最も多く並ぶ向きへ一閃で斬り抜けるのを数回くり返す。GIFにするのは tools/make_promo_gif.py。
## 実行: Godot --path . --script res://tools/capture_promo.gd

const FRAMES_DIR := "res://build/promo/frames"
const ALL_KINDS_TIME := 200.0
const CROWD := 30
const GATHER_TIME := 3.5
const SLASHES := 3
const AFTER_SLASH := 1.2
const LINGER_TIME := 0.9
const SHOCKWAVE_RADIUS := 48.0
## 20fps(GIFの遅延は1/100秒単位なので50msちょうどにする)
const FRAME_MSEC := 50
const AIM_STEPS := 36
const AIM_REACH := 160.0
const AIM_WIDTH := 14.0
const PHYSICS_FPS := 60.0
const ARENA_PATH := "res://scenes/stage/arena.tscn"
const RECORDS_PATH := "user://capture_records.cfg"
const PROGRESS_PATH := "user://capture_progress.cfg"

var _arena: Node
var _player: Player
var _frame := 0
var _recording := false
var _next_shot := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	RunRecords.path = RECORDS_PATH
	TrainingProgress.path = PROGRESS_PATH
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES_DIR))
	for file in DirAccess.get_files_at(FRAMES_DIR):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FRAMES_DIR.path_join(file)))
	change_scene_to_file(ARENA_PATH)
	await _wait(0.5)
	_arena = current_scene
	_player = _arena.get_node("Entities/Player")
	## 被弾の点滅を映さないよう、敵の攻撃に見つからなくする
	_player.hurtbox.collision_layer = 0
	_player.stats.linger_time = LINGER_TIME
	_player.stats.shockwave_radius = SHOCKWAVE_RADIUS
	_arena.schedule.elapsed = ALL_KINDS_TIME
	for i in CROWD:
		_arena.spawn_enemy()
	_arena.spawn_horde()
	await _wait(GATHER_TIME)
	process_frame.connect(_record)
	_recording = true
	for i in SLASHES:
		await _slash()
		await _wait(AFTER_SLASH)
	_recording = false
	print("frames: %d" % _frame)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RECORDS_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROGRESS_PATH))
	quit()


func _slash() -> void:
	var aim := _best_aim()
	Input.action_press("iai")
	for i in roundi(PHYSICS_FPS * 2.0):
		await physics_frame
		_player.facing = aim
		if _player.state == Player.State.CHARGE and _player.charge.is_issen_window():
			break
	Input.action_release("iai")


## 踏み込みの線の近くに最も多く敵がいる向き
func _best_aim() -> Vector2:
	var best := Vector2.RIGHT
	var best_count := -1
	for step in AIM_STEPS:
		var dir := Vector2.RIGHT.rotated(TAU * step / AIM_STEPS)
		var count := 0
		for node in _arena.get_node("Entities").get_children():
			if node is Enemy:
				var offset: Vector2 = node.position - _player.position
				var along := offset.dot(dir)
				if along > 0.0 and along < AIM_REACH and absf(offset.cross(dir)) < AIM_WIDTH:
					count += 1
		if count > best_count:
			best_count = count
			best = dir
	return best


func _record() -> void:
	_close_choices()
	if not _recording or Time.get_ticks_msec() < _next_shot:
		return
	_next_shot = Time.get_ticks_msec() + FRAME_MSEC
	var image := root.get_texture().get_image()
	image.save_png(FRAMES_DIR.path_join("%04d.png" % _frame))
	_frame += 1


## レベルアップ・巻物の画面が開くとツリーが止まるので、すぐ1枚目を選んで閉じる
func _close_choices() -> void:
	var menu := _arena.get_node("LevelUp")
	if menu.visible:
		menu.choose(0)


func _wait(seconds: float) -> void:
	for i in roundi(seconds * PHYSICS_FPS):
		await physics_frame
