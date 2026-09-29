# 1. 構成

| 場所 | 中身 |
|---|---|
| `scenes/stage/arena.tscn` | メインシーン(試作場) |
| `scenes/player/player.tscn` / `scenes/enemies/kooni.tscn` | 主人公・小鬼 |
| `scripts/components/` | Health / Hitbox / Hurtbox |
| `scripts/data/` | Resource 定義(PlayerData / IaiStage / IaiData / EnemyData) |
| `data/` | 数値の実体(`player.tres` `iai.tres` `enemies/kooni.tres`) |
| `scripts/effects/` | 斬撃の軌跡・ヒット火花(コード描画、シーン無し) |
| `scripts/ui/` | ハート・ゲームオーバー・ポーズ |

- 画面は 480×270 を `stretch/mode=viewport` + `scale_mode=integer` で拡大(GameDesign.md 6章)
- 入力アクション:`move_left/right/up/down` `iai` `pause`(GameDesign.md 2章)
- 絵が届くまでは各 `*_visual.gd` が仮の図形を描く。足元が原点

## 物理レイヤー
| 番号 | 名前 | 使う物 |
|---|---|---|
| 1 | world | 壁・岩(StaticBody2D) |
| 2 | player_body | 主人公の体。mask は world だけ |
| 3 | enemy_body | 敵の体。mask は world だけ(主人公・敵同士はすり抜ける) |
| 4 | player_attack | 主人公の DashHitbox。敵の Hurtbox が mask する |
| 5 | enemy_attack | 敵の ContactHitbox。主人公の Hurtbox が mask する |
