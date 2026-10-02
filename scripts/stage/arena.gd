extends Node2D
## アリーナ(GameDesign.md 1・5・6・8・9・10章)。敵と大鬼の出現、経過時間と撃破数、魂とレベルアップ、
## 終了(ゲームオーバー / クリア)と記録、演出と効果音のきっかけを受け持つ。

const SlashTrail = preload("res://scripts/effects/slash_trail.gd")
const HitSpark = preload("res://scripts/effects/hit_spark.gd")

@export var enemy_scene: PackedScene
@export var boss_scene: PackedScene
@export var survival: SurvivalData
@export var growth: GrowthData
@export var floor_color := Color("5d8a4a")
@export var floor_alt_color := Color("598546")
@export var floor_tile := 32.0
## 出現位置の判定に使う、壁・岩のコリジョンレイヤー
@export_flags_2d_physics var obstacle_mask := 1

var schedule: SpawnSchedule
var progression: Progression
var kills := 0
var ended := false
var boss: Enemy

var _alive := 0

@onready var _entities: Node2D = $Entities
@onready var _player: Player = $Entities/Player
@onready var _hearts = $HUD/Hearts
@onready var _run_status = $HUD/RunStatus
@onready var _exp_bar = $HUD/ExpBar
@onready var _boss_bar = $HUD/BossBar
@onready var _souls: SoulField = $Entities/SoulField
@onready var _level_up = $LevelUp
@onready var _game_over = $GameOver
@onready var _pause = $Pause
@onready var _effects: Node2D = $Effects
@onready var _camera: FollowCamera = $FollowCamera


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	schedule = SpawnSchedule.new(survival)
	progression = Progression.new(growth)
	_souls.player = _player
	_camera.setup(_player, schedule.field_rect())
	_souls.collected.connect(_on_soul_collected)
	_level_up.chosen.connect(_on_upgrade_chosen)
	_hearts.bind(_player.health)
	_player.died.connect(_end.bind(false))
	_player.slashed.connect(_on_player_slashed)
	_player.hit_landed.connect(_on_player_hit_landed)
	_connect_sounds()
	_update_status()


func _physics_process(delta: float) -> void:
	if ended:
		return
	if schedule.advance(delta) and _alive < schedule.max_enemies_at(schedule.elapsed):
		spawn_enemy()
	if schedule.take_horde():
		spawn_horde()
	if schedule.take_boss():
		spawn_boss()
	_update_status()


func _draw() -> void:
	var field := Rect2(Vector2.ZERO, survival.field_size)
	draw_rect(field, floor_color)
	var cols := ceili(field.size.x / floor_tile)
	var rows := ceili(field.size.y / floor_tile)
	for y in rows:
		for x in range(y % 2, cols, 2):
			var cell := Rect2(field.position + Vector2(x, y) * floor_tile, Vector2.ONE * floor_tile)
			draw_rect(cell.intersection(field), floor_alt_color)


func alive_enemies() -> int:
	return _alive


func spawn_enemy() -> void:
	var at := schedule.pick_spawn_point(_camera.view_rect(), _is_blocked)
	if at != Vector2.INF:
		_add_enemy(schedule.pick_enemy(), at)


func spawn_horde() -> void:
	for at in schedule.horde_points(_camera.view_rect()):
		_add_enemy(survival.horde_enemy, at, true)


func spawn_boss() -> void:
	boss = _add_enemy(null, schedule.edge_center(_camera.view_rect()), true, boss_scene)
	boss.defeated.connect(_end.bind(true).unbind(1))
	_boss_bar.bind(boss.health)
	Sfx.play(&"boss_appear")


## data が null ならシーンの持つ EnemyData のまま
func _add_enemy(
	data: EnemyData, at: Vector2, alerted := false, scene: PackedScene = enemy_scene
) -> Enemy:
	var enemy: Enemy = scene.instantiate()
	if data:
		enemy.data = data
	enemy.alerted = alerted
	enemy.position = at
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.tree_exiting.connect(_on_enemy_exiting)
	enemy.rush_warned.connect(Sfx.play.bind(&"boss_warn"))
	_entities.add_child(enemy)
	_alive += 1
	return enemy


func _is_blocked(point: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collision_mask = obstacle_mask
	return not get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()


func _update_status() -> void:
	_run_status.show_status(progression.level, schedule.time_left(), kills, boss != null)
	_exp_bar.show_ratio(float(progression.experience) / progression.exp_to_next())


func _end(cleared: bool) -> void:
	if ended:
		return
	ended = true
	get_tree().paused = true
	_pause.locked = true
	var updated := RunRecords.load_saved().submit(
		schedule.elapsed, kills, progression.level, cleared
	)
	_game_over.open(cleared, schedule.elapsed, kills, progression.level, updated)


## 撃破と、遠すぎて消えたときの両方で減らす
func _on_enemy_exiting() -> void:
	_alive -= 1


func _on_enemy_defeated(enemy: Enemy) -> void:
	kills += 1
	if enemy.data.soul_value > 0:
		_souls.drop(enemy.global_position, enemy.data.soul_value)
	_update_status()


func _on_soul_collected(value: int) -> void:
	Sfx.play(&"soul")
	progression.add_exp(value)
	_update_status()
	if progression.pending > 0 and not _level_up.visible and not ended:
		get_tree().paused = true
		_pause.locked = true
		_open_level_up()


func _open_level_up() -> void:
	Sfx.play(&"level_up")
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


func _connect_sounds() -> void:
	_player.stage_reached.connect(
		func(index: int, is_top: bool) -> void:
			Sfx.play(&"issen" if is_top else StringName("stage_%d" % index))
	)
	_player.dash_started.connect(Sfx.play.bind(&"dash"))
	_player.issen_sheathed.connect(Sfx.play.bind(&"chin"))
	_player.damaged.connect(Sfx.play.bind(&"hurt"))


func _on_player_hit_landed(at: Vector2) -> void:
	Sfx.play(&"hit")
	var spark := HitSpark.new()
	spark.position = at
	_effects.add_child(spark)
