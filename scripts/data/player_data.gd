class_name PlayerData
extends Resource
## 主人公の手触りに関わる数値(GameDesign.md 2・3・4章)。

@export var move_speed := 0.0
@export var max_hp := 0
@export var invincible_time := 0.0
@export var knockback_distance := 0.0
@export var knockback_time := 0.0
## 斬痕・残心(GameDesign.md 8章)
@export var linger_power := 0
@export var shockwave_power := 0
@export var shockwave_time := 0.0
## 燕返し:威力・斬り返しの時間(GameDesign.md 8章)
@export var return_power := 0
@export var return_time := 0.0
