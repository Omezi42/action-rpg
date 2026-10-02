extends RefCounted
## 経験値の曲線・カードの選び方・強化の反映・魂の取得・レベルアップで止まることを確かめる(GameDesign.md 8章)。

const GROWTH := preload("res://data/growth.tres")
const IAI := preload("res://data/iai.tres")
const HAYANUKI := preload("res://data/upgrades/hayanuki.tres")
const GOUBA := preload("res://data/upgrades/gouba.tres")
const GANKEN := preload("res://data/upgrades/ganken.tres")
const FUKABUMI := preload("res://data/upgrades/fukabumi.tres")
const ZANKON := preload("res://data/upgrades/zankon.tres")
const ZANSHIN := preload("res://data/upgrades/zanshin.tres")
const TSUBAME := preload("res://data/upgrades/tsubame.tres")
const KAGENUI := preload("res://data/upgrades/kagenui.tres")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const SOUL_SCENE := preload("res://scenes/pickups/soul_field.tscn")
const ARENA_SCENE := preload("res://scenes/stage/arena.tscn")
const PHYSICS_FPS := 60.0

var _tree: SceneTree


func run(tree: SceneTree, check: Callable) -> void:
	_tree = tree
	_test_exp_curve(check)
	_test_choices(check)
	_test_charge_scale(check)
	_test_scroll_choices(check)
	await _test_take(check)
	await _test_soul_pickup(check)
	await _test_level_up_pauses(check)


func _test_exp_curve(check: Callable) -> void:
	var p := Progression.new(GROWTH)
	check.call(p.level == 1 and p.exp_to_next() == 5, "レベル1は経験値5で上がる")
	p.add_exp(5)
	check.call(p.level == 2 and p.pending == 1 and p.exp_to_next() == 7, "次は7")
	p.add_exp(20)
	check.call(p.level == 4 and p.pending == 3 and p.experience == 4, "一度に複数上がる")


func _test_choices(check: Callable) -> void:
	var p := Progression.new(GROWTH)
	var choices := p.roll_choices()
	var distinct := {}
	for c in choices:
		distinct[c] = true
	check.call(choices.size() == 3 and distinct.size() == 3, "重ならない3枚")
	var upgrades: Array = GROWTH.upgrades
	for upgrade: Variant in upgrades:
		for i in upgrade.max_level:
			p._levels[upgrade] = p.level_of(upgrade) + 1
	check.call(p.roll_choices() == [GROWTH.heal], "すべて最大なら回復だけ")


## 巻物の3枚:奥義を先に、残りを挙動の強化から、末尾に全回復(GameDesign.md 8章)
func _test_scroll_choices(check: Callable) -> void:
	var p := Progression.new(GROWTH)
	var choices := p.roll_scroll()
	check.call(choices.size() == 3 and choices.back() == GROWTH.full_heal, "巻物は3枚で末尾が全回復")
	var behaviors := choices.slice(0, 2).filter(
		func(u: UpgradeData) -> bool: return u.kind == UpgradeData.Kind.BEHAVIOR
	)
	check.call(behaviors.size() == 2, "残りは挙動の強化から")
	var data: GrowthData = GROWTH.duplicate()
	var ougi := UpgradeData.new()
	ougi.kind = UpgradeData.Kind.OUGI
	ougi.max_level = 1
	ougi.requires.append(ZANKON)
	ougi.requires.append(GOUBA)
	data.ougi = [ougi]
	p = Progression.new(data)
	p._levels[ZANKON] = ZANKON.max_level
	check.call(not ougi in p.roll_scroll(), "条件が揃うまで奥義は出ない")
	check.call(not ZANKON in p.roll_scroll(), "最大の挙動の強化は出ない")
	p._levels[GOUBA] = GOUBA.max_level
	check.call(p.roll_scroll()[0] == ougi, "条件が揃った奥義を先に出す")
	check.call(not ougi in p.roll_choices(), "奥義はレベルアップに出ない")
	p._levels[ougi] = 1
	check.call(not ougi in p.roll_scroll(), "取った奥義は出ない")
	p._levels[ZANSHIN] = ZANSHIN.max_level
	p._levels[TSUBAME] = TSUBAME.max_level
	p._levels[KAGENUI] = KAGENUI.max_level
	check.call(p.roll_scroll() == [data.full_heal], "候補が無ければ全回復だけ")


func _test_charge_scale(check: Callable) -> void:
	var stats := PlayerStats.new()
	stats.charge_time_scale = 0.5
	var charge := IaiCharge.new(IAI, stats)
	charge.advance(0.5)
	check.call(charge.stage_index() == 3, "早抜きで参に届く時間が縮む")
	check.call(charge.is_issen_window(), "縮んだ参の直後が一閃の受付")


func _test_take(check: Callable) -> void:
	var player: Player = PLAYER_SCENE.instantiate()
	_tree.root.add_child(player)
	player.set_physics_process(false)
	var p := Progression.new(GROWTH)
	p.pending = 1
	p.take(GOUBA, player)
	check.call(p.pending == 0 and p.level_of(GOUBA) == 1, "取ると段階が上がり選び待ちが減る")
	check.call(player.strike_power(IAI.stages[0]) == IAI.stages[0].power, "剛刃は抜き打ちに乗らない")
	check.call(player.strike_power(IAI.stages[1]) == IAI.stages[1].power + 1, "剛刃は壱に+1")
	check.call(player.strike_power(IAI.issen) == IAI.issen.power + 1, "剛刃は一閃にも+1")
	p.take(FUKABUMI, player)
	check.call(is_equal_approx(player.strike_distance(IAI.stages[3]), 160.0 * 1.12), "深踏みで+12%")
	player.health.damage(2)
	p.take(GANKEN, player)
	check.call(player.health.max_hp == 7 and player.health.hp == 5, "頑健は最大HP+1で1回復")
	p.take(TSUBAME, player)
	p.take(TSUBAME, player)
	check.call(is_equal_approx(player.return_distance(), 64.0), "燕返しは1段32px")
	p.take(KAGENUI, player)
	check.call(is_equal_approx(player.stats.bind_time, 1.0), "影縫いの1段目は1.0秒")
	p.take(KAGENUI, player)
	check.call(is_equal_approx(player.stats.bind_time, 1.4), "影縫いの2段目から+0.4秒")
	player.free()


func _test_soul_pickup(check: Callable) -> void:
	var world := Node2D.new()
	_tree.root.add_child(world)
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = Vector2(100, 100)
	world.add_child(player)
	player.set_physics_process(false)
	var souls: SoulField = SOUL_SCENE.instantiate()
	souls.player = player
	world.add_child(souls)
	var got := [0]
	souls.collected.connect(func(v: int) -> void: got[0] += v)
	souls.drop(Vector2(120, 100), 1)
	souls.drop(Vector2(160, 100), 3)
	await _frames(0.3)
	check.call(got[0] == 1 and souls.count() == 1, "半径内の魂は吸い寄せて拾い、遠い魂は残る")
	player.state = Player.State.DASH
	player.position = Vector2(140, 100)
	await _frames(1.0 / PHYSICS_FPS * 2)
	check.call(got[0] == 4 and souls.count() == 0, "踏み込み中は半径内をその場で拾う")
	player.state = Player.State.MOVE
	player.position = Vector2(400, 400)
	for i in GROWTH.max_souls + 1:
		souls.drop(Vector2(10, 10), 1)
	check.call(souls.count() == GROWTH.max_souls and got[0] == 5, "上限を超えた古い魂は拾ったことにする")
	world.free()


func _test_level_up_pauses(check: Callable) -> void:
	var arena: Node2D = ARENA_SCENE.instantiate()
	_tree.root.add_child(arena)
	await _frames(0.1)
	var menu := arena.get_node("LevelUp")
	arena._on_soul_collected(GROWTH.exp_base)
	check.call(_tree.paused and menu.visible, "レベルアップで止まってカードを出す")
	check.call(menu.is_locked(), "開いた直後は選べない")
	menu.choose(0)
	check.call(not _tree.paused and not menu.visible, "選ぶと再開する")
	check.call(arena.progression.level == 2 and arena.progression.pending == 0, "レベル2で選び待ちなし")
	arena.free()
	_tree.paused = false


func _frames(seconds: float) -> void:
	for i in maxi(roundi(seconds * PHYSICS_FPS), 1):
		await _tree.physics_frame
