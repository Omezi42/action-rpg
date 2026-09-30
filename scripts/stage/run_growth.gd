class_name RunGrowth
extends Node
## 1回の挑戦の中の成長の進行役(GameDesign.md 8章)。玉を落とし、回収で経験値を足し、
## レベルアップで3択を開いて選ばれた強化を主人公へ反映する。斬痕も出す。

@export var data: GrowthData

var growth: Growth

var _player: Player
var _pickups: Node2D
var _effects: Node2D
var _menu
var _xp_bar
var _pause


func setup(player: Player, pickups: Node2D, effects: Node2D, menu, xp_bar, pause) -> void:
	_player = player
	_pickups = pickups
	_effects = effects
	_menu = menu
	_xp_bar = xp_bar
	_pause = pause
	growth = Growth.new(data, Growth.load_pool(data.upgrade_dir))
	_player.slashed.connect(_on_player_slashed)
	_menu.chosen.connect(_on_chosen)
	_update_bar()


func drop_xp(at: Vector2, value: int) -> void:
	var orb := XpOrb.new()
	orb.setup(value, data)
	orb.position = at
	orb.collected.connect(add_xp)
	_pickups.add_child.call_deferred(orb)


func add_xp(value: int) -> void:
	var gained := growth.add_xp(value)
	_update_bar()
	if gained > 0 and not _menu.visible:
		_open_menu()


func _open_menu() -> void:
	get_tree().paused = true
	_pause.locked = true
	var choices := growth.roll_choices()
	var levels: Array[int] = []
	for upgrade in choices:
		levels.append(growth.level_of(upgrade))
	_menu.open(choices, levels, data.choose_lock_time)


func _on_chosen(upgrade: UpgradeData) -> void:
	growth.take(upgrade)
	_player.apply_upgrade(upgrade)
	if growth.pending > 0:
		_open_menu()
		return
	get_tree().paused = false
	_pause.locked = false
	_player.resync_input()


func _on_player_slashed(from: Vector2, to: Vector2, _is_issen: bool) -> void:
	var level := roundi(_player.stats.value(PlayerStats.LINGERING_LEVEL))
	if level <= 0:
		return
	var slash := LingeringSlash.new()
	var life := data.lingering_base_time + data.lingering_time_step * (level - 1)
	slash.setup(from, to, data.lingering_power, life)
	_effects.add_child(slash)


func _update_bar() -> void:
	_xp_bar.show_growth(growth.level, growth.xp, growth.xp_to_next())
