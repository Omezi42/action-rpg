# unityroom 投稿用の文面

画像は `bash tools/export_web.sh` と同じく手元で作る(`build/` は git 管理外)。
- アップロードするゲーム:`build/unityroom/index.pck`(`bash tools/export_web.sh`)
- サムネイル:`build/promo/icon.gif`(288×288。一覧では144×144で出る)
- 紹介用GIF:`build/promo/gameplay.gif`(960×540)
- GIFの作り直し:`Godot --path . --script res://tools/capture_promo.gd`(紹介用)・`res://tools/promo_icon.gd`(サムネイル)→ `python tools/make_promo_gif.py`

## 登録する項目

| 項目 | 入れる内容 |
|---|---|
| タイトル | 居合サバイバー |
| エンジン | Godot |
| 画面サイズ | 960 × 540 |
| 想定時間 | 5分(1回の挑戦) |
| タグ | アクション / サバイバー / ローグライト / 和風 / ドット絵 |

## 一行紹介

溜めて、離して、斬り抜ける。群れを一直線にまとめて斬る、居合だけで戦う5分間のサバイバー。

## ゲーム紹介

四方から押し寄せる鬼の群れを、居合切りだけで斬り抜けて5分を生き残る見下ろし型アクションです。
最後に現れる大鬼を斬ればクリア。

攻撃は自動ではありません。
ボタンを押して溜め、離した瞬間に自分ごと一直線に踏み込み、通り道の敵をすべて斬ります。
溜めるほど遠くまで踏み込み、最大まで溜めた「瞬間」に離すと一閃。威力が倍になります。

◆ 群れを一列に並べて、まとめて斬る
一度にたくさん斬るほど「N人斬り」。
逃げ回って鬼を一列に並べ、岩や壁を使って群れを分け、最高の一太刀を狙ってください。

◆ 鬼ごとに違う斬り方
・赤鬼:速いが脆い。跳んで斬りかかってくる
・青鬼:硬くて遅い。正面を大きく薙ぎ払う
・弓鬼:離れて矢を撃つ
・盾鬼:正面からの居合を盾で弾く。回り込むか、一閃で押し通すか

◆ 挑戦ごとに違う育ち方
レベルアップで居合を強化。斬った線に斬撃を残す「斬痕」、止まった場所に衝撃波を出す「残心」、
納刀中に斬り返す「燕返し」、斬った敵を止める「影縫い」。条件をそろえると奥義に化けます。

◆ 負けても次につながる
挑戦で得た武功で、タイトル画面の「修行」から体や足を鍛えられます。

## 操作方法

| 操作 | キーボード+マウス | キーボードのみ | ゲームパッド |
|---|---|---|---|
| 移動 | WASD | WASD / 矢印 | 左スティック / 十字 |
| 居合(長押しで溜め、離して斬る) | 左クリック(カーソルの方向へ) | J / Space(移動キーの向きへ) | 下ボタン |
| 強化を選ぶ | クリック / 1・2・3 | 移動キーで選んで居合 / 1・2・3 | 左右で選んで下ボタン |
| 引き直し / 封じ | R / F | R / F | 左ボタン / 上ボタン |
| 修行(タイトル) | Tab | Tab | 上ボタン |
| ポーズ・音量 | Esc / P | Esc / P | Start |

※ 全画面表示中は Esc で全画面が解除されるので、ポーズは P を使ってください。
※ 音はゲーム画面をクリックすると鳴り始めます。

## 使用アセット

フォント
- PixelMplus10 / M+ FONTS PROJECT・itouhiro(M+ FONT LICENSE)https://github.com/itouhiro/PixelMplus

BGM
- Menu Music / wipics(CC0)https://opengameart.org/content/menu-music-2
- Taiko drums (seamless loop) / jobro(CC-BY 3.0)https://opengameart.org/content/taiko-drums-seamless-loop
- Samurai / TAD(CC-BY 4.0)https://opengameart.org/content/samurai

効果音
- Medieval Sound Effects - Weapon Textures / Ben Jaszczak & Brian Nelson(CC0)https://opengameart.org/content/medieval-sound-effects-weapon-textures
- 20 Sword Sound Effects (Attacks and Clashes) / StarNinjas(CC0)https://opengameart.org/content/20-sword-sound-effects-attacks-and-clashes
- Impact Sounds / Interface Sounds / RPG Audio / Music Jingles / Kenney(CC0)https://kenney.nl/

エンジン
- Godot Engine(MIT)https://godotengine.org/

## 実況ポリシー(投稿者が決める)

案:実況・配信・動画投稿は自由です。収益化も可。事前の連絡は不要です。
