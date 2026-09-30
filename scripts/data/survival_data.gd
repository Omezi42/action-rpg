class_name SurvivalData
extends Resource
## サバイバルの進行と敵の出現(GameDesign.md 1・5章)。phases は start_time の昇順。

@export var clear_time := 0.0
@export var phases: Array[SpawnPhase] = []
@export var spawns: Array[SpawnEntry] = []
@export var horde_times := PackedFloat32Array()
@export var horde_count := 0
@export var horde_spacing := 0.0
@export var horde_enemy: EnemyData
@export var spawn_margin := 0.0
@export var spawn_min_player_distance := 0.0
