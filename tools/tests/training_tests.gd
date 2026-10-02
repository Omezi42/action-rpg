extends RefCounted
## 武功・修行の売り買いと反映・引き直し・封じを確かめる(GameDesign.md 8章「修行」)。

const GROWTH := preload("res://data/growth.tres")
const TRAINING := preload("res://data/training.tres")
const KARADA := preload("res://data/training/karada.tres")
const ASHI := preload("res://data/training/ashi.tres")
const HIKINAOSHI := preload("res://data/training/hikinaoshi.tres")
const FUJI := preload("res://data/training/fuji.tres")
const ZANKON := preload("res://data/upgrades/zankon.tres")
const ARENA_SCENE := preload("res://scenes/stage/arena.tscn")
const TITLE_SCENE := preload("res://scenes/ui/title.tscn")

var _tree: SceneTree


func run(tree: SceneTree, check: Callable) -> void:
	_tree = tree
	_reset()
	_test_reward(check)
	_test_buy_and_refund(check)
	_test_seal(check)
	_test_replace(check)
	await _test_arena_applies(check)
	await _test_arena_reroll_and_seal(check)
	_test_title_menu(check)
	_reset()


func _reset() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TrainingProgress.path))


func _test_reward(check: Callable) -> void:
	check.call(TRAINING.reward(25, 7, false) == 9, "武功は撃破÷10+到達レベル")
	check.call(TRAINING.reward(25, 7, true) == 39, "クリアで+30")


func _test_buy_and_refund(check: Callable) -> void:
	var progress := TrainingProgress.new()
	progress.merit = 69
	check.call(progress.buy(KARADA) and progress.merit == 49, "1段目は20武功")
	check.call(not progress.buy(KARADA), "足りなければ買えない")
	progress.merit += 151
	check.call(progress.buy(KARADA) and progress.buy(KARADA), "2・3段目を買う")
	check.call(progress.next_cost(KARADA) == -1 and not progress.buy(KARADA), "3段で最大")
	var saved := TrainingProgress.load_saved()
	check.call(saved.level_of(KARADA) == 3 and saved.merit == 50, "買うと保存する")
	saved.refund_all(TRAINING)
	check.call(saved.merit == 220 and saved.level_of(KARADA) == 0, "全部戻すと全額返る")
	check.call(TrainingProgress.load_saved().merit == 220, "戻しても保存する")


func _test_seal(check: Callable) -> void:
	var p := Progression.new(GROWTH)
	p.seals_left = 1
	check.call(not p.can_seal(GROWTH.heal) and not p.can_seal(GROWTH.full_heal), "回復は封じられない")
	check.call(p.can_seal(ZANKON), "強化は封じられる")
	p.seal(ZANKON)
	check.call(p.seals_left == 0 and not p.can_seal(ZANKON), "残りが無ければ封じられない")
	var seen := false
	for i in 50:
		seen = seen or ZANKON in p.roll_choices() or ZANKON in p.roll_scroll()
	check.call(not seen, "封じた強化は二度と出ない")


func _test_replace(check: Callable) -> void:
	var p := Progression.new(GROWTH)
	var choices := p.roll_choices()
	var kept := [choices[0], choices[2]]
	var replaced := p.replace_choice(choices, 1, false)
	var fresh := replaced[1] not in choices
	check.call(replaced.size() == 3 and fresh, "封じた位置だけ画面に無い候補と入れ替える")
	check.call(replaced[0] == kept[0] and replaced[2] == kept[1], "ほかのカードはそのまま")
	var upgrades: Array = GROWTH.upgrades
	for upgrade: Variant in upgrades:
		p._levels[upgrade] = upgrade.max_level
	var ougi_list: Array = GROWTH.ougi
	for ougi: Variant in ougi_list:
		p._levels[ougi] = 1
	p._levels.erase(ZANKON)
	var only: Array[UpgradeData] = [ZANKON]
	check.call(p.replace_choice(only, 0, false) == [GROWTH.heal], "候補が無く0枚になれば回復")
	var scroll := p.roll_scroll()
	var shrunk := p.replace_choice(scroll, 0, true)
	check.call(shrunk == [GROWTH.full_heal], "巻物で候補が無ければ消える")


func _test_arena_applies(check: Callable) -> void:
	var progress := TrainingProgress.new()
	progress.merit = 1000
	for item in [KARADA, ASHI, HIKINAOSHI, FUJI]:
		progress.buy(item)
	var arena: Node2D = ARENA_SCENE.instantiate()
	_tree.root.add_child(arena)
	await _tree.physics_frame
	var player: Player = arena.get_node("Entities/Player")
	var base_hp: int = player.data.max_hp
	check.call(player.health.max_hp == base_hp + 1 and player.health.hp == base_hp + 1, "体の修行でHP+1")
	check.call(is_equal_approx(player.stats.move_speed_scale, 1.04), "足の修行で移動+4%")
	var p: Progression = arena.progression
	check.call(p.rerolls_left == 1 and p.seals_left == 1, "引き直し・封じの回数を入れる")
	var before := TrainingProgress.load_saved().merit
	arena.kills = 30
	player.health.damage(player.health.hp)
	var label: Label = arena.get_node("GameOver/Label")
	var merit := TRAINING.reward(30, p.level, false)
	check.call(TrainingProgress.load_saved().merit == before + merit, "挑戦の終わりに武功を足す")
	check.call(label.text.contains("武功 +%d" % merit), "結果に武功を出す")
	arena.free()
	_tree.paused = false


func _test_arena_reroll_and_seal(check: Callable) -> void:
	var arena: Node2D = ARENA_SCENE.instantiate()
	_tree.root.add_child(arena)
	await _tree.physics_frame
	var p: Progression = arena.progression
	p.rerolls_left = 1
	p.seals_left = 1
	arena._on_soul_collected(GROWTH.exp_base)
	var menu := arena.get_node("LevelUp")
	arena._on_reroll()
	check.call(p.rerolls_left == 0 and menu.visible, "引き直すと回数が減って画面は開いたまま")
	var first: UpgradeData = arena._choices[0]
	arena._on_seal(0)
	check.call(p.seals_left == 0 and first not in arena._choices, "封じたカードは入れ替わる")
	arena._on_reroll()
	check.call(p.rerolls_left == 0, "残りが無ければ引き直せない")
	menu.choose(0)
	check.call(not _tree.paused, "選ぶと再開する")
	arena.free()
	_tree.paused = false


func _test_title_menu(check: Callable) -> void:
	var title: Control = TITLE_SCENE.instantiate()
	_tree.root.add_child(title)
	title.open_training()
	var menu: Control = title._training_menu
	var merit: int = menu.progress.merit
	menu.refund()
	menu.progress.merit = 20
	menu.buy(0)
	check.call(menu.progress.level_of(TRAINING.items[0]) == 1, "修行画面で買える")
	menu.refund()
	check.call(menu.progress.merit == 20, "修行画面で全部戻せる")
	menu.progress.merit = merit
	menu.progress.save()
	title._close_training()
	check.call(title._training_menu == null, "閉じるとタイトルへ戻る")
	title.free()
