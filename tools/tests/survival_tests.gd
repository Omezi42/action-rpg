extends RefCounted
## 出現の計算、小鬼の追跡、制限時間でのクリアを確かめる(GameDesign.md 1・4・5章)。

const SURVIVAL := preload("res://data/survival.tres")
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
	await _test_enemy_chases(check)
	await _test_clear_stops_run(check)


func _test_schedule(check: Callable) -> void:
	var schedule := SpawnSchedule.new(SURVIVAL)
	check.call(is_equal_approx(schedule.interval_at(0.0), 2.0), "開始時の出現間隔は2.0秒")
	check.call(is_equal_approx(schedule.interval_at(60.0), 0.4), "60秒で0.4秒")
	check.call(is_equal_approx(schedule.interval_at(30.0), 1.2), "途中は直線的に縮む")
	check.call(schedule.advance(0.0), "開始直後に1体目")
	check.call(not schedule.advance(1.9), "次は2秒後まで出ない")
	check.call(schedule.advance(0.1), "2秒で次が出る")
	schedule.advance(58.0)
	check.call(schedule.is_cleared(), "60秒でクリア")


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
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.position = Vector2(300, 100)
	world.add_child(enemy)
	await _frames(0.5)
	check.call(enemy.position.x < 280 and enemy.position.x > 270, "小鬼は遠くからでも追ってくる")
	world.free()


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
