# 5. 試作場・演出・UI

## Arena(`scripts/stage/arena.gd`)
- `SpawnPoints` の Marker2D ごとに `enemy_scene` を生成。全滅したら `respawn_delay` 秒後に同じ位置へ再生成
- 床は Arena の `_draw`、壁・岩は `obstacle_drawer.gd` が子の RectangleShape2D をそのまま塗る(配置はコリジョンが唯一の情報源)
- 敵と主人公は `Entities`(y_sort)の下、演出は `Effects` の下
- `_ready` で `Engine.time_scale = 1` に戻す(ヒットストップ中の再開に備える)

## UI
- `HUD/Hearts`:Health の `changed` を受けてハートを描く(HP2で1個)
- `GameOver`:主人公の `died` で表示、居合ボタンで `reload_current_scene()`
- `Pause`:`process_mode = ALWAYS`。pause アクションで `get_tree().paused` を切り替える
- 溜めゲージは主人公シーンの `ChargeGauge`(頭上、構え中だけ表示)
