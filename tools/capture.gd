extends SceneTree
## 見た目確認用のスクリーンショット(logs/shot_*.png)。ウィンドウありで起動する。
## 起動直後 → フィールドの角(カメラが端で止まる)→ 群れを湧かせて寄ってきたところ → 敵の攻撃の予告 → 斜めに構えて弐(予告線)→ 一閃の受付中 → 踏み込み直後
## → 斬り抜けた後(魂が落ちている)→ レベルアップ画面 → 残り時間を飛ばして大鬼 → 突進の予告 → 大鬼を倒した結果表示。
## 最初にタイトル画面も撮る。
## 群れには大群(一列)と全種類(弓鬼を含む)を混ぜ、斬痕・残心を取った状態で斬る。
## マウスの狙いは実カーソルを動かさないよう facing を直接向ける。

const ALL_KINDS_TIME := 200.0
const LINGER_TIME := 0.9
const SHOCKWAVE_RADIUS := 48.0
const SCALE := 3
const PHYSICS_FPS := 60.0
const CROWD := 24
const ALMOST_CLEAR := 0.1
const AIM := Vector2(1.0, -0.45)
const CORNER := Vector2(60, 60)
const CROWD_WAIT := 3.0
const ARENA_PATH := "res://scenes/stage/arena.tscn"
## 本物の最高記録に触れないよう、撮影中の記録はここへ書く
const CAPTURE_RECORDS_PATH := "user://capture_records.cfg"
const BOSS_WAIT := 2.5
const BOSS_APPROACH := Vector2(-100, 30)
const KOONI := preload("res://data/enemies/kooni.tres")
const AKA_ONI := preload("res://data/enemies/aka_oni.tres")
const AO_ONI := preload("res://data/enemies/ao_oni.tres")
## 予告を撮る間は被弾させない(この後の構えを止めないため)
const WARNING_GUARD := 2.0
const WARNING_WAIT := 0.3


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	RunRecords.path = CAPTURE_RECORDS_PATH
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await _wait(0.5)
	await _shot("0_title")
	change_scene_to_file(ARENA_PATH)
	await _wait(0.5)
	await _shot("1_start")
	var arena := current_scene
	var player: Player = arena.get_node("Entities/Player")
	var start := player.position
	player.position = CORNER
	await _wait(0.1)
	await _shot("1b_field_corner")
	player.position = start
	await _wait(0.1)
	arena.schedule.elapsed = ALL_KINDS_TIME
	for i in CROWD:
		arena.spawn_enemy()
	arena.spawn_horde()
	await _wait(CROWD_WAIT)
	await _shot("2_crowd")
	await _shot_warnings(arena, player)
	player.stats.linger_time = LINGER_TIME
	player.stats.shockwave_radius = SHOCKWAVE_RADIUS
	Input.action_press("move_right")
	await _wait(0.05)
	Input.action_press("iai")
	await _wait(0.05)
	Input.action_release("move_right")
	player.facing = AIM.normalized()
	await _wait(0.55)
	await _shot("3_charge_guide")
	await _wait(0.4)
	await _shot("3b_issen_window")
	Input.action_release("iai")
	await _wait(0.12)
	await _shot("4_slash")
	await _wait(0.4)
	await _shot("5_after")
	arena._on_soul_collected(arena.progression.exp_to_next())
	await _wait(0.1)
	await _shot("6_level_up")
	arena.get_node("LevelUp").choose(0)
	arena.schedule.elapsed = arena.survival.clear_time - ALMOST_CLEAR
	await _wait(BOSS_WAIT)
	await _shot("7_boss")
	await _wait_boss_windup(arena)
	await _shot("7b_boss_rush_warning")
	arena.boss.health.damage(arena.boss.health.hp)
	arena.boss.fall()
	await _wait(0.3)
	await _shot("8_result")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CAPTURE_RECORDS_PATH))
	quit()


## 主人公の周りに小鬼・赤鬼・青鬼を置き、そろって予告しているところを撮る
func _shot_warnings(arena: Node, player: Player) -> void:
	player.invincible_left = WARNING_GUARD
	player.hurtbox.invincible = true
	arena._add_enemy(KOONI, player.position + Vector2(-40, 0), true)
	arena._add_enemy(AKA_ONI, player.position + Vector2(0, -80), true)
	arena._add_enemy(AO_ONI, player.position + Vector2(30, 12), true)
	await _wait(WARNING_WAIT)
	await _shot("2b_enemy_warnings")


## 主人公を大鬼の近くへ置き、突進の予告が半分進んだところまで待つ
func _wait_boss_windup(arena: Node) -> void:
	var player: Player = arena.get_node("Entities/Player")
	player.position = arena.boss.position + BOSS_APPROACH
	for i in roundi(PHYSICS_FPS * BOSS_WAIT):
		await physics_frame
		if arena.boss.windup_ratio() >= 0.5:
			return


func _shot(label: String) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	image.save_png("res://logs/shot_%s.png" % label)


func _wait(seconds: float) -> void:
	for i in roundi(seconds * PHYSICS_FPS):
		await physics_frame
