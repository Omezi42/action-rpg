extends Node2D
## アリーナ(GameDesign.md 1・5・6・8・9・10章)。敵と大鬼の出現、経過時間と撃破数、魂とレベルアップ、
## 終了(ゲームオーバー / クリア)と記録、演出と効果音のきっかけを受け持つ。

const SlashTrail = preload("res://scripts/effects/slash_trail.gd")
const HitSpark = preload("res://scripts/effects/hit_spark.gd")
const HitokiriLabel = preload("res://scripts/effects/hitokiri_label.gd")

@export var enemy_scene: PackedScene
@export var boss_scene: PackedScene
@export var survival: SurvivalData
@export var growth: GrowthData
@export var training: TrainingCatalog = preload("res://data/training.tres")
@export var floor_color := Color("5d8a4a")
@export var floor_alt_color := Color("598546")
@export var floor_tile := 32.0
## 出現位置の判定に使う、壁・岩のコリジョンレイヤー
@export_flags_2d_physics var obstacle_mask := 1
## 人斬り(GameDesign.md 3章):文字を出す数・画面を揺らす一閃の数・揺れ幅・揺れる時間・文字の高さ
@export var hitokiri_min_count := 3
@export var hitokiri_shake_count := 5
@export var shake_amplitude := 2.0
@export var shake_time := 0.15
@export var hitokiri_label_height := 24.0
## 盾で弾いたときの火花の色
@export var guard_spark_color := Color("c8e0ff")

var schedule: SpawnSchedule
var progression: Progression
var hitokiri := HitokiriCounter.new()
var kills := 0
var ended := false
var boss: Enemy

var _alive := 0
## 開いている選択画面が巻物か(閉じたときに pending と scroll_count のどちらを減らすか)
var _choosing_scroll := false
## 開いている選択画面のカード(封じたときに入れ替えるため)
var _choices: Array[UpgradeData] = []

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
	TrainingProgress.load_saved().apply(training, _player, progression)
	_souls.player = _player
	_camera.setup(_player, schedule.field_rect())
	_souls.collected.connect(_on_soul_collected)
	_level_up.chosen.connect(_on_upgrade_chosen)
	_level_up.reroll_requested.connect(_on_reroll)
	_level_up.seal_requested.connect(_on_seal)
	_hearts.bind(_player.health)
	_player.died.connect(_end.bind(false))
	_player.slashed.connect(_on_player_slashed)
	_player.hit_landed.connect(_on_player_hit_landed)
	_player.strike_started.connect(hitokiri.start)
	_player.strike_finished.connect(_on_strike_finished)
	_connect_sounds()
	_update_status()
	Bgm.play(&"battle")


func _physics_process(delta: float) -> void:
	if ended:
		return
	if schedule.advance(delta) and _alive < schedule.max_enemies_at(schedule.elapsed):
		spawn_enemy()
	if schedule.take_horde():
		spawn_horde()
	if schedule.take_elite():
		spawn_elite()
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
	boss.defeated.connect(Sfx.play.bind(&"boss_defeat").unbind(1))
	boss.defeated.connect(_end.bind(true).unbind(1))
	boss.rush_warned.connect(Sfx.play.bind(&"boss_warn"))
	_boss_bar.bind(boss.health)
	Sfx.play(&"boss_appear")
	Bgm.play(&"boss")


func spawn_elite() -> Enemy:
	var at := schedule.edge_center(_camera.view_rect())
	var elite := _add_enemy(schedule.pick_enemy(), at, true, enemy_scene, true)
	elite.defeated.connect(_drop_scroll)
	Sfx.play(&"elite_appear")
	return elite


## data が null ならシーンの持つ EnemyData のまま
func _add_enemy(
	data: EnemyData, at: Vector2, alerted := false, scene: PackedScene = enemy_scene, elite := false
) -> Enemy:
	var enemy: Enemy = scene.instantiate()
	if data:
		enemy.data = data
	enemy.alerted = alerted
	if elite:
		enemy.make_elite(survival.elite_hp_scale, survival.elite_visual_scale)
	enemy.position = at
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.tree_exiting.connect(_on_enemy_exiting)
	enemy.shot_fired.connect(_on_enemy_shot.bind(enemy.data))
	enemy.guarded.connect(_on_enemy_guarded)
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
		schedule.elapsed, kills, progression.level, cleared, hitokiri.best
	)
	var merit := training.reward(kills, progression.level, cleared)
	var progress := TrainingProgress.load_saved()
	progress.merit += merit
	progress.save()
	_game_over.open(
		cleared, schedule.elapsed, kills, progression.level, hitokiri.best, updated, merit
	)


## 撃破と、遠すぎて消えたときの両方で減らす
func _on_enemy_exiting() -> void:
	_alive -= 1


func _on_enemy_defeated(enemy: Enemy) -> void:
	kills += 1
	hitokiri.add_kill()
	if enemy.data.soul_value > 0:
		_souls.drop(enemy.global_position, enemy.data.soul_value)
	_update_status()


func _on_enemy_shot(from: Vector2, direction: Vector2, data: EnemyData) -> void:
	var arrow := Arrow.new()
	arrow.position = from
	arrow.setup(direction, data.shot_speed, data.shot_distance, data.shot_damage)
	_effects.add_child(arrow)
	Sfx.play(&"shot")


func _on_soul_collected(value: int) -> void:
	Sfx.play(&"soul")
	progression.add_exp(value)
	_update_status()
	_open_choices()


func _drop_scroll(enemy: Enemy) -> void:
	var scroll := Scroll.new()
	scroll.position = enemy.global_position
	scroll.player = _player
	scroll.picked.connect(_on_scroll_picked)
	_entities.add_child.call_deferred(scroll)


func _on_scroll_picked() -> void:
	Sfx.play(&"scroll")
	progression.scroll_count += 1
	_open_choices()


## 選び待ちがあれば止めて選択画面を開く。巻物をレベルアップより先に出す
func _open_choices() -> void:
	if _level_up.visible or ended or (progression.scroll_count == 0 and progression.pending == 0):
		return
	get_tree().paused = true
	_pause.locked = true
	_open_next_choice()


func _open_next_choice() -> void:
	_choosing_scroll = progression.scroll_count > 0
	_choices = progression.roll_scroll() if _choosing_scroll else progression.roll_choices()
	if not _choosing_scroll:
		Sfx.play(&"level_up")
	_show_choices()


func _show_choices(selected := 0) -> void:
	var levels: Array[int] = []
	for upgrade in _choices:
		levels.append(progression.level_of(upgrade))
	_level_up.open(
		_choices,
		levels,
		_choosing_scroll,
		progression.rerolls_left,
		progression.seals_left,
		selected
	)


func _on_reroll() -> void:
	if progression.rerolls_left <= 0:
		return
	progression.rerolls_left -= 1
	_choices = progression.roll_scroll() if _choosing_scroll else progression.roll_choices()
	Sfx.play(&"confirm")
	_show_choices()


func _on_seal(index: int) -> void:
	if index < 0 or index >= _choices.size() or not progression.can_seal(_choices[index]):
		return
	progression.seal(_choices[index])
	_choices = progression.replace_choice(_choices, index, _choosing_scroll)
	Sfx.play(&"confirm")
	_show_choices(mini(index, _choices.size() - 1))


func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	progression.take(upgrade, _player, _choosing_scroll)
	_update_status()
	if progression.scroll_count > 0 or progression.pending > 0:
		_open_next_choice()
		return
	get_tree().paused = false
	_pause.locked = false
	_player.interrupt_input()


## 一閃のときはチンが鳴るので人斬りの音は鳴らさない
func _on_strike_finished(is_issen: bool) -> void:
	var count := hitokiri.finish()
	if count < hitokiri_min_count:
		return
	var label := HitokiriLabel.new()
	label.position = _player.global_position + Vector2.UP * hitokiri_label_height
	label.setup(count, is_issen)
	_effects.add_child(label)
	if not is_issen:
		Sfx.play(&"hitokiri")
	elif count >= hitokiri_shake_count:
		_camera.shake(shake_amplitude, shake_time)


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
	_player.return_started.connect(Sfx.play.bind(&"return"))
	_player.issen_sheathed.connect(Sfx.play.bind(&"chin"))
	_player.damaged.connect(Sfx.play.bind(&"hurt"))


func _on_player_hit_landed(at: Vector2) -> void:
	Sfx.play(&"hit")
	var spark := HitSpark.new()
	spark.position = at
	_effects.add_child(spark)


func _on_enemy_guarded(at: Vector2) -> void:
	Sfx.play(&"guard")
	var spark := HitSpark.new()
	spark.color = guard_spark_color
	spark.position = at + Hitbox.GROUND_TO_BODY
	_effects.add_child(spark)
