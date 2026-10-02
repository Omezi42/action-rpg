# 8. 画面の流れ・ボス・効果音

## 画面の流れ(GameDesign.md 9章)
- メインシーンは `scenes/ui/title.tscn`(`scripts/ui/title.gd`)。居合で `change_scene_to_file(arena)`、training(Tab)で修行(7章)、pause(Esc)で `quit()`
- 入力の受付開始は `Time.get_ticks_msec()` で測る(`input_lock_time` は `@export`)
- `GameOver`(結果)は iai でもう一度(`reload_current_scene()`)、pause でタイトルへ

## RunRecords(`scripts/stage/run_records.gd`、RefCounted)
- `ConfigFile` で `RunRecords.path`(static。既定 `user://records.cfg`)を読み書きする。読めなければ全項目0
- `submit(survived, kills, level, cleared, hitokiri)`:更新した項目名(`best_time` `best_kills` `best_level` `best_hitokiri`)の配列を返し、保存する
- テストと撮影は開始時に `RunRecords.path` を別のファイルへ向け、終わりに消す(本物の記録に触れないため)

## 大鬼(GameDesign.md 5章)
- 突進は敵の踏み込み攻撃(4章 `WINDUP` / `RUSH` / `RECOVER`)を大きくしたもの。`attack_armor = true` で予告・突進・隙の間は斬られても状態を変えず光るだけ。`hold_range = 0` で立ち止まらずに追う
- シーンは `scenes/enemies/oo_oni.tscn`(小鬼のシーンを Visual 2倍・判定2倍にしたもの + 予告線の `RushGuide`)
- Arena の `boss_scene`、SurvivalData の `boss_spawn_interval` / `boss_max_enemies`。SpawnSchedule は `clear_time` 以降を大鬼の区間として扱い(`is_boss_time()`)、`take_boss()` は1度だけ true
- 出現位置は `edge_center(view)`(大群と同じ辺の中央。大群と共通の `line_points()`)
- Arena は大鬼の `defeated` でクリア。生存時間はその時刻。`HUD/BossBar`(`scripts/ui/boss_bar.gd`)が大鬼の Health を描く

## 効果音(GameDesign.md 10章)
- autoload `SfxPlayer`(`scripts/audio/sfx.gd`、class_name `Sfx`)。鳴らす側は static の `Sfx.play(name)` を呼び、autoload が無いとき(`--script` のテスト)は何もしない。起動時に `data/sfx.tres`(SfxBank:名前 → SfxData)から AudioStreamWAV を合成し、8個の AudioStreamPlayer を順に使う
- SfxData(`scripts/data/sfx_data.gd`):`wave`(SQUARE / TRIANGLE / NOISE)`freq_start` `freq_end` `duration` `volume_db`。音の追加は .tres に1行
- 鳴らすきっかけは信号で受ける。Player の `stage_reached(index, is_top)` `dash_started` `issen_sheathed` `damaged`、大鬼の `rush_warned`(Arena は大鬼にだけつなぐ)・Enemy の `shot_fired`、Arena 側で斬撃・魂・レベルアップ・大鬼出現・精鋭出現・巻物・人斬り。Player の `return_started` で返し。UI は決定時に自分で鳴らす
