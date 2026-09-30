class_name PlayerStats
extends RefCounted
## 強化後の主人公の能力値(Architecture.md 7章)。倍率系は 1、加算系は 0 から始まる。

const POWER_BONUS := &"power_bonus"
const HOLD_SCALE := &"hold_scale"
const ISSEN_WINDOW_BONUS := &"issen_window_bonus"
const DISTANCE_SCALE := &"distance_scale"
const MOVE_SPEED_SCALE := &"move_speed_scale"
const PICKUP_SCALE := &"pickup_scale"
const LINGERING_LEVEL := &"lingering_level"

const BASE := {
	POWER_BONUS: 0.0,
	HOLD_SCALE: 1.0,
	ISSEN_WINDOW_BONUS: 0.0,
	DISTANCE_SCALE: 1.0,
	MOVE_SPEED_SCALE: 1.0,
	PICKUP_SCALE: 1.0,
	LINGERING_LEVEL: 0.0,
}

var _values: Dictionary = BASE.duplicate()


func value(stat: StringName) -> float:
	assert(_values.has(stat), "未知の stat: %s" % stat)
	return _values[stat]


func apply(upgrade: UpgradeData) -> void:
	assert(_values.has(upgrade.stat), "未知の stat: %s" % upgrade.stat)
	if upgrade.mode == UpgradeData.Mode.MULTIPLY:
		_values[upgrade.stat] *= upgrade.amount
	else:
		_values[upgrade.stat] += upgrade.amount
