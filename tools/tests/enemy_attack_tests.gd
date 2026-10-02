extends RefCounted
## 敵の予告のある攻撃(GameDesign.md 5章「攻撃」):小鬼の抜き打ち・斬って取り消し・青鬼の薙ぎ払い・赤鬼のジャンプ斬り。

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/kooni.tscn")
const KOONI := preload("res://data/enemies/kooni.tres")
const AO_ONI := preload("res://data/enemies/ao_oni.tres")
const AKA_ONI := preload("res://data/enemies/aka_oni.tres")
const PHYSICS_FPS := 60.0
const PLAYER_POS := Vector2(200, 200)
const TOLERANCE := 4.0

var _tree: SceneTree
var _world: Node2D


func run(tree: SceneTree, check: Callable) -> void:
	_tree = tree
	await _test_kooni_draw(check)
	await _test_cut_cancels_attack(check)
	await _test_sweep(check, Vector2(30, 0), true)
	await _test_sweep(check, Vector2(-30, 0), false)
	await _test_sweep(check, Vector2(30, 60), false)
	await _test_sweep(check, Vector2(30, -48), true)
	await _test_jump(check, Vector2.ZERO, true)
	await _test_jump(check, Vector2(0, 40), false)


func _test_kooni_draw(check: Callable) -> void:
	var setup := _spawn(KOONI, PLAYER_POS - Vector2(40, 0))
	var player: Player = setup[0]
	var enemy: Enemy = setup[1]
	await _frames(0.05)
	check.call(enemy.state == Enemy.State.WINDUP, "小鬼は間合いに入ると予告に入る")
	check.call(enemy.aim_direction.is_equal_approx(Vector2.RIGHT), "予告の始めに主人公の方へ向く")
	check.call(player.health.hp == player.health.max_hp, "予告中はダメージが無い")
	await _frames(KOONI.attack_windup)
	check.call(enemy.state == Enemy.State.RUSH, "予告の後に踏み込む")
	await _frames(KOONI.rush_time + 0.05)
	check.call(enemy.state == Enemy.State.RECOVER, "踏み込みの後は隙")
	check.call(player.health.hp == player.health.max_hp - KOONI.attack_damage, "踏み込みが当たる")
	var start := PLAYER_POS - Vector2(40, 0)
	check.call(absf(enemy.position.x - start.x - KOONI.rush_distance) < TOLERANCE, "踏み込む距離だけ進む")
	await _frames(KOONI.attack_recover + 0.05)
	var held := enemy.position
	await _frames(0.2)
	check.call(enemy.position == held, "間合いの内では立ち止まって次の攻撃を待つ")
	_clear()


func _test_cut_cancels_attack(check: Callable) -> void:
	var setup := _spawn(KOONI, PLAYER_POS - Vector2(40, 0))
	var player: Player = setup[0]
	var enemy: Enemy = setup[1]
	await _frames(0.1)
	var hitbox := Hitbox.new()
	hitbox.power = 1
	hitbox.direction = Vector2.LEFT
	enemy.hurtbox.hurt.emit(hitbox)
	hitbox.free()
	check.call(enemy.state == Enemy.State.HURT, "予告中に斬られると被弾硬直に入る")
	await _frames(KOONI.attack_windup + KOONI.rush_time)
	check.call(player.health.hp == player.health.max_hp, "斬られた攻撃は取り消される")
	_clear()


func _test_sweep(check: Callable, player_offset: Vector2, hits: bool) -> void:
	var setup := _spawn(AO_ONI, PLAYER_POS - Vector2(30, 0))
	var player: Player = setup[0]
	var enemy: Enemy = setup[1]
	await _frames(0.05)
	check.call(enemy.state == Enemy.State.WINDUP, "青鬼は間合いに入ると薙ぎ払いの予告に入る")
	player.position = enemy.position + player_offset
	await _frames(AO_ONI.attack_windup + AO_ONI.strike_time)
	check.call(enemy.state == Enemy.State.RECOVER, "薙ぎ払いの後は隙")
	var expected := player.health.max_hp - (AO_ONI.attack_damage if hits else 0)
	var label := "正面の半円に当たる" if hits else "背後には当たらない"
	check.call(player.health.hp == expected, "%s (hp=%d)" % [label, player.health.hp])
	_clear()


func _test_jump(check: Callable, player_move: Vector2, hits: bool) -> void:
	var setup := _spawn(AKA_ONI, PLAYER_POS - Vector2(80, 0))
	var player: Player = setup[0]
	var enemy: Enemy = setup[1]
	await _frames(0.05)
	check.call(enemy.state == Enemy.State.WINDUP, "赤鬼は間合いに入るとジャンプ斬りの予告に入る")
	check.call(enemy.jump_target == PLAYER_POS, "着地点は予告の始めの主人公の位置")
	player.position += player_move
	await _frames(AKA_ONI.attack_windup + AKA_ONI.jump_time / 2)
	check.call(enemy.state == Enemy.State.JUMP and enemy.hurtbox.invincible, "跳んでいる間は斬れない")
	check.call(enemy.air_height() > 0.0, "跳んでいる間は高く見える")
	await _frames(AKA_ONI.jump_time / 2 + AKA_ONI.strike_time)
	check.call(enemy.position.distance_to(PLAYER_POS) < TOLERANCE, "着地点へ降りる")
	var expected := player.health.max_hp - (AKA_ONI.attack_damage if hits else 0)
	var label := "着地点の円に当たる" if hits else "円から出れば当たらない"
	check.call(player.health.hp == expected, "%s (hp=%d)" % [label, player.health.hp])
	_clear()


## 主人公を PLAYER_POS に置き(操作は止める)、気づいた状態の敵を at に置く
func _spawn(data: EnemyData, at: Vector2) -> Array:
	_world = Node2D.new()
	_tree.root.add_child(_world)
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = PLAYER_POS
	player.set_physics_process(false)
	_world.add_child(player)
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = data
	enemy.alerted = true
	enemy.position = at
	_world.add_child(enemy)
	return [player, enemy]


func _clear() -> void:
	_world.free()
	Engine.time_scale = 1.0


func _frames(seconds: float) -> void:
	for i in roundi(seconds * PHYSICS_FPS):
		await _tree.physics_frame
