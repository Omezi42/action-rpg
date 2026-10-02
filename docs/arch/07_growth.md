# 7. 成長

GameDesign.md 8章。数値は GrowthData(`data/growth.tres`)、強化1種は UpgradeData(`data/upgrades/*.tres`)。

## UpgradeData(`scripts/data/upgrade_data.gd`)
`label` `description` `stat`(enum Stat:CHARGE_TIME / DASH_DISTANCE / POWER / ISSEN_WINDOW / MOVE_SPEED / MAX_HP / HEAL / LINGER / SHOCKWAVE / FULL_HEAL / RETURN_SLASH / SHADOW_BIND / OUGI_HOMURA / OUGI_DAIZANSHIN / OUGI_TSUBAME / OUGI_KAGE)`amount` `max_level`。
同じ種類の数値違いは .tres を足すだけ。新しい種類は Stat と `Progression.take()` に1行足す。
- `kind`(enum Kind:STAT / BEHAVIOR / OUGI)。BEHAVIOR は巻物の候補、OUGI はレベルアップに出ない
- 奥義は `requires: Array[Resource]`(中身は UpgradeData。すべて `max_level` に達していれば巻物に出る)。`max_level = 1`
- 影縫いの1段目と以後の差があるので、`base_amount`(1段目の値。0なら `amount`)を持つ

## PlayerStats(`scripts/growth/player_stats.gd`、RefCounted)
強化の合計(`charge_time_scale` `distance_scale` `power_bonus` `issen_window_bonus` `move_speed_scale` `linger_time` `shockwave_radius` `return_distance` `bind_time`)と奥義の旗(`ougi_homura` `ougi_daizanshin` `ougi_tsubame` `ougi_kage`)。Player と IaiCharge が読む。

## 斬痕・残心(`scripts/player/lingering_slash.gd` / `scripts/player/shockwave.gd`、どちらも Hitbox)
- Player が壱以上の踏み込みの終わり(`_end_dash`)に、`stats` が0より大きいものだけ生成して自分の親(Entities)へ足す。コリジョンはコードで作る
- 威力は `PlayerData.linger_power` / `shockwave_power`、衝撃波の広がる時間は `shockwave_time`
- 当たっても Player の `_on_dash_landed` は通らないので、ヒットストップと一閃の遅延撃破は起きない
- 焔痕:LingeringSlash の威力を `PlayerData.homura_power`、残る時間を `homura_time_scale` 倍。大残心:Shockwave が `PlayerData.daizanshin_delay` 後に同じ位置・半径・威力の Shockwave を1つ足す(当たりは新しく数える)

## Progression(`scripts/growth/progression.gd`、RefCounted)
- `level` `exp` `pending`(選び待ちのレベルアップ数)と強化ごとの段階を持つ
- `add_exp(n)`:足りた分だけ level と pending を上げる。`exp_to_next()` は `exp_base + exp_step × (level − 1)`
- `roll_choices()`:最大でない強化から `choice_count` 枚。無ければ `[heal]`
- `take(upgrade, player)`:段階を上げ、PlayerStats か Health に反映して pending を1減らす(巻物から取ったときは減らさない)
- `roll_scroll()`:条件を満たした未取得の奥義(`GrowthData.ougi`)を先に、残りを最大でない BEHAVIOR から、合わせて `GrowthData.scroll_pick_count`(2)枚。末尾に `GrowthData.full_heal`(`data/upgrades/zenkaifuku.tres`、Stat FULL_HEAL)を足す
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
- Arena:`picked` → `scroll_count += 1` → `_open_choices()`。魂の取得も同じ入口を通り、`scroll_count` が残っていれば巻物を、無ければレベルアップを開く。`_choosing_scroll` で `take(…, from_scroll)` を切り替える
- Arena は巻物を `call_deferred` で足す(敵の `defeated` は物理のコールバック中に出るため)

## レベルアップ画面(`scripts/ui/level_up_menu.gd`、CanvasLayer・process_mode ALWAYS)
- `open(choices, levels, is_scroll := false)`:カードを作り直して表示。`chosen(upgrade)` を出して閉じる。`is_scroll` なら上に「巻物」と出す。UpgradeCard は `kind == OUGI` なら金の枠
- 開いてから `choose_lock_time` の間は入力を無視する(ツリー停止中・ヒットストップ中でも進むよう `Time.get_ticks_msec()` で測る)
- クリック(カード矩形)・1/2/3 キー・move_left/right + iai で選ぶ
- Arena:`collected` → `add_exp` → pending があれば `paused = true`・ポーズを locked にして開く。`chosen` → `take` → まだ pending があれば次の3枚、無ければ閉じて再開し `player.interrupt_input()`

## 引き直し・封じ(Progression)
- `rerolls_left` `seals_left`(挑戦の始めに修行から入れる)と、封じた強化の一覧を持つ。`roll_choices()` / `roll_scroll()` は封じた強化を候補から外す
- `can_seal(upgrade)`:残りがあり、`heal` / `full_heal` でないとき true。`seal(upgrade)` で一覧に足して残りを1減らす
- `replace_choice(choices, index, is_scroll)`:その位置を、今の画面と同じ選び方の候補(画面に出ていないもの)から1枚と入れ替えた配列を返す。候補が無ければ消す。レベルアップで0枚になったら `[heal]`
- レベルアップ画面は `open(choices, levels, is_scroll, rerolls, seals, selected)` で、残りがあれば下に「R 引き直し 残りN」「F 封じ 残りN」を出す。入力 `reroll` / `seal` で `reroll_requested` / `seal_requested(index)` を出すだけで、判断は Arena(`_on_reroll` / `_on_seal`)が行い、画面を開き直す(誤操作防止の時間も測り直す)

## 修行(GameDesign.md 8章「修行」)
- TrainingData(`scripts/data/training_data.gd`、`data/training/*.tres`):`id`(保存の鍵)`label` `description` `effect`(enum Effect:MAX_HP / MOVE_SPEED / REROLL / SEAL)`amount` `costs`(段ごとの値段。段数 = `costs.size()`)
- TrainingCatalog(`scripts/data/training_catalog.gd`、`data/training.tres`):`items` と武功の式の数値 `kills_per_merit` `merit_per_level` `clear_merit`。`reward(kills, level, cleared)` で1回の武功を返す
- TrainingProgress(`scripts/growth/training_progress.gd`、RefCounted):`merit` と段階(id → 段)。RunRecords と同じく static の `path`(既定 `user://progress.cfg`)を読み書きし、読めなければ0。`next_cost(item)`(最大なら −1)・`buy(item)`・`refund_all(catalog)`・`total(catalog, effect)`(amount × 段の合計)・`apply(catalog, player, progression)`
- Arena:`_ready` で読み込んで `apply`(Health の `raise_max`・`PlayerStats.move_speed_scale`・Progression の残り回数)。`_end` で武功を足して保存し、結果画面へ渡す
- タイトル:武功を出す。入力 `training` で TrainingMenu(`scripts/ui/training_menu.gd`、Control、コードで足す)を開き、閉じるまでタイトル自身の入力を止める。TrainingMenu は上下で選び iai で買い、`reroll` で全部戻し、`pause` で `closed` を出す
- 入力 `reroll`(R・パッド左)`seal`(F・パッド上)`training`(Tab・パッド上)
- テストと撮影は `TrainingProgress.path` も別のファイルへ向ける
