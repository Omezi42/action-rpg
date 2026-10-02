# 1. 構成

| 場所 | 中身 |
|---|---|
| `scenes/ui/title.tscn` | メインシーン(タイトル) |
| `scenes/stage/arena.tscn` | 1回の挑戦(アリーナ) |
| `scenes/player/player.tscn` / `scenes/enemies/kooni.tscn` / `oo_oni.tscn` | 主人公・小鬼(色違いの敵も共用)・大鬼 |
| `scripts/components/` | Health / Hitbox / Hurtbox |
| `scripts/data/` | Resource 定義(PlayerData / IaiStage / IaiData / EnemyData / SurvivalData / SpawnEntry / SpawnPhase / GrowthData / UpgradeData / SfxData / SfxBank) |
| `data/` | 数値の実体(`player.tres` `iai.tres` `survival.tres` `growth.tres` `enemies/*.tres` `upgrades/*.tres` `sfx.tres`) |
| `scripts/growth/` | 成長(Progression / PlayerStats / SoulField / Scroll) |
| `scripts/effects/` | 斬撃の軌跡・ヒット火花・人斬りの文字(コード描画、シーン無し) |
| `scripts/ui/` | タイトル・ハート・結果・ポーズ・HPバー等 |
| `scripts/audio/` | 効果音の合成と再生(autoload `SfxPlayer`) |

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
| 5 | enemy_attack | 敵の AttackHitbox・SweepAttack・矢。主人公の Hurtbox が mask する |
