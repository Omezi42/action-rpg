extends Node2D
## 試作場(GameDesign.md 1・5・6章)。敵の配置と全滅後の復活、演出の生成、ゲームオーバーを受け持つ。

const SlashTrail = preload("res://scripts/effects/slash_trail.gd")
const HitSpark = preload("res://scripts/effects/hit_spark.gd")

@export var enemy_scene: PackedScene
@export var respawn_delay := 2.0
@export var floor_color := Color("5d8a4a")

var _alive := 0

@onready var _entities: Node2D = $Entities
@onready var _player: Player = $Entities/Player
@onready var _spawn_points: Node2D = $SpawnPoints
@onready var _hearts = $HUD/Hearts
@onready var _game_over = $GameOver
@onready var _effects: Node2D = $Effects


func _ready() -> void:
	Engine.time_scale = 1.0
	_hearts.bind(_player.health)
	_player.died.connect(_game_over.open)
	_player.slashed.connect(_on_player_slashed)
	_player.hit_landed.connect(_on_player_hit_landed)
	_spawn_enemies()


func _draw() -> void:
	draw_rect(get_viewport_rect(), floor_color)


func alive_enemies() -> int:
	return _alive


func _spawn_enemies() -> void:
	for point: Node2D in _spawn_points.get_children():
		var enemy: Enemy = enemy_scene.instantiate()
		enemy.position = point.position
		enemy.defeated.connect(_on_enemy_defeated)
		_entities.add_child(enemy)
		_alive += 1


func _on_enemy_defeated() -> void:
	_alive -= 1
	if _alive > 0:
		return
	await get_tree().create_timer(respawn_delay, false).timeout
	_spawn_enemies()


func _on_player_slashed(from: Vector2, to: Vector2, is_issen: bool) -> void:
	var trail := SlashTrail.new()
	trail.setup(from, to, is_issen)
	_effects.add_child(trail)


func _on_player_hit_landed(at: Vector2) -> void:
	var spark := HitSpark.new()
	spark.position = at
	_effects.add_child(spark)
