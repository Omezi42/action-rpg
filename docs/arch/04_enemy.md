# 4. 敵

`scripts/enemies/enemy.gd`(class Enemy)が全敵共通。種類は EnemyData(`data/enemies/*.tres`)とシーンで分け、色違いは `color` だけ変えた .tres で作る。

| 状態 | すること |
|---|---|
| CHASE | 主人公へ `chase_speed` で直進(初期状態) |
| HURT | `knockback_time` の間ノックバック、`hurt_time` で CHASE |
| DOOMED | 一閃でHP0。止まって `fall()` を待つ |

- ContactHitbox は CHASE の間だけ有効(被弾硬直中は接触ダメージなし)
- 撃破時に `defeated` を出して `queue_free()`。主人公は group `"player"` で探す
