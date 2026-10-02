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
## 巻物(GameDesign.md 8章):奥義・挙動の強化から選ぶ枚数と、必ず足す「全回復」
@export var scroll_pick_count := 0
@export var full_heal: UpgradeData
@export var ougi: Array[UpgradeData] = []
