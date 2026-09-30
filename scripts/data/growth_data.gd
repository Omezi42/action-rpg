class_name GrowthData
extends Resource
## 経験値・レベルアップ・3択・斬痕の数値(GameDesign.md 8章)。

@export var xp_base := 0
@export var xp_step := 0
@export var magnet_speed := 0.0
@export var collect_distance := 0.0
@export var choice_count := 0
@export var choose_lock_time := 0.0
## 候補が足りないときに足す札(手当)
@export var filler: UpgradeData
@export_dir var upgrade_dir := ""
@export_group("斬痕")
@export var lingering_base_time := 0.0
@export var lingering_time_step := 0.0
@export var lingering_power := 0
