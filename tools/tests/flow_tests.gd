extends RefCounted
## 最高記録・大鬼の突進・弓鬼の矢・結果画面を確かめる(GameDesign.md 5・9章)。

const BOSS_SCENE := preload("res://scenes/enemies/oo_oni.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const ARENA_SCENE := preload("res://scenes/stage/arena.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/kooni.tscn")
const YUMI_ONI := preload("res://data/enemies/yumi_oni.tres")
const PHYSICS_FPS := 60.0
const RUSH_START := Vector2(200, 200)
const PLAYER_OFFSET := Vector2(100, 0)
const RUSH_TOLERANCE := 8.0

var _tree: SceneTree


func run(tree: SceneTree, check: Callable) -> void:
	_tree = tree
	_test_records(check)
	await _test_boss_rush(check)
	await _test_archer(check)
	await _test_arrow(check)
	_test_game_over_records(check)


func _test_records(check: Callable) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RunRecords.path))
	var empty := RunRecords.load_saved()
	check.call(empty.plays == 0 and empty.best_time == 0.0, "記録が無ければ0から")
	var updated := empty.submit(120.0, 50, 8, false)
	check.call(updated.size() == 3, "初回は3項目とも新記録")
	var loaded := RunRecords.load_saved()
	check.call(loaded.best_time == 120.0 and loaded.best_kills == 50, "保存した記録を読める")
	updated = loaded.submit(100.0, 70, 8, true)
	check.call(updated.size() == 1 and updated[0] == "best_kills", "超えた項目だけ新記録")
	loaded = RunRecords.load_saved()
	check.call(loaded.best_time == 120.0, "下回った記録は残す")
	check.call(loaded.clears == 1 and loaded.plays == 2, "クリア回数と挑戦回数を数える")
	updated = loaded.submit(10.0, 1, 1, false, 7)
	check.call(updated == ["best_hitokiri"], "最多人斬りを記録する")
	check.call(RunRecords.load_saved().best_hitokiri == 7, "最多人斬りを保存する")


func _test_boss_rush(check: Callable) -> void:
	var world := Node2D.new()
	_tree.root.add_child(world)
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = RUSH_START + PLAYER_OFFSET
	player.set_physics_process(false)
	world.add_child(player)
	var boss: Enemy = BOSS_SCENE.instantiate()
	boss.position = RUSH_START
	boss.alerted = true
	world.add_child(boss)
	var warned := [false]
	boss.rush_warned.connect(func() -> void: warned[0] = true)
	await _frames(0.1)
	check.call(boss.state == Enemy.State.WINDUP and warned[0], "近づくと突進の予告に入る")
	check.call(boss.aim_direction.is_equal_approx(Vector2.RIGHT), "予告の始めに主人公の方へ向く")
	var hitbox := Hitbox.new()
	hitbox.power = 1
	hitbox.direction = Vector2.LEFT
	boss.hurtbox.hurt.emit(hitbox)
	hitbox.free()
	check.call(boss.state == Enemy.State.WINDUP, "予告中は斬られても中断しない")
	check.call(boss.flash_left > 0.0, "斬られると光る")
	player.position = RUSH_START + Vector2(0, PLAYER_OFFSET.x)
	await _frames(boss.data.attack_windup)
	check.call(boss.state == Enemy.State.RUSH, "予告の後に突進")
	await _frames(boss.data.rush_time + 0.05)
	check.call(boss.state == Enemy.State.RECOVER, "突進の後は隙")
	var traveled := boss.position.x - RUSH_START.x
	check.call(absf(traveled - boss.data.rush_distance) < RUSH_TOLERANCE, "予告の向きへ突進の距離だけ進む")
	await _frames(boss.data.attack_recover + 0.05)
	check.call(boss.state == Enemy.State.CHASE, "隙の後は追跡へ戻る")
	world.free()


func _test_archer(check: Callable) -> void:
	var world := Node2D.new()
	_tree.root.add_child(world)
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = RUSH_START + PLAYER_OFFSET
	player.set_physics_process(false)
	world.add_child(player)
	var archer: Enemy = ENEMY_SCENE.instantiate()
	archer.data = YUMI_ONI
	archer.position = RUSH_START
	archer.alerted = true
	world.add_child(archer)
	var shots: Array[Vector2] = []
	archer.shot_fired.connect(func(_from: Vector2, dir: Vector2) -> void: shots.append(dir))
	await _frames(0.05)
	check.call(archer.state == Enemy.State.AIM, "射程に入ると立ち止まって構える")
	await _frames(YUMI_ONI.shot_windup)
	check.call(shots.size() == 1 and shots[0].is_equal_approx(Vector2.RIGHT), "構えの後に主人公の方へ矢を放つ")
	await _frames(0.5)
	check.call(archer.position == RUSH_START, "次の構えまでも射程内なら立ち止まる")
	check.call(shots.size() == 1, "次の構えまで間を空ける")
	world.free()


func _test_arrow(check: Callable) -> void:
	var world := Node2D.new()
	_tree.root.add_child(world)
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = RUSH_START + PLAYER_OFFSET
	world.add_child(player)
	var arrow := Arrow.new()
	arrow.position = RUSH_START + Vector2(0, -10)
	arrow.setup(Vector2.RIGHT, YUMI_ONI.shot_speed, YUMI_ONI.shot_distance, YUMI_ONI.shot_damage)
	world.add_child(arrow)
	var hp := player.health.hp
	await _frames(PLAYER_OFFSET.x / YUMI_ONI.shot_speed + 0.2)
	check.call(player.health.hp == hp - 1, "矢が当たると1ダメージ")
	check.call(not is_instance_valid(arrow), "当たった矢は消える")
	world.free()


func _test_game_over_records(check: Callable) -> void:
	var arena: Node2D = ARENA_SCENE.instantiate()
	_tree.root.add_child(arena)
	arena.kills = 999
	arena.hitokiri.best = 999
	var player: Player = arena.get_node("Entities/Player")
	player.health.damage(player.health.hp)
	var label: Label = arena.get_node("GameOver/Label")
	check.call(arena.ended and label.text.begins_with("ゲームオーバー"), "HP0でゲームオーバー")
	check.call(label.text.contains("撃破 999 新記録!"), "更新した記録に新記録と出す")
	check.call(label.text.contains("最多人斬り 999 新記録!"), "結果に最多人斬りを出す")
	arena.free()
	_tree.paused = false


func _frames(seconds: float) -> void:
	for i in roundi(seconds * PHYSICS_FPS):
		await _tree.physics_frame
