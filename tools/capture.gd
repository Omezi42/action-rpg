extends SceneTree
## 見た目確認用のスクリーンショット(logs/shot_*.png)。ウィンドウありで起動する。
## 起動直後 → フィールドの角(カメラが端で止まる)→ 群れを湧かせて寄ってきたところ → 敵の攻撃の予告 → 赤鬼のジャンプ → 斜めに構えて弐(予告線)→ 一閃の受付中 → 踏み込み直後
## → 斬り抜けた後(魂が落ちている)→ 人斬りの文字 → レベルアップ画面 → 燕返しの斬り返し中 → 影縫いで止まった敵
## → 精鋭鬼 → 巻物 → 巻物の画面 → 残り時間を飛ばして大鬼 → 突進の予告 → 大鬼を倒した結果表示。
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
## 赤鬼が跳んで最も高いあたりまで
const JUMP_WAIT := 0.25
## 一閃の納刀が終わって「N人斬り」が出ているあたりまで(ヒットストップの分だけ遅れる)
const HITOKIRI_WAIT := 0.2
const ELITE_OFFSET := Vector2(48, 0)
## 燕返し3段の距離
const RETURN_DISTANCE := 96.0
const NI_HOLD := 0.6
const RETURN_SHOT_WAIT := 0.06
## 影縫い3段の時間
const BIND_TIME := 1.8
const BIND_OFFSETS: Array[Vector2] = [Vector2(40, -20), Vector2(56, 16)]


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
	await _wait(HITOKIRI_WAIT)
	await _shot("5b_hitokiri")
	arena._on_soul_collected(arena.progression.exp_to_next())
	await _wait(0.1)
	await _shot("6_level_up")
	arena.get_node("LevelUp").choose(0)
	await _shot_return(player)
	await _shot_bind(arena, player)
	await _shot_elite_and_scroll(arena, player)
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
	await _wait(JUMP_WAIT)
	await _shot("2c_aka_oni_jump")


## 弐で右へ踏み込み、納刀中に押して斬り返しているところを撮る
func _shot_return(player: Player) -> void:
	player.invincible_left = WARNING_GUARD
	player.stats.return_distance = RETURN_DISTANCE
	await _wait(0.05)
	Input.action_press("iai")
	await _wait(0.05)
	player.facing = Vector2.RIGHT
	await _wait(NI_HOLD)
	Input.action_release("iai")
	for i in roundi(PHYSICS_FPS):
		await physics_frame
		if player.state == Player.State.SHEATHE:
			break
	Input.action_press("iai")
	await _wait(RETURN_SHOT_WAIT)
	await _shot("5c_return")
	Input.action_release("iai")
	await _wait(0.5)


## 主人公の横に青鬼と小鬼を出して影縫いで止め、足元の影を撮る
func _shot_bind(arena: Node, player: Player) -> void:
	player.invincible_left = WARNING_GUARD
	player.hurtbox.invincible = true
	var kinds := [AO_ONI, KOONI]
	for i in kinds.size():
		var enemy: Enemy = arena._add_enemy(kinds[i], player.position + BIND_OFFSETS[i], true)
		enemy.bind(BIND_TIME)
	await _wait(0.2)
	await _shot("5d_bind")


## 精鋭鬼(金の縁)を主人公の横に出して撮り、倒して落ちた巻物を撮り、拾って巻物の画面を撮る。
## 巻物の画面には奥義(金の枠)が出るよう、奥義の条件の強化を最大にしておく
func _shot_elite_and_scroll(arena: Node, player: Player) -> void:
	player.invincible_left = WARNING_GUARD
	player.hurtbox.invincible = true
	var elite: Enemy = arena.spawn_elite()
	elite.position = player.position + ELITE_OFFSET
	await _wait(0.1)
	await _shot("6b_elite")
	elite.health.damage(elite.health.hp)
	elite.fall()
	await _wait(0.1)
	await _shot("6c_scroll")
	_unlock_ougi(arena.progression, arena.growth)
	player.position = elite_drop_point(arena)
	await _wait(0.1)
	await _shot("6d_scroll_menu")
	var menu := arena.get_node("LevelUp")
	menu.choose(menu._cards.size() - 1)


func _unlock_ougi(progression: Progression, growth: GrowthData) -> void:
	var ougi_list: Array = growth.ougi
	for ougi: Resource in ougi_list:
		for required: Resource in ougi.requires:
			progression._levels[required] = required.max_level


func elite_drop_point(arena: Node) -> Vector2:
	for node in arena.get_node("Entities").get_children():
		if node is Scroll:
			return node.position
	return Vector2.ZERO


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
