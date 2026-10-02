# 3. 主人公と居合

## Player(`scripts/player/player.gd`)
状態は enum `State { MOVE, CHARGE, DASH, RETURN, SHEATHE, HURT, DEAD }` で持つ。

| 状態 | すること | 抜ける条件 |
|---|---|---|
| MOVE | 8方向移動(向きは入力を45°単位に丸める) | 居合を押す → CHARGE |
| CHARGE | 移動せず向きだけ更新、IaiCharge を進める。マウスで構えたら `cursor_direction()` がカーソルへの向きを返す | 離す → DASH |
| DASH | 向きへ `distance/duration` で `move_and_collide`。DashHitbox 有効、無敵 | 距離到達 or 壁 → SHEATHE |
| RETURN | 燕返しの斬り返し。直前の踏み込みの逆向きへ `return_distance()` を `PlayerData.return_time` で。DASH と同じく DashHitbox 有効・無敵 | 距離到達 or 壁 → SHEATHE |
| SHEATHE | 硬直。押された居合はバッファする。壱以上の DASH の後で `stats.return_distance > 0` なら、納刀中の押下で RETURN(1回の踏み込みにつき1回) | `sheathe_time` 経過 → MOVE(バッファがあれば即 CHARGE/抜き打ち) |
| HURT | ノックバック | `knockback_time` 経過 → MOVE |
| DEAD | 何もしない | — |

- 居合ボタンの押下は `Input.is_action_pressed` の前フレームとの差で取る(テストの `Input.action_press` でも動くため)
- 一閃の踏み込みでは DashHitbox の `delay_death` を立てる。HPが0になった敵は DOOMED で残り、`_doomed` に積んで納刀の終わり(または被弾)で `fall()` を呼ぶ
- ヒットストップは `Engine.time_scale = 0` + time_scale を無視するタイマー。連続ヒットはトークンで最後の1回だけが戻す
- カーソルの狙いはワールド座標(`get_global_mouse_position()`)で取る。構え中のカメラはカーソルとほぼ同じ向きへ寄るので、狙いの向きはぶれない
- マウスで構えたかは構え開始時の `Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)` で決める。カーソルが近すぎるときの遊び(`aim_deadzone`)は IaiData
- `aim_tip()`:構え中に今離したときの踏み込みの終点(壁は考えない)。FollowCamera が使う
- 踏み込みの予告線は子の `AimGuide`(`scenes/player/aim_guide.tscn`、`show_behind_parent`)。`charge.release()` の距離で描く
- 演出は `slashed(from, to, is_issen)` / `hit_landed(at)` を出すだけで、生成は Arena が行う
- 1回の踏み込みの区切りは `strike_started` / `strike_finished(is_issen)`。DASH に入る瞬間と、SHEATHE の終わり(`_release_doomed()` の後)に出す。RETURN を挟んでも1回として扱う。HURT で中断されたときも `strike_finished` を出す
- `is_striking()`:DASH か RETURN。魂の即取得・無敵・刀の見た目はこれで見る
- 押したまま斬り返しの納刀が終わったら CHARGE へ
- RETURN の威力は `PlayerData.return_power`、斬り返しでは `_spawn_followups()`(斬痕・残心)を呼ばない。`return_started` を出す(効果音)
- 影縫い:DashHitbox の当たりに `bind_time`(`stats.bind_time`)を載せ、Enemy の `_on_hurt` が被弾硬直の長さに使う。奥義 `stats.ougi_kage` なら、`_end_dash` / RETURN の終わりに、親(Entities)の子の Enemy のうち斬った線の左右 `PlayerData.kage_width` の矩形に入るものへ `Enemy.bind(time)` を呼ぶ
- 燕返し・極:`stats.ougi_tsubame` なら `return_distance()` は直前の踏み込みで実際に進んだ距離(壁で止まったらそこまで)

## 強化の反映
- `Player.stats`(PlayerStats)が強化の倍率・加算を持つ。移動は `move_speed * stats.move_speed_scale`
- 踏み込みの距離と威力は `strike_distance(strike)` / `strike_power(strike)` で出す(IaiStage は共有リソースなので書き換えない)。予告線もこれを使う
- `interrupt_input()`:レベルアップ画面を閉じたときに呼ぶ。構え中なら MOVE へ戻し、居合ボタンを「押しっぱなし」扱いにして一度離すまで効かなくする

## IaiCharge(`scripts/player/iai_charge.gd`)
押し時間 → 段階・一閃受付・ゲージの溜まり具合を返す純ロジック。段階に届く時間は `stats.charge_time_scale` 倍、一閃の受付は `stats.issen_window_bonus` を足す。数値は `data/iai.tres`(IaiData:`stages` は hold_time 昇順、`issen` は一閃用の IaiStage)。
