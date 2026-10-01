extends Node2D
## アリーナ(GameDesign.md 1・5・6・8章)。敵の出現、経過時間と撃破数、魂とレベルアップ、
## 終了(ゲームオーバー / クリア)、演出の生成を受け持つ。

const SlashTrail = preload("res://scripts/effects/slash_trail.gd")
const HitSpark = preload("res://scripts/effects/hit_spark.gd")

@export var enemy_scene: PackedScene
@export var survival: SurvivalData
@export var growth: GrowthData
@export var floor_color := Color("5d8a4a")

var schedule: SpawnSchedule
var progression: Progression
var kills := 0
var ended := false

var _alive := 0

@onready var _entities: Node2D = $Entities
@onready var _player: Player = $Entities/Player
@onready var _hearts = $HUD/Hearts
@onready var _run_status = $HUD/RunStatus
@onready var _exp_bar = $HUD/ExpBar
@onready var _souls: SoulField = $Entities/SoulField
@onready var _level_up = $LevelUp
@onready var _game_over = $GameOver
@onready var _pause = $Pause
@onready var _effects: Node2D = $Effects


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	schedule = SpawnSchedule.new(survival)
	progression = Progression.new(growth)
	_souls.player = _player
	_souls.collected.connect(_on_soul_collected)
	_level_up.chosen.connect(_on_upgrade_chosen)
	_hearts.bind(_player.health)
	_player.died.connect(_end.bind(false))
	_player.slashed.connect(_on_player_slashed)
	_player.hit_landed.connect(_on_player_hit_landed)
	_update_status()


func _physics_process(delta: float) -> void:
	if ended:
		return
	if schedule.advance(delta) and _alive < schedule.max_enemies_at(schedule.elapsed):
		spawn_enemy()
	if schedule.take_horde():
		spawn_horde()
	_update_status()
	if schedule.is_cleared():
		_end(true)


func _draw() -> void:
	draw_rect(get_viewport_rect(), floor_color)


func alive_enemies() -> int:
	return _alive


func spawn_enemy() -> void:
	var at := schedule.pick_spawn_point(get_viewport_rect(), _player.global_position)
	_add_enemy(schedule.pick_enemy(), at)


func spawn_horde() -> void:
	for at in schedule.horde_points(get_viewport_rect(), _player.global_position):
		_add_enemy(survival.horde_enemy, at, true)


func _add_enemy(data: EnemyData, at: Vector2, alerted := false) -> void:
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.data = data
	enemy.alerted = alerted
	enemy.position = at
	enemy.defeated.connect(_on_enemy_defeated)
	_entities.add_child(enemy)
	_alive += 1


func _update_status() -> void:
	_run_status.show_status(progression.level, schedule.time_left(), kills)
	_exp_bar.show_ratio(float(progression.experience) / progression.exp_to_next())


func _end(cleared: bool) -> void:
	if ended:
		return
	ended = true
	get_tree().paused = true
	_pause.locked = true
	_game_over.open(cleared, minf(schedule.elapsed, survival.clear_time), kills, progression.level)


func _on_enemy_defeated(enemy: Enemy) -> void:
	_alive -= 1
	kills += 1
	_souls.drop(enemy.global_position, enemy.data.soul_value)
	_update_status()


func _on_soul_collected(value: int) -> void:
	progression.add_exp(value)
	_update_status()
	if progression.pending > 0 and not _level_up.visible and not ended:
		get_tree().paused = true
		_pause.locked = true
		_open_level_up()


func _open_level_up() -> void:
	var choices := progression.roll_choices()
	var levels: Array[int] = []
	for upgrade in choices:
		levels.append(progression.level_of(upgrade))
	_level_up.open(choices, levels)


func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	progression.take(upgrade, _player)
	_update_status()
	if progression.pending > 0:
		_open_level_up()
		return
	get_tree().paused = false
	_pause.locked = false
	_player.interrupt_input()


func _on_player_slashed(from: Vector2, to: Vector2, is_issen: bool) -> void:
	var trail := SlashTrail.new()
	trail.setup(from, to, is_issen)
	_effects.add_child(trail)


func _on_player_hit_landed(at: Vector2) -> void:
	var spark := HitSpark.new()
	spark.position = at
	_effects.add_child(spark)
