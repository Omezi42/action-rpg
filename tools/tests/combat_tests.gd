extends RefCounted
## 実際のシーンで居合を出し、敵へのダメージ・一閃の遅延撃破・被弾・斬痕と残心を確かめる。

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/kooni.tscn")
const PHYSICS_FPS := 60.0

var _tree: SceneTree
var _world: Node2D


func run(tree: SceneTree, check: Callable) -> void:
	_tree = tree
	await _test_charge_roots_player(check)
	await _test_ichi_damages_once(check)
	await _test_issen_kills_on_sheathe(check)
	await _test_contact_is_harmless(check)
	await _test_shockwave(check)
	await _test_lingering_slash(check)
	await _test_hitokiri(check)
	await _test_return_slash(check)
	await _test_return_limits(check)
	await _test_homura(check)
	await _test_daizanshin(check)
	await _test_tsubame_kiwami(check)
	await _test_kage_kiwami(check)
	_test_hitokiri_outside_strike(check)


func _test_charge_roots_player(check: Callable) -> void:
	var setup := _spawn(Vector2(300, 300))
	var player: Player = setup[0]
	Input.action_press("iai")
	await _frames(0.05)
	Input.action_press("move_down")
	await _frames(0.2)
	check.call(player.global_position == Vector2(100, 100), "構え中は移動しない")
	check.call(player.facing.is_equal_approx(Vector2.DOWN), "構え中も向きは変えられる")
	Input.action_release("move_down")
	_clear()


func _test_ichi_damages_once(check: Callable) -> void:
	var setup := _spawn(Vector2(130, 100))
	var player: Player = setup[0]
	var enemy: Enemy = setup[1]
	await _hold_iai(0.3)
	await _frames(0.2)
	check.call(enemy.health.hp == 1, "壱(威力2)で小鬼のHPは3→1 (hp=%d)" % enemy.health.hp)
	check.call(player.global_position.x > 140, "壱の踏み込みで敵を通り抜ける")
	_clear()


func _test_issen_kills_on_sheathe(check: Callable) -> void:
	var setup := _spawn(Vector2(180, 100))
	var player: Player = setup[0]
	var enemy: Enemy = setup[1]
	await _hold_iai(1.05)
	await _frames(0.3)
	check.call(is_instance_valid(enemy) and enemy.is_doomed(), "一閃で斬った敵は納刀まで残る")
	check.call(player.state == Player.State.SHEATHE, "踏み込み後は納刀中")
	await _frames(0.25)
	check.call(not is_instance_valid(enemy), "納刀の瞬間に倒れて消える")
	_clear()


func _test_contact_is_harmless(check: Callable) -> void:
	var setup := _spawn(Vector2(100, 100))
	var player: Player = setup[0]
	await _frames(0.2)
	check.call(player.health.hp == player.health.max_hp, "敵に触れてもダメージは無い")
	_clear()


func _test_shockwave(check: Callable) -> void:
	var setup := _spawn(Vector2(148, 125))
	var player: Player = setup[0]
	var enemy: Enemy = setup[1]
	player.stats.shockwave_radius = 32.0
	await _hold_iai(0.3)
	await _frames(0.2)
	check.call(enemy.health.hp == 1, "残心の衝撃波が止まった位置の周りに当たる (hp=%d)" % enemy.health.hp)
	_clear()


func _test_lingering_slash(check: Callable) -> void:
	var setup := _spawn(Vector2(300, 300))
	var player: Player = setup[0]
	var enemy: Enemy = setup[1]
	player.stats.linger_time = 0.5
	await _hold_iai(0.3)
	await _frames(0.15)
	enemy.position = Vector2(124, 100)
	await _frames(0.1)
	check.call(enemy.health.hp == 2, "斬痕が斬り抜けた線に残って当たる (hp=%d)" % enemy.health.hp)
	await _frames(0.2)
	check.call(enemy.health.hp == 2, "斬痕は同じ敵に1度だけ")
	_clear()


## 一閃で並んだ3体を斬ると、納刀の終わりに3人斬りと数える(GameDesign.md 3章)
func _test_hitokiri(check: Callable) -> void:
	var setup := _spawn(Vector2(130, 100))
	var player: Player = setup[0]
	var counter := HitokiriCounter.new()
	var enemies: Array[Enemy] = [setup[1]]
	for x in [160, 190]:
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.position = Vector2(x, 100)
		_world.add_child(enemy)
		enemy.set_physics_process(false)
		enemies.append(enemy)
	for enemy in enemies:
		enemy.defeated.connect(counter.add_kill.unbind(1))
	var result := [-1, false]
	player.strike_started.connect(counter.start)
	player.strike_finished.connect(
		func(is_issen: bool) -> void:
			result[0] = counter.finish()
			result[1] = is_issen
	)
	await _hold_iai(1.05)
	await _frames(0.3)
	check.call(result[0] == -1, "納刀が終わるまでは数え終えない")
	await _frames(0.4)
	check.call(result[0] == 3 and result[1], "一閃で3体を斬ると3人斬り (n=%d)" % result[0])
	check.call(counter.best == 3, "最多人斬りを覚える")
	_clear()


func _test_hitokiri_outside_strike(check: Callable) -> void:
	var counter := HitokiriCounter.new()
	counter.add_kill()
	counter.start()
	counter.add_kill()
	check.call(counter.finish() == 1, "踏み込みの外で倒れた敵は数えない")
	counter.add_kill()
	counter.start()
	check.call(counter.finish() == 0 and counter.best == 1, "数え直しは0から")


## 燕返し:壱で斬った敵を斬り返しでもう一度斬る。斬痕は1本だけ・人斬りの区切りは1回(GameDesign.md 8章)
func _test_return_slash(check: Callable) -> void:
	var setup := _spawn(Vector2(130, 100))
	var player: Player = setup[0]
	var enemy: Enemy = setup[1]
	player.stats.return_distance = 64.0
	player.stats.linger_time = 1.0
	var finished := [0]
	player.strike_finished.connect(func(_is_issen: bool) -> void: finished[0] += 1)
	await _hold_iai(0.3)
	await _wait_state(player, Player.State.SHEATHE)
	var stop_x := player.global_position.x
	Input.action_press("iai")
	await _wait_state(player, Player.State.SHEATHE)
	check.call(not is_instance_valid(enemy), "斬り返しで壱の残りHPを斬る")
	check.call(player.global_position.x < stop_x - 60, "来た方向へ斬り返す")
	check.call(_count_lingering() == 1, "斬り返しでは斬痕を出さない (n=%d)" % _count_lingering())
	await _frames(0.3)
	check.call(finished[0] == 1, "斬り返しを挟んでも1回の踏み込み (n=%d)" % finished[0])
	check.call(player.state == Player.State.CHARGE, "押したまま納刀が終わると構えに入る")
	_clear()


func _test_return_limits(check: Callable) -> void:
	var setup := _spawn(Vector2(300, 300))
	var player: Player = setup[0]
	player.stats.return_distance = 64.0
	await _hold_iai(0.05)
	await _wait_state(player, Player.State.SHEATHE)
	Input.action_press("iai")
	await _frames(0.05)
	check.call(player.state != Player.State.RETURN, "抜き打ちからは返せない")
	Input.action_release("iai")
	await _frames(0.3)
	await _hold_iai(0.3)
	await _wait_state(player, Player.State.SHEATHE)
	await _frames(0.3)
	Input.action_press("iai")
	await _frames(0.02)
	check.call(player.state == Player.State.CHARGE, "納刀が終わった後に押すと構えになる")
	Input.action_release("iai")
	await _frames(0.3)
	await _hold_iai(0.3)
	await _wait_state(player, Player.State.SHEATHE)
	Input.action_press("iai")
	await _wait_state(player, Player.State.SHEATHE)
	Input.action_release("iai")
	await _frames(0.02)
	Input.action_press("iai")
	await _frames(0.02)
	check.call(player.state == Player.State.SHEATHE, "斬り返しからは返せない")
	_clear()


## 奥義(GameDesign.md 8章)
func _test_homura(check: Callable) -> void:
	var setup := _spawn(Vector2(300, 300))
	var player: Player = setup[0]
	var enemy: Enemy = setup[1]
	player.stats.linger_time = 0.5
	player.stats.ougi_homura = true
	await _hold_iai(0.3)
	await _frames(0.15)
	enemy.position = Vector2(124, 100)
	await _frames(0.1)
	check.call(enemy.health.hp == 1, "焔痕は斬痕の威力2 (hp=%d)" % enemy.health.hp)
	await _frames(0.5)
	check.call(_count_lingering() == 1, "焔痕は斬痕が2倍の時間残る")
	_clear()


func _test_daizanshin(check: Callable) -> void:
	var setup := _spawn(Vector2(148, 125))
	var player: Player = setup[0]
	var enemy: Enemy = setup[1]
	player.stats.shockwave_radius = 32.0
	player.stats.ougi_daizanshin = true
	await _hold_iai(0.3)
	await _frames(0.2)
	check.call(enemy.health.hp == 1, "大残心の1回目")
	await _frames(0.3)
	check.call(not is_instance_valid(enemy), "大残心は0.3秒後にもう1回当たる")
	_clear()


func _test_tsubame_kiwami(check: Callable) -> void:
	var setup := _spawn(Vector2(300, 300))
	var player: Player = setup[0]
	player.stats.return_distance = 32.0
	player.stats.ougi_tsubame = true
	await _hold_iai(0.3)
	await _wait_state(player, Player.State.SHEATHE)
	Input.action_press("iai")
	await _wait_state(player, Player.State.RETURN)
	await _wait_state(player, Player.State.SHEATHE)
	var x := player.global_position.x
	check.call(absf(x - 100.0) < 1.0, "燕返し・極は踏み込みと同じ距離を返す (x=%.1f)" % x)
	_clear()


func _test_kage_kiwami(check: Callable) -> void:
	var setup := _spawn(Vector2(140, 113))
	var player: Player = setup[0]
	var near: Enemy = setup[1]
	var far: Enemy = ENEMY_SCENE.instantiate()
	far.position = Vector2(140, 140)
	_world.add_child(far)
	far.set_physics_process(false)
	player.stats.bind_time = 1.0
	player.stats.ougi_kage = true
	await _hold_iai(0.3)
	await _wait_state(player, Player.State.SHEATHE)
	check.call(near.bound and near.state == Enemy.State.HURT, "影縫い・極は線の左右16px以内を止める")
	check.call(not far.bound, "線から離れた敵は止めない")
	_clear()


func _count_lingering() -> int:
	return _world.get_children().filter(func(n: Node) -> bool: return n is LingeringSlash).size()


func _wait_state(player: Player, state: Player.State) -> void:
	for i in roundi(PHYSICS_FPS):
		await _tree.physics_frame
		if player.state == state:
			return


## プレイヤーを (100,100) に右向きで置き、敵を enemy_pos に置く。敵のAIは止める
func _spawn(enemy_pos: Vector2) -> Array:
	_world = Node2D.new()
	_tree.root.add_child(_world)
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = Vector2(100, 100)
	_world.add_child(player)
	player.facing = Vector2.RIGHT
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.position = enemy_pos
	_world.add_child(enemy)
	enemy.set_physics_process(false)
	return [player, enemy]


func _clear() -> void:
	Input.action_release("iai")
	_world.free()
	Engine.time_scale = 1.0


func _hold_iai(seconds: float) -> void:
	Input.action_press("iai")
	await _frames(seconds)
	Input.action_release("iai")


func _frames(seconds: float) -> void:
	for i in roundi(seconds * PHYSICS_FPS):
		await _tree.physics_frame
