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
## フィールドの広さ。原点が左上(GameDesign.md 6章)
@export var field_size := Vector2.ZERO
## 出現・大群は、カメラの映す矩形をこれだけ広げた周上
@export var spawn_margin := 0.0
## 残り時間0から大鬼を倒すまでの出現(GameDesign.md 5章「ボス」)
@export var boss_spawn_interval := 0.0
@export var boss_max_enemies := 0
