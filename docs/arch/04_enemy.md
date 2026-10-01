# 4. 敵

`scripts/enemies/enemy.gd`(class Enemy)が全敵共通。種類は EnemyData(`data/enemies/*.tres`:kooni / aka_oni / ao_oni)で分ける。シーンは `kooni.tscn` 1つを使い回し、Arena が出現時に `add_child` の前で `data` を差し替える(`_ready` で読むため)。

| 状態 | すること |
|---|---|
| WANDER | 初期状態。`chase_speed * wander_speed_ratio` で歩く。最初の向きは主人公の方向±`initial_wander_spread`、以後はランダムな向きへ。`wander_turn_min〜max` 秒ごと・衝突時に向きを変える。主人公が `sight_range` 以内で NOTICE |
| NOTICE | `notice_time` 止まって CHASE。EnemyVisual が頭上に「!」を描く |
| CHASE | 主人公へ `chase_speed` で直進。`lose_range` より離れたら WANDER |
| HURT | `knockback_time` の間ノックバック、`hurt_time` で CHASE |
| DOOMED | 一閃でHP0。止まって `fall()` を待つ |

- WANDER 中に主人公から `despawn_range` より離れたら `defeated` を出さずに `queue_free()`(GameDesign.md 5章)
- `alerted = true` を `add_child` の前に立てると CHASE から始まる(Arena が大群に使う)
- ContactHitbox は HURT / DOOMED 以外で有効(被弾硬直中は接触ダメージなし)
- 撃破時に `defeated(enemy)` を出して `queue_free()`(Arena が位置と `data.soul_value` から魂を落とす)。主人公は group `"player"` で探す
