# 5. 試作場・演出・UI

## Arena(`scripts/stage/arena.gd`)
- サバイバルの進行(GameDesign.md 1・5章)。数値は SurvivalData(`data/survival.tres`)
- `SpawnSchedule`(`scripts/stage/spawn_schedule.gd`、RefCounted)が経過時間・出現間隔・出現位置を計算する。Arena は毎物理フレーム `advance()` し、出現の番で生存数が `max_enemies_at()` 未満なら `enemy_scene` を生成し、`pick_enemy()` の EnemyData を入れる
- 区間は `SurvivalData.phases`(SpawnPhase:`start_time` / `interval_start` / `interval_end` / `max_enemies`、start_time 昇順)。区間の中で間隔を直線的に縮め、区間の終わりは次の区間の start_time(最後は clear_time)
- 大群は `SurvivalData.horde_times` の時刻ごとに `take_horde()` が true を返し、`horde_points()`(主人公から最も遠い辺の沿いに `horde_count` 体、`horde_spacing` 間隔)へ `horde_enemy` を上限を無視して出す
- 出現表は `SurvivalData.spawns`(SpawnEntry:`enemy` / `weight` / `start_time`、`scripts/data/spawn_entry.gd`)。`pick_enemy()` は `start_time` を過ぎた行から重みで抽選する。種類の追加は .tres の行を足すだけ
- 出現位置は画面矩形を `spawn_margin` だけ縮めた周上。主人公から `spawn_min_player_distance` 以内なら引き直す
- 主人公の `died` または `is_cleared()` で終了:`get_tree().paused = true`、ポーズを `locked` にし、結果を出す
- 床は Arena の `_draw`、壁・岩は `obstacle_drawer.gd` が子の RectangleShape2D をそのまま塗る(配置はコリジョンが唯一の情報源)
- 敵と主人公は `Entities`(y_sort)の下、演出は `Effects` の下
- `_ready` で `Engine.time_scale = 1`・`paused = false` に戻す(ヒットストップ中・結果表示中の再開に備える)

## UI
- `HUD/Hearts`:Health の `changed` を受けてハートを描く(HP2で1個)
- `HUD/RunStatus`(`scenes/ui/run_status.tscn`):右上にレベル・残り時間・撃破数
- `HUD/ExpBar`(`scenes/ui/exp_bar.tscn`):上端の経験値バー
- `LevelUp`(`scenes/ui/level_up_menu.tscn`):7章
- `GameOver`:結果表示(ゲームオーバー / クリア・生存時間・撃破数・到達レベル)。`process_mode = ALWAYS`、居合ボタンで `reload_current_scene()`
- `Pause`:`process_mode = ALWAYS`。pause アクションで `get_tree().paused` を切り替える。`locked` の間(結果表示中・レベルアップ中)は無視
- 溜めゲージは主人公シーンの `ChargeGauge`(頭上、構え中だけ表示)
