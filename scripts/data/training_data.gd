class_name TrainingData
extends Resource
## 修行1項目(GameDesign.md 8章「修行」)。段数は costs の数。

enum Effect { MAX_HP, MOVE_SPEED, REROLL, SEAL }

## 保存の鍵
@export var id := &""
@export var label := ""
@export var description := ""
@export var effect := Effect.MAX_HP
@export var amount := 0.0
## 段ごとの値段(武功)
@export var costs: Array[int] = []


func max_level() -> int:
	return costs.size()
