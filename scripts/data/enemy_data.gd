class_name EnemyData
extends Resource
## 敵1種ぶんの数値と色(GameDesign.md 5章)。色違いの派生はこのリソースを増やして作る。

@export var max_hp := 0
@export var contact_damage := 0
@export var chase_speed := 0.0
@export var hurt_time := 0.0
@export var knockback_distance := 0.0
@export var knockback_time := 0.0
@export var color := Color.WHITE
## 倒したときに落とす魂の経験値(GameDesign.md 8章)
@export var soul_value := 0
## うろつき・気づき・見失い(GameDesign.md 5章「ふるまい」)
@export var wander_speed_ratio := 0.0
@export var wander_turn_min := 0.0
@export var wander_turn_max := 0.0
@export var sight_range := 0.0
@export var notice_time := 0.0
@export var lose_range := 0.0
