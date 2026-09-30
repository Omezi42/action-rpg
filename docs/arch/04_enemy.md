# 4. 敵

`scripts/enemies/enemy.gd`(class Enemy)が全敵共通。種類は EnemyData(`data/enemies/*.tres`:kooni / aka_oni / ao_oni)で分ける。シーンは `kooni.tscn` 1つを使い回し、Arena が出現時に `add_child` の前で `data` を差し替える(`_ready` で読むため)。

| 状態 | すること |
|---|---|
| CHASE | 主人公へ `chase_speed` で直進(初期状態) |
| HURT | `knockback_time` の間ノックバック、`hurt_time` で CHASE |
| DOOMED | 一閃でHP0。止まって `fall()` を待つ |

- ContactHitbox は CHASE の間だけ有効(被弾硬直中は接触ダメージなし)
- 撃破時に `defeated(self)` を出して `queue_free()`(Arena が位置と `xp_value` で玉を落とす)。主人公は group `"player"` で探す
