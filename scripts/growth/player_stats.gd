class_name PlayerStats
extends RefCounted
## 強化の合計(GameDesign.md 8章)。Player と IaiCharge が読む。

var charge_time_scale := 1.0
var distance_scale := 1.0
var power_bonus := 0
var issen_window_bonus := 0.0
var move_speed_scale := 1.0
## 斬痕の残る時間・残心の半径。0なら出さない(GameDesign.md 8章)
var linger_time := 0.0
var shockwave_radius := 0.0
## 燕返しの距離。0なら返せない
var return_distance := 0.0
## 影縫いの時間。0なら止めない
var bind_time := 0.0
