# 7. 成長

GameDesign.md 8章。数値は GrowthData(`data/growth.tres`)、強化1種は UpgradeData(`data/upgrades/*.tres`)。

## UpgradeData(`scripts/data/upgrade_data.gd`)
`label` `description` `stat`(enum Stat:CHARGE_TIME / DASH_DISTANCE / POWER / ISSEN_WINDOW / MOVE_SPEED / MAX_HP / HEAL / LINGER / SHOCKWAVE / RETURN_SLASH / SHADOW_BIND / FULL_HEAL / OUGI_HOMURA / OUGI_DAIZANSHIN / OUGI_TSUBAME / OUGI_KAGE)`amount` `max_level`。
同じ種類の数値違いは .tres を足すだけ。新しい種類は Stat と `Progression.take()` に1行足す。
- `kind`(enum Kind:STAT / BEHAVIOR / OUGI)。BEHAVIOR は巻物の候補、OUGI はレベルアップに出ない
- 奥義は `requires: Array[UpgradeData]`(すべて `max_level` に達していれば巻物に出る)。`max_level = 1`
- 影縫いの1段目と以後の差があるので、`base_amount`(1段目の値。0なら `amount`)を持つ

## PlayerStats(`scripts/growth/player_stats.gd`、RefCounted)
強化の合計(`charge_time_scale` `distance_scale` `power_bonus` `issen_window_bonus` `move_speed_scale` `linger_time` `shockwave_radius` `return_distance` `bind_time`)と奥義の旗(`ougi_homura` `ougi_daizanshin` `ougi_tsubame` `ougi_kage`)。Player と IaiCharge が読む。

## 斬痕・残心(`scripts/player/lingering_slash.gd` / `scripts/player/shockwave.gd`、どちらも Hitbox)
- Player が壱以上の踏み込みの終わり(`_end_dash`)に、`stats` が0より大きいものだけ生成して自分の親(Entities)へ足す。コリジョンはコードで作る
- 威力は `PlayerData.linger_power` / `shockwave_power`、衝撃波の広がる時間は `shockwave_time`
- 当たっても Player の `_on_dash_landed` は通らないので、ヒットストップと一閃の遅延撃破は起きない
- 焔痕:LingeringSlash の威力を `PlayerData.homura_power`、残る時間を `homura_time_scale` 倍。大残心:Shockwave が `PlayerData.daizanshin_delay` 後にもう1回広がる

## Progression(`scripts/growth/progression.gd`、RefCounted)
- `level` `exp` `pending`(選び待ちのレベルアップ数)と強化ごとの段階を持つ
- `add_exp(n)`:足りた分だけ level と pending を上げる。`exp_to_next()` は `exp_base + exp_step × (level − 1)`
- `roll_choices()`:最大でない強化から `choice_count` 枚。無ければ `[heal]`
- `take(upgrade, player)`:段階を上げ、PlayerStats か Health に反映して pending を1減らす(巻物から取ったときは減らさない)
- `roll_scroll()`:条件を満たした未取得の奥義を先に、残りを最大でない BEHAVIOR から、合わせて `GrowthData.scroll_pick_count`(2)枚。末尾に `GrowthData.full_heal` を足す
- `scroll_count`:拾って選び待ちの巻物の数

## SoulField(`scripts/growth/soul_field.gd`、Node2D)
- 魂を1ノードで持ち(位置と経験値の配列)、自分の `_draw` でまとめて描く。理由:最大200個をノードにしないため
- `Entities` の子(y_sort、原点に置くので敵・主人公より奥に描かれる)
- 毎物理フレーム:主人公が踏み込み中なら半径内を即取得、それ以外は半径内を `pull_speed` で寄せて `collect_distance` 以内で取得。`collected(value)` を出す
- `drop()` で `max_souls` を超えたら古いものから `collected` を出して消す
- 主人公は Arena が `player` に入れる

## Scroll(`scripts/growth/scroll.gd`、Node2D)
- Arena が精鋭鬼の倒れた位置に Entities へ足す。巻物の絵はコード描画
- 毎物理フレーム主人公との距離が `pickup_radius`(16、`@export`)以内なら `picked` を出して消える
- Arena:`picked` → `scroll_count += 1` → レベルアップと同じく止めて `open(roll_scroll(), levels, true)`。巻物の選び待ちはレベルアップより先に出す

## レベルアップ画面(`scripts/ui/level_up_menu.gd`、CanvasLayer・process_mode ALWAYS)
- `open(choices, levels, is_scroll := false)`:カードを作り直して表示。`chosen(upgrade)` を出して閉じる。`is_scroll` なら上に「巻物」と出す。UpgradeCard は `kind == OUGI` なら金の枠
- 開いてから `choose_lock_time` の間は入力を無視する(ツリー停止中・ヒットストップ中でも進むよう `Time.get_ticks_msec()` で測る)
- クリック(カード矩形)・1/2/3 キー・move_left/right + iai で選ぶ
- Arena:`collected` → `add_exp` → pending があれば `paused = true`・ポーズを locked にして開く。`chosen` → `take` → まだ pending があれば次の3枚、無ければ閉じて再開し `player.interrupt_input()`
