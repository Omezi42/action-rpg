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
## 奥義:焔痕の威力と残る時間の倍率・大残心の2回目までの時間・影縫い・極の線の左右の幅(GameDesign.md 8章)
@export var homura_power := 0
@export var homura_time_scale := 0.0
@export var daizanshin_delay := 0.0
@export var kage_width := 0.0
