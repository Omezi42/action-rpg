class_name Progression
extends RefCounted
## 経験値・レベル・強化の段階(GameDesign.md 8章)。ノードを持たないのでテストから直接使える。

var level := 1
var experience := 0
## 選び待ちのレベルアップ数
var pending := 0
## 拾って選び待ちの巻物の数
var scroll_count := 0
## 修行(GameDesign.md 8章):この挑戦で引き直し・封じができる残りの回数
var rerolls_left := 0
var seals_left := 0

var _data: GrowthData
var _levels: Dictionary = {}
var _sealed: Array[UpgradeData] = []


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
	var choices: Array[UpgradeData] = []
	for upgrade: UpgradeData in _level_up_pool().slice(0, _data.choice_count):
		choices.append(upgrade)
	if choices.is_empty():
		choices.append(_data.heal)
	return choices


## 巻物の3枚:条件を満たした未取得の奥義を先に、残りを最大でない挙動の強化から。末尾に必ず全回復
func roll_scroll() -> Array[UpgradeData]:
	var choices: Array[UpgradeData] = []
	for upgrade: UpgradeData in _scroll_pool().slice(0, _data.scroll_pick_count):
		choices.append(upgrade)
	choices.append(_data.full_heal)
	return choices


func can_seal(upgrade: UpgradeData) -> bool:
	return seals_left > 0 and upgrade != _data.heal and upgrade != _data.full_heal


func seal(upgrade: UpgradeData) -> void:
	_sealed.append(upgrade)
	seals_left -= 1


## index の1枚を、同じ選び方でまだ画面に出ていない候補と入れ替える。候補が無ければ消す
func replace_choice(choices: Array[UpgradeData], index: int, is_scroll: bool) -> Array[UpgradeData]:
	var pool := _scroll_pool() if is_scroll else _level_up_pool()
	var fresh := pool.filter(func(u: UpgradeData) -> bool: return u not in choices)
	var result := choices.duplicate()
	if fresh.is_empty():
		result.remove_at(index)
	else:
		result[index] = fresh[0]
	if result.is_empty():
		result.append(_data.heal)
	return result


## 最大でなく封じていない強化を無作為な順で
func _level_up_pool() -> Array:
	var open := _data.upgrades.filter(
		func(u: UpgradeData) -> bool: return level_of(u) < u.max_level and u not in _sealed
	)
	open.shuffle()
	return open


## 条件を満たした未取得の奥義を先に、残りを最大でない挙動の強化から。どちらも封じたものは外す
func _scroll_pool() -> Array:
	var ougi := _data.ougi.filter(
		func(u: UpgradeData) -> bool:
			return level_of(u) == 0 and _requirements_met(u) and u not in _sealed
	)
	var behaviors := _data.upgrades.filter(
		func(u: UpgradeData) -> bool:
			return (
				u.kind == UpgradeData.Kind.BEHAVIOR
				and level_of(u) < u.max_level
				and u not in _sealed
			)
	)
	ougi.shuffle()
	behaviors.shuffle()
	return ougi + behaviors


func _requirements_met(upgrade: UpgradeData) -> bool:
	return upgrade.requires.all(
		func(u: Resource) -> bool:
			var required := u as UpgradeData
			return level_of(required) >= required.max_level
	)


## 巻物から選んだときは pending ではなく scroll_count を減らす
func take(upgrade: UpgradeData, player: Player, from_scroll := false) -> void:
	_levels[upgrade] = level_of(upgrade) + 1
	if from_scroll:
		scroll_count = maxi(scroll_count - 1, 0)
	else:
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
		UpgradeData.Stat.LINGER:
			stats.linger_time += upgrade.amount
		UpgradeData.Stat.SHOCKWAVE:
			stats.shockwave_radius += upgrade.amount
		UpgradeData.Stat.RETURN_SLASH:
			stats.return_distance += upgrade.amount
		UpgradeData.Stat.SHADOW_BIND:
			var first := level_of(upgrade) == 1 and upgrade.base_amount > 0.0
			stats.bind_time += upgrade.base_amount if first else upgrade.amount
		UpgradeData.Stat.OUGI_HOMURA:
			stats.ougi_homura = true
		UpgradeData.Stat.OUGI_DAIZANSHIN:
			stats.ougi_daizanshin = true
		UpgradeData.Stat.OUGI_TSUBAME:
			stats.ougi_tsubame = true
		UpgradeData.Stat.OUGI_KAGE:
			stats.ougi_kage = true
		UpgradeData.Stat.FULL_HEAL:
			player.health.heal(player.health.max_hp)
