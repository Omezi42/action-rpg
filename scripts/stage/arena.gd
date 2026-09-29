extends Node2D
## アリーナ(GameDesign.md 1・5・6章)。敵の出現、経過時間と撃破数、終了(ゲームオーバー / クリア)、演出の生成を受け持つ。

const SlashTrail = preload("res://scripts/effects/slash_trail.gd")
const HitSpark = preload("res://scripts/effects/hit_spark.gd")

@export var enemy_scene: PackedScene
@export var survival: SurvivalData
@export var floor_color := Color("5d8a4a")

var schedule: SpawnSchedule
var kills := 0
var ended := false

var _alive := 0

@onready var _entities: Node2D = $Entities
@onready var _player: Player = $Entities/Player
@onready var _hearts = $HUD/Hearts
@onready var _run_status = $HUD/RunStatus
@onready var _game_over = $GameOver
@onready var _pause = $Pause
@onready var _effects: Node2D = $Effects


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	schedule = SpawnSchedule.new(survival)
	_hearts.bind(_player.health)
	_player.died.connect(_end.bind(false))
	_player.slashed.connect(_on_player_slashed)
	_player.hit_landed.connect(_on_player_hit_landed)
	_update_status()


func _physics_process(delta: float) -> void:
	if ended:
		return
	if schedule.advance(delta) and _alive < survival.max_enemies:
		spawn_enemy()
	_update_status()
	if schedule.is_cleared():
		_end(true)


func _draw() -> void:
	draw_rect(get_viewport_rect(), floor_color)


func alive_enemies() -> int:
	return _alive


func spawn_enemy() -> void:
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.position = schedule.pick_spawn_point(get_viewport_rect(), _player.global_position)
	enemy.defeated.connect(_on_enemy_defeated)
	_entities.add_child(enemy)
	_alive += 1


func _update_status() -> void:
	_run_status.show_status(schedule.elapsed, survival.clear_time, kills)


func _end(cleared: bool) -> void:
	if ended:
		return
	ended = true
	get_tree().paused = true
	_pause.locked = true
	_game_over.open(cleared, minf(schedule.elapsed, survival.clear_time), kills)


func _on_enemy_defeated() -> void:
	_alive -= 1
	kills += 1
	_update_status()


func _on_player_slashed(from: Vector2, to: Vector2, is_issen: bool) -> void:
	var trail := SlashTrail.new()
	trail.setup(from, to, is_issen)
	_effects.add_child(trail)


func _on_player_hit_landed(at: Vector2) -> void:
	var spark := HitSpark.new()
	spark.position = at
	_effects.add_child(spark)
