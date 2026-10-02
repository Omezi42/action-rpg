# 4. 敵

`scripts/enemies/enemy.gd`(class Enemy)が全敵共通。種類は EnemyData(`data/enemies/*.tres`:kooni / aka_oni / ao_oni / yumi_oni / oo_oni)で分ける。シーンは `kooni.tscn` 1つを使い回し、Arena が出現時に `add_child` の前で `data` を差し替える(`_ready` で読むため)。

| 状態 | すること |
|---|---|
| WANDER | 初期状態。`chase_speed * wander_speed_ratio` で歩く。最初の向きは主人公の方向±`initial_wander_spread`、以後はランダムな向きへ。`wander_turn_min〜max` 秒ごと・衝突時に向きを変える。主人公が `sight_range` 以内で NOTICE |
| NOTICE | `notice_time` 止まって CHASE。EnemyVisual が頭上に「!」を描く |
| CHASE | 主人公へ `chase_speed` で直進。`lose_range` より離れたら WANDER。`attack_range` 以内で攻撃の待ちが明けていれば WINDUP、`hold_range` 以内なら立ち止まる |
| WINDUP | `attack_windup` 止まって予告。向き `aim_direction` は入る瞬間に決め、`rush_warned` を出す。`rush_distance > 0` なら RUSH、`sweep_radius > 0` なら SWEEP へ |
| RUSH | `aim_direction` へ `rush_distance` を `rush_time` で `move_and_collide`。壁・岩で止まる。AttackHitbox が有効 |
| SWEEP | SweepAttack(正面の半円)が `sweep_time` だけ有効 |
| RECOVER | `attack_recover` 止まって CHASE |
| HURT | `knockback_time` の間ノックバック、`hurt_time` で CHASE |
| DOOMED | 一閃でHP0。止まって `fall()` を待つ |

- 弓鬼:EnemyData の `shot_range` が0より大きいと、CHASE 中に `shot_range` 以内で止まり `AIM`(`shot_windup`)→ `shot_fired(from, direction)` を出して CHASE へ戻る。`shot_interval` の間は範囲内なら立ち止まる。Arena が `Arrow`(`scripts/enemies/arrow.gd`、Hitbox。layer enemy_attack・mask world)を生成する。矢は `landed`・壁への `body_entered`・射程で消える
- WANDER 中に主人公から `despawn_range` より離れたら `defeated` を出さずに `queue_free()`(GameDesign.md 5章)
- `alerted = true` を `add_child` の前に立てると CHASE から始まる(Arena が大群に使う)
- 攻撃の種類は EnemyData で決める:`rush_distance > 0` は踏み込み(小鬼・赤鬼・大鬼の突進)、`sweep_radius > 0` は薙ぎ払い(青鬼)、`shot_range > 0` は矢(弓鬼)
- 攻撃の待ち `attack_interval` は WINDUP に入った瞬間から数える(斬られて取り消されても待ちは消費済み)
- 接触ダメージは無い。AttackHitbox(layer enemy_attack、`hit_once_per_activation`)は RUSH の間だけ有効で、威力は `attack_damage`
- SweepAttack(`scripts/enemies/sweep_attack.gd`、Hitbox)は `sweep_radius > 0` のとき Enemy が `_ready` で子に作る。半円の当たりと、WINDUP 中の赤い予告・SWEEP 中の振りを自分で描く
- RushGuide(`scenes/enemies/rush_guide.tscn`)は踏み込みの WINDUP 中に予告線を描く。線の太さ `width` はシーンごと(小鬼のシーン4px・大鬼10px)
- WINDUP / RUSH / SWEEP 中に斬られたら HURT へ(攻撃の取り消し)。`attack_armor` が true(大鬼)なら状態を変えず光るだけ
- 撃破時に `defeated(enemy)` を出して `queue_free()`(Arena が位置と `data.soul_value` から魂を落とす)。主人公は group `"player"` で探す
