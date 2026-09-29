class_name IaiData
extends Resource
## 居合の段階表と一閃・ヒットストップ・マウスの狙い(GameDesign.md 2・3章)。stages は hold_time の昇順。

@export var stages: Array[IaiStage] = []
@export var issen: IaiStage
@export var issen_window := 0.0
@export var hitstop_time := 0.0
@export var aim_deadzone := 0.0
