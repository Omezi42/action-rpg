class_name EnemyData
extends Resource
## 敵1種ぶんの数値と色(GameDesign.md 5章)。色違いの派生はこのリソースを増やして作る。

@export var max_hp := 0
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
## 出現して最初のうろつきは主人公の方向 ± これ(ラジアン)
@export var initial_wander_spread := 0.0
## うろつき中に主人公からこれより離れたら消える
@export var despawn_range := 0.0
## 予告のある攻撃(GameDesign.md 5章「攻撃」)。間合い・待ち・予告・隙は種類によらず共通
@export var attack_damage := 0
@export var attack_range := 0.0
@export var attack_interval := 0.0
@export var attack_windup := 0.0
@export var attack_recover := 0.0
## 追跡中にこの距離の内では立ち止まる。0なら立ち止まらない(大鬼)
@export var hold_range := 0.0
## true なら予告・攻撃・隙の間に斬られても攻撃を取り消さない(大鬼)
@export var attack_armor := false
## 踏み込み(小鬼・赤鬼・大鬼の突進)。rush_distance が0なら踏み込まない
@export var rush_distance := 0.0
@export var rush_time := 0.0
## 薙ぎ払い・着地の一撃の当たりが出ている時間
@export var strike_time := 0.0
## 薙ぎ払い(青鬼)。sweep_radius が0なら薙ぎ払わない
@export var sweep_radius := 0.0
## ジャンプ斬り(赤鬼)。jump_radius が0なら跳ばない。jump_height は見た目の最高の高さ
@export var jump_radius := 0.0
@export var jump_time := 0.0
@export var jump_height := 0.0
## 矢(弓鬼。GameDesign.md 5章)。shot_range が0なら撃たない
@export var shot_range := 0.0
@export var shot_windup := 0.0
@export var shot_interval := 0.0
@export var shot_speed := 0.0
@export var shot_distance := 0.0
@export var shot_damage := 0
