extends RefCounted
## 盾鬼(GameDesign.md 5章「盾」):正面からの踏み込みを弾き、背後・横・一閃・燕返し・弾かれない当たりは通る。振り向きの速さ。

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/kooni.tscn")
const TATE_ONI := preload("res://data/enemies/tate_oni.tres")
const PHYSICS_FPS := 60.0
const TURN_TOLERANCE := 0.1

var _tree: SceneTree
var _world: Node2D


func run(tree: SceneTree, check: Callable) -> void:
	_tree = tree
	await _test_front_blocks(check)
	await _test_back_and_side_hit(check, Vector2.RIGHT, "背後")
	await _test_back_and_side_hit(check, Vector2.UP, "横")
	await _test_issen_breaks_through(check)
	await _test_return_hits_back(check)
	await _test_turn_speed(check)
	_test_unguardable(check)


func _test_front_blocks(check: Callable) -> void:
	var setup := _spawn(Vector2(130, 100), Vector2.LEFT)
	var player: Player = setup[0]
	var enemy: Enemy = setup[1]
	var guarded := [0]
	var landed := [0]
	enemy.guarded.connect(func(_at: Vector2) -> void: guarded[0] += 1)
	player.hit_landed.connect(func(_at: Vector2) -> void: landed[0] += 1)
	await _hold_iai(0.3)
	await _frames(0.2)
	check.call(enemy.health.hp == TATE_ONI.max_hp, "正面からの壱は盾で弾く (hp=%d)" % enemy.health.hp)
	check.call(guarded[0] == 1, "弾いたら1度だけ guarded を出す (n=%d)" % guarded[0])
	check.call(landed[0] == 0, "弾いた当たりは斬撃にならない(ヒットストップも無い)")
	check.call(player.global_position.x > 140, "弾かれても踏み込みは通り抜ける")
	_clear()


func _test_back_and_side_hit(check: Callable, shield: Vector2, label: String) -> void:
	var setup := _spawn(Vector2(130, 100), shield)
	var enemy: Enemy = setup[1]
	await _hold_iai(0.3)
	await _frames(0.2)
	check.call(enemy.health.hp < TATE_ONI.max_hp, "%sからの壱は当たる (hp=%d)" % [label, enemy.health.hp])
	_clear()


func _test_issen_breaks_through(check: Callable) -> void:
	var setup := _spawn(Vector2(180, 100), Vector2.LEFT)
	var enemy: Enemy = setup[1]
	await _hold_iai(1.05)
	await _frames(0.3)
	check.call(is_instance_valid(enemy) and enemy.is_doomed(), "一閃は正面から盾ごと斬る")
	_clear()


func _test_return_hits_back(check: Callable) -> void:
	var setup := _spawn(Vector2(130, 100), Vector2.LEFT)
	var player: Player = setup[0]
	var enemy: Enemy = setup[1]
	player.stats.return_distance = 64.0
	await _hold_iai(0.3)
	await _wait_state(player, Player.State.SHEATHE)
	check.call(enemy.health.hp == TATE_ONI.max_hp, "正面からの踏み込みは弾く")
	Input.action_press("iai")
	await _wait_state(player, Player.State.SHEATHE)
	check.call(
		not is_instance_valid(enemy) or enemy.health.hp < TATE_ONI.max_hp, "背後へ抜けた後の燕返しは盾の裏から当たる"
	)
	_clear()


func _test_turn_speed(check: Callable) -> void:
	var setup := _spawn(Vector2(100, 100), Vector2.LEFT, Vector2(200, 100))
	var player: Player = setup[0]
	var enemy: Enemy = setup[1]
	player.set_physics_process(false)
	enemy.set_physics_process(true)
	var seconds := 0.5
	await _frames(seconds)
	var turned := absf(Vector2.LEFT.angle_to(enemy.shield_facing))
	var expected := TATE_ONI.shield_turn_speed * seconds
	check.call(
		absf(turned - expected) < TURN_TOLERANCE,
		"盾は決まった速さで振り向く (%.2f / %.2f rad)" % [turned, expected]
	)
	_clear()


func _test_unguardable(check: Callable) -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = TATE_ONI
	enemy.shield_facing = Vector2.LEFT
	var hitbox := Hitbox.new()
	hitbox.direction = Vector2.RIGHT
	check.call(not enemy.blocks(hitbox), "斬痕・残心のように弾かれない当たりは正面でも通る")
	hitbox.guardable = true
	check.call(enemy.blocks(hitbox), "弾かれうる当たりは正面なら弾く")
	hitbox.free()
	enemy.free()


func _wait_state(player: Player, state: Player.State) -> void:
	for i in roundi(PHYSICS_FPS):
		await _tree.physics_frame
		if player.state == state:
			return


## プレイヤーを player_pos に右向きで置き、盾鬼を enemy_pos に置いて盾の向きを決める。敵のAIは止める
func _spawn(enemy_pos: Vector2, shield: Vector2, player_pos := Vector2(100, 100)) -> Array:
	_world = Node2D.new()
	_tree.root.add_child(_world)
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = player_pos
	_world.add_child(player)
	player.facing = Vector2.RIGHT
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = TATE_ONI
	enemy.alerted = true
	enemy.position = enemy_pos
	_world.add_child(enemy)
	enemy.shield_facing = shield
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
