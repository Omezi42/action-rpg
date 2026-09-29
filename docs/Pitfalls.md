# 開発時の落とし穴

- `class_name` の登録は `.godot/`(git管理外)にある。新しい class_name を足した直後は `--import` しないとテストがコンパイル失敗のまま止まる(check.sh が自動で回す)
- テストで `Input.action_press` した入力は `is_action_just_pressed` では拾えないことがある。押した瞬間は前フレームの `is_action_pressed` との差で取る
- ヒットストップ(`Engine.time_scale = 0`)の間は物理フレームが進まない。テストでフレーム数を数えて待つときは踏み込み時間に余裕を持たせる
- Resource の既定値と同じ値は .tres に書き出されない。数値の既定値は 0 にして、実際の値は必ず .tres に置く
- ビルダーで InputEvent を作るときは `device = -1`(全デバイス)にする。既定の 0 だと1台目のパッドにしか反応しない
