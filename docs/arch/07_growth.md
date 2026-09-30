# 7. 成長(GameDesign.md 8章)

## データ
| クラス | 場所 | 中身 |
|---|---|---|
| UpgradeData | `scripts/data/upgrade_data.gd` → `data/upgrades/*.tres` | 名前・説明・上限・`stat` と `mode`(ADD / MULTIPLY)と `amount`、`heal`(手当用) |
| GrowthData | `scripts/data/growth_data.gd` → `data/growth.tres` | 必要点数の式・吸い寄せ・3択の枚数と選べない時間・手当の UpgradeData・斬痕の数値・強化を探すフォルダ |
| EnemyData.xp_value | `data/enemies/*.tres` | 倒したときの玉の点数 |
| PlayerData.pickup_radius | `data/player.tres` | 回収範囲の基準 |

- 強化の候補は `GrowthData.upgrade_dir`(`res://data/upgrades`)にある .tres 全部。`Growth.load_pool()` が `ResourceLoader.list_directory` で集める(書き出し後の .remap でも動くため)
- 手当は候補のフォルダに置かず `GrowthData.filler` で持つ(上限なし・候補が足りないときだけ出すため)

## 能力値(PlayerStats、`scripts/player/player_stats.gd`)
主人公の強化後の値を StringName → float で持つ。`apply(upgrade)` が `mode` に従って足す / 掛ける。基準値は ADD 系 0、倍率系 1。

| stat | 使う所 |
|---|---|
| `power_bonus` | Player が踏み込みの威力に足す |
| `hold_scale` | IaiCharge が各段階の到達時間に掛ける |
| `issen_window_bonus` | IaiCharge が一閃の受付に足す |
| `distance_scale` | Player が踏み込み距離に掛ける(時間は据え置き=速くなる)。予告線も同じ値 |
| `move_speed_scale` | Player の移動速度に掛ける |
| `pickup_scale` | `Player.pickup_radius()` に掛ける |
| `lingering_level` | 0 より大きければ Arena が斬痕を出す |

- 数値だけの強化は .tres を足すだけで増える。新しい stat を足すときだけ、それを読むコードが要る
- `Player.apply_upgrade()` が stats を更新し IaiCharge へ反映する。`heal` が正なら回復だけする

## 進行(Growth、`scripts/stage/growth.gd`、RefCounted)
- `xp` `level` `pending`(まだ選んでいないレベルアップの数)と、強化ごとの段を持つ
- `add_xp(n)` は余りを持ち越してレベルを上げ、上がった数を返す。`roll_choices()` は上限未満の候補をシャッフルして3つ、足りなければ手当を1枚足す。`take(upgrade)` で段を上げ `pending` を減らす

## 経験値の玉(XpOrb、`scripts/stage/xp_orb.gd`、シーン無し)
- Arena が敵の `defeated(enemy)` で倒れた位置に生成し、`Pickups`(Entities の前)に入れる
- 毎物理フレーム主人公との距離を見て、`pickup_radius()` 以内に入ったら吸い寄せを始める(以後は範囲外でも追う)。`collect_distance` 以内で `collected(value)` を出して消える
- 踏み込み中も同じ処理なので、通過線の近くの玉は拾われる

## 斬痕(LingeringSlash、`scripts/player/lingering_slash.gd`、Hitbox を継承)
- Arena が主人公の `slashed` で `lingering_level > 0` のとき `Effects` に生成する。踏み込みの線に SegmentShape2D を張り、layer は player_attack
- 体の高さ(足元 −10px)にずらす。理由:敵の Hurtbox が足元より上にあるため
- `hit_once_per_activation` で1本につき同じ敵へ1度。寿命が来たら消える。ヒットストップは入れない

## 3択(Arena ↔ UpgradeMenu)
- Arena は `collected` で `growth.add_xp()`。上がったら `get_tree().paused = true`・ポーズを `locked` にして `HUD/UpgradeMenu` を開く
- UpgradeMenu(`scripts/ui/upgrade_menu.gd`、Control、`process_mode = ALWAYS`)は札をコード描画し、`chosen(upgrade)` を出す。開いて `choose_lock_time` の間は入力を無視する
  - マウスのボタンは札の上のときだけ扱う(`iai` に左クリックが入っているため、札の外のクリックで決まらないように)
  - `move_left/right` で選び、`iai` で決める。`choose_1〜3` で直接選ぶ
- Arena は `chosen` で `growth.take()` → `player.apply_upgrade()`。`pending` が残っていれば引き直して開き、無ければ再開し `player.resync_input()`(止まっている間に押した居合を「押した瞬間」と取り違えないため)
- `HUD/XpBar`(`scripts/ui/xp_bar.gd`)が上端にレベルと経験値のバーを描く
