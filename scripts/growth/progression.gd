class_name Progression
extends RefCounted
## 経験値・レベル・強化の段階(GameDesign.md 8章)。ノードを持たないのでテストから直接使える。

var level := 1
var experience := 0
## 選び待ちのレベルアップ数
var pending := 0

var _data: GrowthData
var _levels: Dictionary = {}


func _init(data: GrowthData) -> void:
	_data = data


func exp_to_next() -> int:
	return _data.exp_base + _data.exp_step * (level - 1)


func add_exp(amount: int) -> void:
	experience += amount
	while experience >= exp_to_next():
		experience -= exp_to_next()
		level += 1
		pending += 1


func level_of(upgrade: UpgradeData) -> int:
	return _levels.get(upgrade, 0)


func roll_choices() -> Array[UpgradeData]:
	var open := _data.upgrades.filter(
		func(u: UpgradeData) -> bool: return level_of(u) < u.max_level
	)
	open.shuffle()
	var choices: Array[UpgradeData] = []
	for upgrade: UpgradeData in open.slice(0, _data.choice_count):
		choices.append(upgrade)
	if choices.is_empty():
		choices.append(_data.heal)
	return choices


func take(upgrade: UpgradeData, player: Player) -> void:
	_levels[upgrade] = level_of(upgrade) + 1
	pending = maxi(pending - 1, 0)
	var stats := player.stats
	match upgrade.stat:
		UpgradeData.Stat.CHARGE_TIME:
			stats.charge_time_scale -= upgrade.amount
		UpgradeData.Stat.DASH_DISTANCE:
			stats.distance_scale += upgrade.amount
		UpgradeData.Stat.POWER:
			stats.power_bonus += roundi(upgrade.amount)
		UpgradeData.Stat.ISSEN_WINDOW:
			stats.issen_window_bonus += upgrade.amount
		UpgradeData.Stat.MOVE_SPEED:
			stats.move_speed_scale += upgrade.amount
		UpgradeData.Stat.MAX_HP:
			player.health.raise_max(roundi(upgrade.amount))
		UpgradeData.Stat.HEAL:
			player.health.heal(roundi(upgrade.amount))
