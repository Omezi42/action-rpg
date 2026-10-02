class_name TrainingCatalog
extends Resource
## 修行の一覧と武功の式の数値(GameDesign.md 8章「修行」)。

@export var items: Array[TrainingData] = []
@export var kills_per_merit := 0
@export var merit_per_level := 0
@export var clear_merit := 0


## 1回の挑戦で得る武功
func reward(kills: int, level: int, cleared: bool) -> int:
	var merit := kills / kills_per_merit + level * merit_per_level
	if cleared:
		merit += clear_merit
	return merit
