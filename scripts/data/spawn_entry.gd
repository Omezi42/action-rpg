class_name SpawnEntry
extends Resource
## 出現表の1行(GameDesign.md 5章)。どの敵を、どの重みで、何秒から出すか。

@export var enemy: EnemyData
@export var weight := 0
@export var start_time := 0.0
