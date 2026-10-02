extends RefCounted
## 出現の計算、小鬼の追跡、大鬼を倒してのクリアを確かめる(GameDesign.md 1・4・5章)。

const SURVIVAL := preload("res://data/survival.tres")
const KOONI := preload("res://data/enemies/kooni.tres")
const AKA_ONI := preload("res://data/enemies/aka_oni.tres")
const AO_ONI := preload("res://data/enemies/ao_oni.tres")
const YUMI_ONI := preload("res://data/enemies/yumi_oni.tres")
const ARENA_SCENE := preload("res://scenes/stage/arena.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/kooni.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const SCREEN_SIZE := Vector2(480, 270)
const MID_VIEW := Rect2(Vector2(480, 270), SCREEN_SIZE)
const ROCK_CLEAR_RADIUS := 80.0
const ROCK_COUNT_MIN := 12
const ROCK_COUNT_MAX := 16
const PAN_WAIT := 0.35
const PHYSICS_FPS := 60.0
const SHORT_CLEAR_TIME := 0.3

var _tree: SceneTree


func run(tree: SceneTree, check: Callable) -> void:
	_tree = tree
	_test_schedule(check)
	_test_spawn_point(check)
	_test_pick_enemy(check)
	_test_horde(check)
	_test_field(check)
	await _test_camera(check)
	await _test_enemy_chases(check)
	await _test_enemy_despawns(check)
	_test_elite_schedule(check)
	await _test_elite_drops_scroll(check)
	await _test_boss_clears_run(check)


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
	check.call(schedule.is_boss_time(), "5分で大鬼の区間")
	check.call(is_equal_approx(schedule.interval_at(300.0), 1.0), "大鬼の区間の出現間隔1.0秒")
	check.call(schedule.max_enemies_at(300.0) == 30, "大鬼の区間の上限30")
	check.call(schedule.take_boss(), "5分で大鬼が出る")
	check.call(not schedule.take_boss(), "大鬼は1度だけ")


func _test_horde(check: Callable) -> void:
	var schedule := SpawnSchedule.new(SURVIVAL)
	schedule.advance(89.0)
	check.call(not schedule.take_horde(), "1:30までは大群が来ない")
	schedule.advance(1.0)
	check.call(schedule.take_horde(), "1:30に大群")
	check.call(not schedule.take_horde(), "大群は1回につき1度だけ")
	var left_view := Rect2(Vector2(0, 270), SCREEN_SIZE)
	var points := schedule.horde_points(left_view)
	check.call(points.size() == 12, "大群は12体")
	var right_x := left_view.end.x + SURVIVAL.spawn_margin
	var on_right := points.all(func(p: Vector2) -> bool: return is_equal_approx(p.x, right_x))
	check.call(on_right, "左端の画面には、外側が最も広い右の辺の外から来る")
	check.call(is_equal_approx(points[1].y - points[0].y, 16.0), "16px間隔")
	check.call(
		is_equal_approx((points[0].y + points[11].y) / 2.0, left_view.get_center().y), "辺の中央ぞろえ"
	)
	var long_data: SurvivalData = SURVIVAL.duplicate()
	long_data.horde_count = 30
	var long_points := SpawnSchedule.new(long_data).horde_points(
		Rect2(Vector2(960, 0), SCREEN_SIZE)
	)
	var inner := Rect2(Vector2.ZERO, SURVIVAL.field_size).grow(-SURVIVAL.spawn_margin)
	var inside := long_points.all(func(p: Vector2) -> bool: return inner.grow(0.01).has_point(p))
	check.call(inside, "フィールドからはみ出す列は内側へ詰める")


func _test_pick_enemy(check: Callable) -> void:
	var schedule := SpawnSchedule.new(SURVIVAL)
	check.call(schedule.pick_enemy(0.99) == KOONI, "開始時は小鬼だけ")
	schedule.advance(60.0)
	check.call(schedule.pick_enemy(0.99) == AKA_ONI, "60秒から赤鬼が出る")
	check.call(schedule.pick_enemy(0.5) == KOONI, "重み6:3で小鬼が先")
	schedule.advance(60.0)
	check.call(schedule.pick_enemy(0.99) == YUMI_ONI, "120秒から弓鬼が出る")
	schedule.advance(60.0)
	check.call(schedule.pick_enemy(0.8) == AO_ONI, "180秒から青鬼が出る(重み 6:3:2:2)")
	check.call(schedule.pick_enemy(0.6) == AKA_ONI, "重み6:3:2の中ほどは赤鬼")
	check.call(schedule.pick_enemy(0.0) == KOONI, "roll 0 は先頭の小鬼")


func _test_spawn_point(check: Callable) -> void:
	var schedule := SpawnSchedule.new(SURVIVAL)
	var never := func(_p: Vector2) -> bool: return false
	var area := MID_VIEW.grow(SURVIVAL.spawn_margin)
	var all_on_edge := true
	for i in 50:
		var p := schedule.pick_spawn_point(MID_VIEW, never)
		all_on_edge = all_on_edge and _on_edge(p, area)
	check.call(all_on_edge, "出現位置は画面の外側16pxの周上")
	var corner_view := Rect2(Vector2.ZERO, SCREEN_SIZE)
	var field := Rect2(Vector2.ZERO, SURVIVAL.field_size)
	var all_in_field := true
	for i in 50:
		all_in_field = (
			all_in_field and field.has_point(schedule.pick_spawn_point(corner_view, never))
		)
	check.call(all_in_field, "フィールドの外には出さない")
	var left_blocked := func(p: Vector2) -> bool: return p.x < MID_VIEW.get_center().x
	var all_right := true
	for i in 50:
		all_right = (
			all_right
			and schedule.pick_spawn_point(MID_VIEW, left_blocked).x >= MID_VIEW.get_center().x
		)
	check.call(all_right, "岩と重なる点は引き直す")
	var always := func(_p: Vector2) -> bool: return true
	check.call(schedule.pick_spawn_point(MID_VIEW, always) == Vector2.INF, "置ける点が無ければ出さない")


func _on_edge(p: Vector2, area: Rect2) -> bool:
	return (
		is_equal_approx(p.x, area.position.x)
		or is_equal_approx(p.x, area.end.x)
		or is_equal_approx(p.y, area.position.y)
		or is_equal_approx(p.y, area.end.y)
	)


func _shape_rects(body: Node) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for child: CollisionShape2D in body.get_children():
		var size: Vector2 = child.shape.size
		rects.append(Rect2(child.position - size / 2.0, size))
	return rects


func _test_field(check: Callable) -> void:
	var arena: Node2D = ARENA_SCENE.instantiate()
	var walls := _shape_rects(arena.get_node("Walls"))
	var bounds := walls[0]
	for rect in walls:
		bounds = bounds.merge(rect)
	check.call(bounds == Rect2(Vector2.ZERO, SURVIVAL.field_size), "外周の壁がフィールドを囲む")
	var start: Vector2 = arena.get_node("Entities/Player").position
	check.call(start == SURVIVAL.field_size / 2.0, "主人公はフィールドの中央から始める")
	var rocks := _shape_rects(arena.get_node("Rocks"))
	check.call(rocks.size() >= ROCK_COUNT_MIN and rocks.size() <= ROCK_COUNT_MAX, "岩は12〜16個")
	var clear := rocks.all(
		func(r: Rect2) -> bool:
			return start.clamp(r.position, r.end).distance_to(start) > ROCK_CLEAR_RADIUS
	)
	check.call(clear, "開始地点の半径80pxに岩を置かない")
	arena.free()


func _test_camera(check: Callable) -> void:
	var arena: Node2D = ARENA_SCENE.instantiate()
	_tree.root.add_child(arena)
	arena.set_physics_process(false)
	var player: Player = arena.get_node("Entities/Player")
	player.set_physics_process(false)
	var camera: FollowCamera = arena.get_node("FollowCamera")
	await _frames(0.05)
	check.call(camera.view_rect().get_center() == player.position, "カメラは主人公を中心に映す")
	player.position = Vector2(30, 30)
	await _frames(0.05)
	check.call(camera.view_rect().position == Vector2.ZERO, "フィールドの端でカメラが止まる")
	player.position = SURVIVAL.field_size / 2.0
	player.facing = Vector2.RIGHT
	player.state = Player.State.CHARGE
	await _frames(camera.charge_pan_time + 0.05)
	var midpoint := ((player.position + player.aim_tip()) / 2.0).round()
	check.call(camera.global_position == midpoint, "構え中は予告線の先端との中点へ寄せる")
	player.state = Player.State.MOVE
	await _frames(camera.return_pan_time / 2.0)
	check.call(camera.global_position != player.position, "主人公へは時間をかけて戻す")
	await _frames(camera.return_pan_time)
	check.call(camera.global_position == player.position, "構えを解くと主人公の中心へ戻る")
	arena.free()


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
	check.call(far_enemy.position.x < 400, "出現してすぐは主人公の方へうろつく")
	check.call(near_enemy.state == Enemy.State.NOTICE, "視認距離に入ると気づいて止まる")
	check.call(horde_enemy.state == Enemy.State.CHASE, "大群は最初から追跡する")
	await _frames(KOONI.notice_time)
	check.call(near_enemy.state == Enemy.State.CHASE, "気づいた後に追跡へ移る")
	near_enemy.position = Vector2(100 + KOONI.lose_range + 20, 100)
	await _frames(0.05)
	check.call(near_enemy.state == Enemy.State.WANDER, "離れすぎると見失う")
	world.free()


func _test_enemy_despawns(check: Callable) -> void:
	var world := Node2D.new()
	_tree.root.add_child(world)
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = Vector2(100, 100)
	world.add_child(player)
	player.set_physics_process(false)
	var far_enemy := _add_test_enemy(world, Vector2(100 + KOONI.despawn_range + 50, 100), false)
	var defeated := [false]
	far_enemy.defeated.connect(func(_e: Enemy) -> void: defeated[0] = true)
	await _frames(0.05)
	check.call(not is_instance_valid(far_enemy), "うろつき中に600px以上離れた敵は消える")
	check.call(not defeated[0], "消えた敵は撃破に数えない")
	world.free()


func _test_elite_schedule(check: Callable) -> void:
	var schedule := SpawnSchedule.new(SURVIVAL)
	schedule.advance(119.0)
	check.call(not schedule.take_elite(), "2:00までは精鋭鬼が来ない")
	schedule.advance(1.0)
	check.call(schedule.take_elite() and not schedule.take_elite(), "2:00に1度だけ")
	schedule.advance(120.0)
	check.call(schedule.take_elite(), "4:00に2体目")
	schedule.advance(60.0)
	check.call(not schedule.take_elite(), "精鋭鬼は2体まで")


## 精鋭鬼を倒すと巻物が落ち、拾うと巻物の3枚が出て、全回復でHPが戻る(GameDesign.md 5・8章)
func _test_elite_drops_scroll(check: Callable) -> void:
	var arena: Node2D = ARENA_SCENE.instantiate()
	_tree.root.add_child(arena)
	await _frames(0.1)
	var player: Player = arena.get_node("Entities/Player")
	arena.schedule.elapsed = 120.0
	var elite: Enemy = arena.spawn_elite()
	check.call(elite.elite and elite.state == Enemy.State.CHASE, "精鋭鬼は最初から追跡する")
	check.call(elite.health.max_hp == elite.data.max_hp * SURVIVAL.elite_hp_scale, "HPは5倍")
	check.call(is_equal_approx(elite.hurtbox.scale.x, SURVIVAL.elite_visual_scale), "被弾判定は1.5倍")
	elite.position = player.position + Vector2(1000, 0)
	await _frames(0.1)
	check.call(is_instance_valid(elite) and elite.state != Enemy.State.WANDER, "遠くても見失わず消えない")
	var hitbox := Hitbox.new()
	hitbox.power = elite.health.hp
	elite.hurtbox.hurt.emit(hitbox)
	hitbox.free()
	await _frames(1.0 / PHYSICS_FPS)
	var scrolls := arena.get_node("Entities").get_children().filter(
		func(n: Node) -> bool: return n is Scroll
	)
	check.call(scrolls.size() == 1, "倒すと巻物を1つ落とす")
	player.health.damage(3)
	scrolls[0].position = player.position
	await _frames(2.0 / PHYSICS_FPS)
	var menu := arena.get_node("LevelUp")
	check.call(
		_tree.paused and menu.visible and arena.progression.scroll_count == 1, "拾うと止めて巻物の画面を出す"
	)
	check.call(menu._cards.back().upgrade == arena.growth.full_heal, "巻物の末尾は全回復")
	menu.choose(menu._cards.size() - 1)
	check.call(player.health.hp == player.health.max_hp, "全回復でHPが最大に戻る")
	check.call(not _tree.paused and arena.progression.scroll_count == 0, "選ぶと再開する")
	arena.free()
	_tree.paused = false


func _add_test_enemy(world: Node2D, at: Vector2, alerted: bool) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.position = at
	enemy.alerted = alerted
	world.add_child(enemy)
	return enemy


func _test_boss_clears_run(check: Callable) -> void:
	var arena: Node2D = ARENA_SCENE.instantiate()
	arena.survival = SURVIVAL.duplicate()
	arena.survival.clear_time = SHORT_CLEAR_TIME
	_tree.root.add_child(arena)
	await _frames(SHORT_CLEAR_TIME + 0.2)
	check.call(not arena.ended, "残り時間0では終わらない")
	check.call(arena.boss != null, "残り時間0で大鬼が出る")
	check.call(arena.get_node("HUD/BossBar").visible, "大鬼のHPバーを出す")
	check.call(arena.alive_enemies() >= 2, "開始直後から敵が湧く")
	var boss: Enemy = arena.boss
	var hitbox := Hitbox.new()
	hitbox.power = boss.health.hp
	boss.hurtbox.hurt.emit(hitbox)
	hitbox.free()
	check.call(arena.ended, "大鬼を倒すとクリアして終わる")
	check.call(_tree.paused, "終了時は画面を止める")
	check.call(arena.get_node("GameOver").visible, "結果を表示する")
	check.call(RunRecords.load_saved().clears == 1, "クリア回数を記録する")
	arena.free()
	_tree.paused = false


func _frames(seconds: float) -> void:
	for i in roundi(seconds * PHYSICS_FPS):
		await _tree.physics_frame
