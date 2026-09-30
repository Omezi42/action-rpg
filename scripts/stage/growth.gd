class_name Growth
extends RefCounted
## 1回の挑戦の中の経験値・レベル・強化の段(GameDesign.md 8章)。ノードを持たないのでテストから直接使える。

var xp := 0
var level := 1
## まだ選んでいないレベルアップの数
var pending := 0
var pool: Array[UpgradeData] = []

var _data: GrowthData
var _levels: Dictionary = {}


func _init(data: GrowthData, upgrades: Array[UpgradeData]) -> void:
	_data = data
	pool = upgrades


## dir にある UpgradeData を名前順に集める
static func load_pool(dir: String) -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	var files := Array(ResourceLoader.list_directory(dir))
	files.sort()
	for file: String in files:
		var upgrade := load(dir.path_join(file)) as UpgradeData
		if upgrade:
			result.append(upgrade)
	return result


func xp_to_next() -> int:
	return _data.xp_base + _data.xp_step * (level - 1)


## 余りを持ち越してレベルを上げ、上がった数を返す
func add_xp(amount: int) -> int:
	xp += amount
	var gained := 0
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		gained += 1
	pending += gained
	return gained


func level_of(upgrade: UpgradeData) -> int:
	return _levels.get(upgrade, 0)


func roll_choices() -> Array[UpgradeData]:
	var available := pool.filter(func(u: UpgradeData) -> bool: return level_of(u) < u.max_level)
	available.shuffle()
	var choices: Array[UpgradeData] = []
	choices.assign(available.slice(0, _data.choice_count))
	if choices.size() < _data.choice_count:
		choices.append(_data.filler)
	return choices


func take(upgrade: UpgradeData) -> void:
	if upgrade != _data.filler:
		_levels[upgrade] = level_of(upgrade) + 1
	pending = maxi(pending - 1, 0)
