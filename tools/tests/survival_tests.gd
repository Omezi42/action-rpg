extends RefCounted
## 出現の計算、小鬼の追跡、制限時間でのクリアを確かめる(GameDesign.md 1・4・5章)。

const SURVIVAL := preload("res://data/survival.tres")
const KOONI := preload("res://data/enemies/kooni.tres")
const AKA_ONI := preload("res://data/enemies/aka_oni.tres")
const AO_ONI := preload("res://data/enemies/ao_oni.tres")
const ARENA_SCENE := preload("res://scenes/stage/arena.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/kooni.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const SCREEN := Rect2(0, 0, 480, 270)
const PHYSICS_FPS := 60.0
const SHORT_CLEAR_TIME := 0.3

var _tree: SceneTree


func run(tree: SceneTree, check: Callable) -> void:
	_tree = tree
	_test_schedule(check)
	_test_spawn_point(check)
	_test_pick_enemy(check)
	_test_horde(check)
	await _test_enemy_chases(check)
	await _test_clear_stops_run(check)


func _test_schedule(check: Callable) -> void:
	var schedule := SpawnSchedule.new(SURVIVAL)
	check.call(is_equal_approx(schedule.interval_at(0.0), 1.5), "開始時の出現間隔は1.5秒")
	check.call(is_equal_approx(schedule.interval_at(30.0), 1.25), "導入の区間の中では直線的に縮む")
	check.call(is_equal_approx(schedule.interval_at(60.0), 1.0), "1:00から中盤(1.0秒)")
	check.call(absf(schedule.interval_at(179.9) - 0.5) < 0.01, "中盤の終わりは0.5秒")
	check.call(is_equal_approx(schedule.interval_at(280.0), 0.3), "最後の区間は0.3秒")
	check.call(schedule.max_enemies_at(0.0) == 30, "導入の上限30")
	check.call(schedule.max_enemies_at(200.0) == 90, "終盤の上限90")
	check.call(schedule.advance(0.0), "開始直後に1体目")
	check.call(not schedule.advance(1.4), "次は1.5秒後まで出ない")
	check.call(schedule.advance(0.1), "1.5秒で次が出る")
	schedule.advance(298.5)
	check.call(schedule.is_cleared(), "5分でクリア")


func _test_horde(check: Callable) -> void:
	var schedule := SpawnSchedule.new(SURVIVAL)
	schedule.advance(89.0)
	check.call(not schedule.take_horde(), "1:30までは大群が来ない")
	schedule.advance(1.0)
	check.call(schedule.take_horde(), "1:30に大群")
	check.call(not schedule.take_horde(), "大群は1回につき1度だけ")
	var area := SCREEN.grow(-SURVIVAL.spawn_margin)
	var points := schedule.horde_points(SCREEN, Vector2(60, 135))
	check.call(points.size() == 12, "大群は12体")
	var on_right := points.all(func(p: Vector2) -> bool: return is_equal_approx(p.x, area.end.x))
	check.call(on_right, "左寄りの主人公には右の辺から来る")
	check.call(is_equal_approx(points[1].y - points[0].y, 16.0), "16px間隔")
	check.call(is_equal_approx((points[0].y + points[11].y) / 2.0, area.get_center().y), "辺の中央ぞろえ")


func _test_pick_enemy(check: Callable) -> void:
	var schedule := SpawnSchedule.new(SURVIVAL)
	check.call(schedule.pick_enemy(0.99) == KOONI, "開始時は小鬼だけ")
	schedule.advance(60.0)
	check.call(schedule.pick_enemy(0.99) == AKA_ONI, "60秒から赤鬼が出る")
	check.call(schedule.pick_enemy(0.5) == KOONI, "重み6:3で小鬼が先")
	schedule.advance(120.0)
	check.call(schedule.pick_enemy(0.99) == AO_ONI, "180秒から青鬼が出る")
	check.call(schedule.pick_enemy(0.6) == AKA_ONI, "重み6:3:2の中ほどは赤鬼")
	check.call(schedule.pick_enemy(0.0) == KOONI, "roll 0 は先頭の小鬼")


func _test_spawn_point(check: Callable) -> void:
	var schedule := SpawnSchedule.new(SURVIVAL)
	var area := SCREEN.grow(-SURVIVAL.spawn_margin)
	var player_pos := Vector2(SURVIVAL.spawn_margin, SURVIVAL.spawn_margin)
	var all_ok := true
	for i in 50:
		var p := schedule.pick_spawn_point(SCREEN, player_pos)
		var on_edge := (
			is_equal_approx(p.x, area.position.x)
			or is_equal_approx(p.x, area.end.x)
			or is_equal_approx(p.y, area.position.y)
			or is_equal_approx(p.y, area.end.y)
		)
		var far := p.distance_to(player_pos) > SURVIVAL.spawn_min_player_distance
		all_ok = all_ok and on_edge and far
	check.call(all_ok, "出現位置は外周の周上で、主人公から離れている")


func _test_enemy_chases(check: Callable) -> void:
	var world := Node2D.new()
	_tree.root.add_child(world)
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = Vector2(100, 100)
	world.add_child(player)
	player.set_physics_process(false)
	var far_enemy := _add_test_enemy(world, Vector2(400, 100), false)
	var near_enemy := _add_test_enemy(world, Vector2(200, 100), false)
	var horde_enemy := _add_test_enemy(world, Vector2(300, 100), true)
	await _frames(0.1)
	check.call(far_enemy.state == Enemy.State.WANDER, "視認距離の外ではうろつく")
	check.call(near_enemy.state == Enemy.State.NOTICE, "視認距離に入ると気づいて止まる")
	check.call(horde_enemy.state == Enemy.State.CHASE, "大群は最初から追跡する")
	await _frames(KOONI.notice_time)
	check.call(near_enemy.state == Enemy.State.CHASE, "気づいた後に追跡へ移る")
	near_enemy.position = Vector2(100 + KOONI.lose_range + 20, 100)
	await _frames(0.05)
	check.call(near_enemy.state == Enemy.State.WANDER, "離れすぎると見失う")
	world.free()


func _add_test_enemy(world: Node2D, at: Vector2, alerted: bool) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.position = at
	enemy.alerted = alerted
	world.add_child(enemy)
	return enemy


func _test_clear_stops_run(check: Callable) -> void:
	var arena: Node2D = ARENA_SCENE.instantiate()
	arena.survival = SURVIVAL.duplicate()
	arena.survival.clear_time = SHORT_CLEAR_TIME
	_tree.root.add_child(arena)
	await _frames(SHORT_CLEAR_TIME + 0.2)
	check.call(arena.ended, "制限時間でクリアして終わる")
	check.call(_tree.paused, "終了時は画面を止める")
	check.call(arena.get_node("GameOver").visible, "結果を表示する")
	check.call(arena.alive_enemies() >= 1, "開始直後から敵が湧く")
	arena.free()
	_tree.paused = false


func _frames(seconds: float) -> void:
	for i in roundi(seconds * PHYSICS_FPS):
		await _tree.physics_frame
