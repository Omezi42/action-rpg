# 3. 主人公と居合

## Player(`scripts/player/player.gd`)
状態は enum `State { MOVE, CHARGE, DASH, SHEATHE, HURT, DEAD }` で持つ。

| 状態 | すること | 抜ける条件 |
|---|---|---|
| MOVE | 8方向移動(向きは入力を45°単位に丸める) | 居合を押す → CHARGE |
| CHARGE | 移動速度×`charge_move_ratio`、IaiCharge を進める | 離す → DASH |
| DASH | 向きへ `distance/duration` で `move_and_collide`。DashHitbox 有効、無敵 | 距離到達 or 壁 → SHEATHE |
| SHEATHE | 硬直。押された居合はバッファする | `sheathe_time` 経過 → MOVE(バッファがあれば即 CHARGE/抜き打ち) |
| HURT | ノックバック | `knockback_time` 経過 → MOVE |
| DEAD | 何もしない | — |

- 居合ボタンの押下は `Input.is_action_pressed` の前フレームとの差で取る(テストの `Input.action_press` でも動くため)
- 一閃の踏み込みでは DashHitbox の `delay_death` を立てる。HPが0になった敵は DOOMED で残り、`_doomed` に積んで納刀の終わり(または被弾)で `fall()` を呼ぶ
- ヒットストップは `Engine.time_scale = 0` + time_scale を無視するタイマー。連続ヒットはトークンで最後の1回だけが戻す
- 演出は `slashed(from, to, is_issen)` / `hit_landed(at)` を出すだけで、生成は Arena が行う

## IaiCharge(`scripts/player/iai_charge.gd`)
押し時間 → 段階・一閃受付・ゲージの溜まり具合を返す純ロジック。数値は `data/iai.tres`(IaiData:`stages` は hold_time 昇順、`issen` は一閃用の IaiStage)。
