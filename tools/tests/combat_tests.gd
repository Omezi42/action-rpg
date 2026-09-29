extends RefCounted
## 実際のシーンで居合を出し、敵へのダメージ・一閃の遅延撃破・被弾を確かめる。

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/kooni.tscn")
const PHYSICS_FPS := 60.0

var _tree: SceneTree
var _world: Node2D


func run(tree: SceneTree, check: Callable) -> void:
	_tree = tree
	await _test_ichi_damages_once(check)
	await _test_issen_kills_on_sheathe(check)
	await _test_contact_hurts_player(check)


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


func _test_contact_hurts_player(check: Callable) -> void:
	var setup := _spawn(Vector2(100, 100))
	var player: Player = setup[0]
	await _frames(0.1)
	check.call(player.health.hp == 5, "接触で1ダメージ (hp=%d)" % player.health.hp)
	check.call(player.invincible_left > 0.0, "被弾後は無敵")
	await _frames(0.2)
	check.call(player.health.hp == 5, "無敵中は重ねて被弾しない")
	_clear()


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
