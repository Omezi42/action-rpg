class_name EnemyData
extends Resource
## 敵1種ぶんの数値と色(GameDesign.md 5章)。色違いの派生はこのリソースを増やして作る。

@export var max_hp := 0
@export var contact_damage := 0
@export var wander_speed := 0.0
@export var wander_interval_min := 0.0
@export var wander_interval_max := 0.0
@export_range(0.0, 1.0) var wander_stop_chance := 0.0
@export var chase_speed := 0.0
@export var notice_range := 0.0
@export var lose_range := 0.0
@export var hurt_time := 0.0
@export var knockback_distance := 0.0
@export var knockback_time := 0.0
@export var color := Color.WHITE
