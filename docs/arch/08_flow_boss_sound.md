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

## 効果音・BGM・音量(GameDesign.md 10章)
- バスは `default_bus_layout.tres` の Master / BGM / SE。素材は `assets/audio/sfx/` `assets/audio/bgm/`(ogg・mp3)、出典は `assets/audio/CREDITS.md`
- autoload `SfxPlayer`(`scripts/audio/sfx.gd`、class_name `Sfx`)。鳴らす側は static の `Sfx.play(name)` を呼び、autoload が無いとき(`--script` のテスト)は何もしない。起動時に `data/sfx.tres`(SfxBank:名前 → SfxData)を読み、8個の AudioStreamPlayer(バス SE)を順に使う。起動時に `AudioSettings.load_saved().apply()` を呼ぶ
- SfxData(`scripts/data/sfx_data.gd`):`streams`(素材。空なら `wave` `freq_start` `freq_end` `duration` から AudioStreamWAV を合成)`volume_db` `min_interval` `pitch_shift`(半音)`pitch_jitter`(鳴らすたびに ±この半音の範囲で揺らす)。`streams` からは鳴らすたびにランダムに1つ選ぶ。音の追加は .tres に1行
- autoload `BgmPlayer`(`scripts/audio/bgm.gd`、class_name `Bgm`)。static の `Bgm.play(name)` / `Bgm.stop()`。`data/bgm.tres`(BgmBank:`tracks` 名前 → BgmData(`stream` `volume_db`)、`fade_time`、`duck_db`)。AudioStreamPlayer 2つ(バス BGM)を交互に使い、`fade_time` で入れ替える。同じ名前を続けて呼んでも鳴らし直さない。曲は読み込み時に `loop = true`。`get_tree().paused` の間は `duck_db` 下げる(process_mode ALWAYS)
- AudioSettings(`scripts/audio/audio_settings.gd`、RefCounted):`bgm` `se`(0〜`MAX_LEVEL`、既定 `DEFAULT_LEVEL`)。`ConfigFile` で `AudioSettings.path`(static。既定 `user://settings.cfg`)を読み書き。`apply()` でバス BGM / SE の音量を `level / MAX_LEVEL` の線形値で設定し、0 ならミュート
- 鳴らすきっかけは信号で受ける。Player の `stage_reached(index, is_top)` `dash_started` `issen_sheathed` `damaged`、大鬼の `rush_warned`(Arena は大鬼にだけつなぐ)・Enemy の `shot_fired`、Arena 側で斬撃・魂・レベルアップ・大鬼出現・大鬼撃破・精鋭出現・巻物・人斬り。Player の `return_started` で返し。Enemy の `guarded` で弾き。UI は決定・カーソル・購入を自分で鳴らす(カーソルは選ぶ項目が変わったときだけ)。結果画面は開いたときに BGM を止めてジングルを鳴らす
- BGM は Title の `_ready` で title、Arena の `_ready` で battle、`spawn_boss` で boss
- PauseMenu(`scripts/ui/pause_menu.gd`)は BGM / 効果音の2行をコードで足し、ポーズ中に move_up/down で選び move_left/right で変え、変えるたびに保存して `apply()` する
- Title は下端に CC-BY のクレジットを1行出す
