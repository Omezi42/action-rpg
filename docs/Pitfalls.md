# 開発時の落とし穴

- `class_name` の登録は `.godot/`(git管理外)にある。新しい class_name を足した直後は `--import` しないとテストがコンパイル失敗のまま止まる(check.sh が自動で回す)
- テストで `Input.action_press` した入力は `is_action_just_pressed` では拾えないことがある。押した瞬間は前フレームの `is_action_pressed` との差で取る
- ヒットストップ(`Engine.time_scale = 0`)の間は物理フレームが進まない。テストでフレーム数を数えて待つときは踏み込み時間に余裕を持たせる
- Resource の既定値と同じ値は .tres に書き出されない。数値の既定値は 0 にして、実際の値は必ず .tres に置く
- ビルダーで InputEvent を作るときは `device = -1`(全デバイス)にする。既定の 0 だと1台目のパッドにしか反応しない
- カメラが動く画面でマウスの移動量(押した位置からの差など)を取るときは画面座標を使う。`get_global_mouse_position()` はカメラが動くとマウスを止めていても値が変わる
- preload した .tres の型付き配列(`Array[UpgradeData]` など)は、要素の型が class_name ではなくスクリプトとして推論され、`for x: UpgradeData in ...` や型付き引数への受け渡しがパースエラーになる。テストでは `var a: Array = res.list` で型なしにして回す
- パッチスクリプトでシーンを書き換えるとき、そのシーンのスクリプトがコンパイルに失敗している(新しい class_name を `--import` する前など)と、ルートの `script` と `@export` の値が黙って外れたまま保存される。先に `--import` し、パッチ後は `git diff` で `script =` が消えていないかを見る
- Resource のスクリプトに自分の型の配列(`Array[UpgradeData]` を UpgradeData 自身に)を持たせると、スクリプトが自分を参照し続けて終了時に「resources still in use」になる。`Array[Resource]` で持って使う側で `as` する
- 撮影・テストで `schedule.elapsed` を先へ飛ばすと、過ぎた精鋭鬼・大群が1フレームずつ出て魂や巻物を拾い、選択画面がツリーを止める。止まっている間は `_physics_process` が進まず大鬼も出ないので、待つ間は開いた選択画面を閉じ続ける
- BGM を鳴らしたままヘッドレスで終了すると、ときどき「resources still in use」(再生中の AudioStreamMP3)が出る。止める処理はオーディオスレッドで片付く前にエンジンが終わるので、終了時に `stop()` すると毎回出るようになる。終了時には止めない(ゲームの動作には影響しない)
- Web 書き出しではOSのフォントに頼れず、日本語が全部□になる(デスクトップでは Windows のフォントで補われて気づかない)。文字は同梱フォントで出す
- Web で `get_tree().quit()` するとエンジンが止まって画面が固まる。ブラウザの全画面中は Esc がゲームに届かない
