class_name TrainingProgress
extends RefCounted
## 武功と修行の段階の読み書き(GameDesign.md 8・9章)。テストと撮影は path を別のファイルへ向ける。

const SECTION := "progress"
const MERIT_KEY := "merit"
const LEVELS_KEY := "levels"

static var path := "user://progress.cfg"

var merit := 0
var _levels: Dictionary = {}


static func load_saved() -> TrainingProgress:
	var progress := TrainingProgress.new()
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return progress
	progress.merit = file.get_value(SECTION, MERIT_KEY, 0)
	progress._levels = file.get_value(SECTION, LEVELS_KEY, {})
	return progress


func save() -> void:
	var file := ConfigFile.new()
	file.set_value(SECTION, MERIT_KEY, merit)
	file.set_value(SECTION, LEVELS_KEY, _levels)
	file.save(path)


func level_of(item: TrainingData) -> int:
	return _levels.get(String(item.id), 0)


## 次の段の値段。最大なら -1
func next_cost(item: TrainingData) -> int:
	var level := level_of(item)
	return item.costs[level] if level < item.max_level() else -1


func buy(item: TrainingData) -> bool:
	var cost := next_cost(item)
	if cost < 0 or cost > merit:
		return false
	merit -= cost
	_levels[String(item.id)] = level_of(item) + 1
	save()
	return true


## 使った武功を全額返し、すべての段を0に戻す
func refund_all(catalog: TrainingCatalog) -> void:
	for item in catalog.items:
		for i in level_of(item):
			merit += item.costs[i]
	_levels.clear()
	save()


func total(catalog: TrainingCatalog, effect: TrainingData.Effect) -> float:
	var sum := 0.0
	for item in catalog.items:
		if item.effect == effect:
			sum += item.amount * level_of(item)
	return sum


## 挑戦の始めに主人公と成長へ反映する
func apply(catalog: TrainingCatalog, player: Player, progression: Progression) -> void:
	var extra_hp := roundi(total(catalog, TrainingData.Effect.MAX_HP))
	if extra_hp > 0:
		player.health.raise_max(extra_hp)
	player.stats.move_speed_scale += total(catalog, TrainingData.Effect.MOVE_SPEED)
	progression.rerolls_left = roundi(total(catalog, TrainingData.Effect.REROLL))
	progression.seals_left = roundi(total(catalog, TrainingData.Effect.SEAL))
