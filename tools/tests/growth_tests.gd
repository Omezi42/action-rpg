extends RefCounted
## 経験値・レベルアップ・3択・強化の反映・玉の回収・斬痕を確かめる(GameDesign.md 8章)。

const GROWTH := preload("res://data/growth.tres")
const TOGI := preload("res://data/upgrades/togi.tres")
const HAYANUKI := preload("res://data/upgrades/hayanuki.tres")
const TOOMA := preload("res://data/upgrades/tooma.tres")
const HEAL := preload("res://data/heal_upgrade.tres")
const IAI := preload("res://data/iai.tres")
const ARENA_SCENE := preload("res://scenes/stage/arena.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/kooni.tscn")
const UPGRADE_COUNT := 7
const PHYSICS_FPS := 60.0

var _tree: SceneTree


func run(tree: SceneTree, check: Callable) -> void:
	_tree = tree
	_test_level_curve(check)
	_test_choices(check)
	_test_stats(check)
	_test_charge_scale(check)
	await _test_orb_collected_during_dash(check)
	await _test_togi_kills_with_ichi(check)
	await _test_lingering_slash(check)
	await _test_level_up_menu(check)


func _test_level_curve(check: Callable) -> void:
	var growth := Growth.new(GROWTH, [])
	check.call(growth.xp_to_next() == 5, "Lv1→2 は5点")
	check.call(growth.add_xp(4) == 0, "4点ではまだ上がらない")
	check.call(growth.add_xp(8) == 1 and growth.level == 2, "12点で Lv2")
	check.call(growth.xp == 7 and growth.xp_to_next() == 8, "余りは持ち越し、次は8点")
	check.call(growth.add_xp(12) == 2 and growth.pending == 3, "一度に2つ上がり、未選択が積もる")


func _test_choices(check: Callable) -> void:
	var pool := Growth.load_pool(GROWTH.upgrade_dir)
	check.call(pool.size() == UPGRADE_COUNT, "data/upgrades の強化 %d 種を集める" % pool.size())
	var growth := Growth.new(GROWTH, pool)
	var choices := growth.roll_choices()
	var unique := {}
	for c in choices:
		unique[c] = true
	check.call(choices.size() == 3 and unique.size() == 3, "3択は重複なし")
	check.call(not choices.has(HEAL), "候補が足りていれば手当は出ない")
	var small := Growth.new(GROWTH, [TOGI, TOOMA])
	for i in TOOMA.max_level:
		small.take(TOOMA)
	var few := small.roll_choices()
	check.call(few.size() == 2 and few[0] == TOGI and few[1] == HEAL, "上限の強化は外れ、足りない分は手当1枚")
	small.take(HEAL)
	check.call(small.level_of(HEAL) == 0, "手当は段を持たない")


func _test_stats(check: Callable) -> void:
	var stats := PlayerStats.new()
	stats.apply(TOGI)
	stats.apply(TOGI)
	check.call(stats.value(PlayerStats.POWER_BONUS) == 2.0, "研ぎ2段で威力+2")
	stats.apply(HAYANUKI)
	stats.apply(HAYANUKI)
	check.call(is_equal_approx(stats.value(PlayerStats.HOLD_SCALE), 0.85 * 0.85), "早抜きは掛け算で重なる")
	stats.apply(TOOMA)
	stats.apply(TOOMA)
	check.call(is_equal_approx(stats.value(PlayerStats.DISTANCE_SCALE), 1.4), "遠間は足し算で +40%")


func _test_charge_scale(check: Callable) -> void:
	var charge := IaiCharge.new(IAI)
	charge.hold_scale = 0.5
	charge.window_bonus = 0.1
	charge.advance(0.5)
	check.call(charge.stage_index() == charge.top_stage_index(), "到達時間が半分なら0.5秒で参")
	charge.advance(0.2)
	check.call(charge.is_issen_window(), "受付が伸びていれば参から0.2秒でも一閃")


func _test_orb_collected_during_dash(check: Callable) -> void:
	var world := _world()
	var player := _player(world)
	var orb := XpOrb.new()
	orb.setup(3, GROWTH)
	orb.position = Vector2(180, 100)
	world.add_child(orb)
	var got := [0]
	orb.collected.connect(func(v: int) -> void: got[0] += v)
	await _frames(0.1)
	check.call(got[0] == 0, "範囲外の玉は動かない")
	await _hold_iai(0.6)
	await _frames(0.4)
	check.call(got[0] == 3, "踏み込みの通り道の玉を回収する")
	check.call(player.global_position.x > 180, "玉を越えて踏み込んでいる")
	_clear(world)


func _test_togi_kills_with_ichi(check: Callable) -> void:
	var world := _world()
	var player := _player(world)
	player.apply_upgrade(TOGI)
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.position = Vector2(130, 100)
	world.add_child(enemy)
	enemy.set_physics_process(false)
	await _hold_iai(0.3)
	await _frames(0.2)
	check.call(not is_instance_valid(enemy), "研ぎ1段なら壱(威力3)で小鬼を倒す")
	_clear(world)


func _test_lingering_slash(check: Callable) -> void:
	var world := _world()
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.position = Vector2(150, 100)
	world.add_child(enemy)
	enemy.set_physics_process(false)
	var slash := LingeringSlash.new()
	slash.setup(
		Vector2(100, 100), Vector2(200, 100), GROWTH.lingering_power, GROWTH.lingering_base_time
	)
	world.add_child(slash)
	await _frames(0.3)
	check.call(enemy.health.hp == enemy.data.max_hp - 1, "斬痕は触れた敵に1度だけ威力1")
	await _frames(0.4)
	check.call(not is_instance_valid(slash), "斬痕は時間で消える")
	world.free()


func _test_level_up_menu(check: Callable) -> void:
	var arena: Node2D = ARENA_SCENE.instantiate()
	_tree.root.add_child(arena)
	await _tree.physics_frame
	var run_growth: RunGrowth = arena.get_node("Growth")
	var menu = arena.get_node("HUD/UpgradeMenu")
	var player: Player = arena.get_node("Entities/Player")
	run_growth.add_xp(GROWTH.xp_base)
	check.call(_tree.paused and menu.visible, "レベルアップで止めて3択を出す")
	var first: UpgradeData = run_growth.growth.roll_choices()[0]
	var choices: Array[UpgradeData] = [first]
	var levels: Array[int] = [0]
	menu.open(choices, levels, 0.0)
	menu.choose(0)
	check.call(not _tree.paused and not menu.visible, "選んだら再開する")
	check.call(run_growth.growth.level_of(first) == 1, "選んだ強化が1段上がる")
	var before := player.stats.value(first.stat)
	check.call(before != PlayerStats.BASE[first.stat], "主人公の能力値に反映される")
	arena.free()
	_tree.paused = false


func _world() -> Node2D:
	var world := Node2D.new()
	_tree.root.add_child(world)
	return world


## (100,100) に右向きで置く
func _player(world: Node2D) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = Vector2(100, 100)
	world.add_child(player)
	player.facing = Vector2.RIGHT
	return player


func _clear(world: Node2D) -> void:
	Input.action_release("iai")
	world.free()
	Engine.time_scale = 1.0


func _hold_iai(seconds: float) -> void:
	Input.action_press("iai")
	await _frames(seconds)
	Input.action_release("iai")


func _frames(seconds: float) -> void:
	for i in roundi(seconds * PHYSICS_FPS):
		await _tree.physics_frame
