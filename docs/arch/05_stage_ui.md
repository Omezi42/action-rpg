# 5. 試作場・演出・UI

## Arena(`scripts/stage/arena.gd`)
- サバイバルの進行(GameDesign.md 1・5章)。数値は SurvivalData(`data/survival.tres`)
- `SpawnSchedule`(`scripts/stage/spawn_schedule.gd`、RefCounted)が経過時間・出現間隔・出現位置を計算する。Arena は毎物理フレーム `advance()` し、出現の番で生存数が `max_enemies_at()` 未満なら `enemy_scene` を生成し、`pick_enemy()` の EnemyData を入れる
- 区間は `SurvivalData.phases`(SpawnPhase:`start_time` / `interval_start` / `interval_end` / `max_enemies`、start_time 昇順)。区間の中で間隔を直線的に縮め、区間の終わりは次の区間の start_time(最後は clear_time)
- 大群は `SurvivalData.horde_times` の時刻ごとに `take_horde()` が true を返し、`horde_points()`(主人公から最も遠い辺の沿いに `horde_count` 体、`horde_spacing` 間隔)へ `horde_enemy` を上限を無視して出す
- 出現表は `SurvivalData.spawns`(SpawnEntry:`enemy` / `weight` / `start_time`、`scripts/data/spawn_entry.gd`)。`pick_enemy()` は `start_time` を過ぎた行から重みで抽選する。種類の追加は .tres の行を足すだけ
- フィールドは `SurvivalData.field_size`(原点が左上の矩形)。外周の壁・岩はシーンのコリジョンが唯一の情報源で、`survival_tests.gd` が壁が field_size を囲むことを確かめる
- 出現位置はカメラの映す矩形を `spawn_margin`(16)だけ広げた周上。field_size の外、または岩と重なる点(`PhysicsDirectSpaceState2D.intersect_point`、壁・岩のレイヤー)なら引き直す。映す矩形と岩の判定(`is_blocked` の Callable)は SpawnSchedule へ引数で渡す(テストで与えられるようにするため)。置ける点が無ければ `Vector2.INF` を返し、Arena はその回の出現を見送る
- 大群は映す矩形の4辺のうち、外側に field_size が最も広く残る辺の外側へ並べ、field_size からはみ出す分は内側へ詰める
- 精鋭鬼は `SurvivalData.elite_times` の時刻ごとに `SpawnSchedule.take_elite()` が true を返し、Arena が `pick_enemy()` の種類で `edge_center(view)` に出す(上限を無視)。倍率は `SurvivalData.elite_hp_scale` / `elite_visual_scale`。精鋭鬼の `defeated` で魂に加えて巻物(7章 Scroll)を落とす
- 人斬りの数は HitokiriCounter(`scripts/stage/hitokiri_counter.gd`、RefCounted)が数える。Arena が Player の `strike_started` / `strike_finished` と敵の `defeated` を渡し、`strike_finished` で数を返す。`min_count`(3)以上なら Arena が HitokiriLabel(`scripts/effects/hitokiri_label.gd`)を Effects へ足し、一閃で `shake_count`(5)以上なら `FollowCamera.shake()`。数値は `@export`。最大値は記録(8章)へ渡す
- 遠すぎる敵の消去は Enemy 自身が行う(4章)。消えた敵は `defeated` を出さない。生存数は `tree_exiting` で減らす(撃破と消去の両方を数えるため)
- 主人公の `died` または大鬼の `defeated` で終了:`get_tree().paused = true`、ポーズを `locked` にし、記録を保存して結果を出す(8章)
- カメラは Arena 直下の `FollowCamera`(`scripts/stage/follow_camera.gd`、Camera2D)。`limit_*` を field_size に合わせ、`position_smoothing` は使わず自前で補間して `round()` する。主人公が CHARGE の間は `player.aim_tip()`(予告線の先端)との中点へ `charge_pan_time`、それ以外は主人公へ `return_pan_time` で寄せる(切り替わった時点のずれから smoothstep で補間)。数値は `@export`。`view_rect()` が映す矩形を返す。`shake(amplitude, time)` は `offset` を整数ピクセルでランダムに揺らし、時間で0へ戻す
- 床は Arena の `_draw`(field_size の範囲に32px格子の市松)、壁・岩は `obstacle_drawer.gd` が子の RectangleShape2D をそのまま塗る(配置はコリジョンが唯一の情報源)
- 敵と主人公は `Entities`(y_sort)の下、演出は `Effects` の下
- `_ready` で `Engine.time_scale = 1`・`paused = false` に戻す(ヒットストップ中・結果表示中の再開に備える)

## UI
- `HUD/Hearts`:Health の `changed` を受けてハートを描く(HP2で1個)
- `HUD/RunStatus`(`scenes/ui/run_status.tscn`):右上にレベル・残り時間・撃破数
- `HUD/ExpBar`(`scenes/ui/exp_bar.tscn`):上端の経験値バー
- `LevelUp`(`scenes/ui/level_up_menu.tscn`):7章。巻物の3枚もこれで出す
- `GameOver`:結果表示(8章)。`process_mode = ALWAYS`
- `HUD/BossBar`(`scenes/ui/boss_bar.tscn`):大鬼のHP(8章)
- `Pause`:`process_mode = ALWAYS`。pause アクションで `get_tree().paused` を切り替える。`locked` の間(結果表示中・レベルアップ中)は無視
- 溜めゲージは主人公シーンの `ChargeGauge`(頭上、構え中だけ表示)

## タッチ操作(`scripts/ui/touch_controls.gd`、TouchControls)
- GameDesign.md 2章。autoload `TouchControlsLayer`(CanvasLayer、`process_mode = ALWAYS`、最前面)。外からは `TouchControls.active()`(autoload が無いテストでは false)
- `input_devices/pointing/emulate_mouse_from_touch` は切る(指がスティックに触れただけで左クリック=居合にならないため)。スティックの無い画面でボタンに当たらないタップは、グループ `touch_context` のうち `touch_tap(at)` を持つノード(Title:始める、TrainingMenu:その項目を買う、LevelUpMenu:そのカードを選ぶ)へ画面の座標で渡す。左クリックに作り直さないのは、デスクトップでは本物のカーソルの位置に上書きされるため
- 移動・居合・小ボタンは InputEventAction を `Input.parse_input_event` で流す(押した・離したの変わり目だけ)。各画面はキーやパッドと同じアクションとして受け取るので、画面側にタッチ専用の処理は持たない
- スティックは触れた点を中心に、指の向きを45度に丸めて上下左右のアクションへ分ける。半径・遊び・ボタンの位置と大きさは `@export`
- 画面ごとの小ボタンとスティックの有無は、グループ `touch_context` のノードが `touch_context() -> Dictionary`(`TouchControls.context(stick, buttons)` で作る。buttons は `[表示名, アクション]` の配列)で返し、TouchControls が毎フレーム集める。返すのは Title・TrainingMenu・PauseMenu(locked でない間はスティックあり)・LevelUpMenu・GameOver
- ウィンドウが縦長なら全面を暗くして「画面を横にしてください」を出す
