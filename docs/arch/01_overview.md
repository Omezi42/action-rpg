# 1. 構成

| 場所 | 中身 |
|---|---|
| `scenes/ui/title.tscn` | メインシーン(タイトル) |
| `scenes/stage/arena.tscn` | 1回の挑戦(アリーナ) |
| `scenes/player/player.tscn` / `scenes/enemies/kooni.tscn` / `oo_oni.tscn` | 主人公・小鬼(色違いの敵も共用)・大鬼 |
| `scripts/components/` | Health / Hitbox / Hurtbox |
| `scripts/data/` | Resource 定義(PlayerData / IaiStage / IaiData / EnemyData / SurvivalData / SpawnEntry / SpawnPhase / GrowthData / UpgradeData / SfxData / SfxBank / BgmData / BgmBank) |
| `data/` | 数値の実体(`player.tres` `iai.tres` `survival.tres` `growth.tres` `enemies/*.tres` `upgrades/*.tres` `sfx.tres` `bgm.tres`) |
| `scripts/growth/` | 成長(Progression / PlayerStats / SoulField / Scroll) |
| `scripts/effects/` | 斬撃の軌跡・ヒット火花・人斬りの文字(コード描画、シーン無し) |
| `scripts/ui/` | タイトル・ハート・結果・ポーズ・HPバー等 |
| `scripts/audio/` | 効果音・BGM・音量(autoload `SfxPlayer` `BgmPlayer`、AudioSettings) |
| `assets/audio/` | 効果音・BGMの素材(`sfx/` `bgm/`)と出典 `CREDITS.md` |
| `assets/fonts/` | `pixel_mplus10.res`(`tools/make_font.gd` が `src/` の ttf から作る)とライセンス |

- 画面は 480×270 を `stretch/mode=viewport` + `scale_mode=integer` で拡大(GameDesign.md 6章)
- 入力アクション:`move_left/right/up/down` `iai` `pause`(GameDesign.md 2章)
- 既定のフォントは `gui/theme/custom_font` = `pixel_mplus10.res`。FontFile に `fixed_size=10`・`FIXED_SIZE_SCALE_INTEGER_ONLY`・アンチエイリアス無しを焼き込む(インポート設定には固定サイズが無いため .res で持つ)。`src/` は `.gdignore` で書き出しに含めない

## Web書き出し(unityroom)
- unityroom には Web 書き出しの **pck だけ**を上げる(エンジン本体は unityroom 側)。Thread Support は未対応なので切る
- `export_presets.cfg` の「Web」:スレッド無し・GDExtension無し・`tools/` `docs/` `logs/` を除外
- `bash tools/export_web.sh` → `build/unityroom/index.pck`(アップロードする物)と `build/web/`(手元確認用の一式。`.claude/launch.json` の web-build で配信)。`build/` は git 管理外
- セーブの置き場所は Web だけ `application/config/custom_user_dir_name.web` で固有名にする。理由:同じドメインの Godot 製ゲームは IndexedDB を共有し、`config/name` の既定の置き場所がぶつかりうるため
- Web 版だけ変える動作は `OS.has_feature("web")` で分ける(タイトルの終了)
- 絵が届くまでは各 `*_visual.gd` が仮の図形を描く。足元が原点

## 物理レイヤー
| 番号 | 名前 | 使う物 |
|---|---|---|
| 1 | world | 壁・岩(StaticBody2D) |
| 2 | player_body | 主人公の体。mask は world だけ |
| 3 | enemy_body | 敵の体。mask は world だけ(主人公・敵同士はすり抜ける) |
| 4 | player_attack | 主人公の DashHitbox。敵の Hurtbox が mask する |
| 5 | enemy_attack | 敵の AttackHitbox・SweepAttack・矢。主人公の Hurtbox が mask する |
