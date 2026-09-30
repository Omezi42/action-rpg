class_name GrowthData
extends Resource
## 魂・経験値・レベルアップの数値と強化の一覧(GameDesign.md 8章)。

@export var pickup_radius := 0.0
@export var pull_speed := 0.0
@export var collect_distance := 0.0
@export var max_souls := 0
@export var exp_base := 0
@export var exp_step := 0
@export var choice_count := 0
@export var choose_lock_time := 0.0
@export var upgrades: Array[UpgradeData] = []
@export var heal: UpgradeData
