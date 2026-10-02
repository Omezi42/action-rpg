# 6. 検証

- `bash tools/check.sh`(引数なしは変更された .gd だけ、`--all` で全部):gdformat → gdlint → `tools/tests/run_tests.gd` → 起動スモーク
- テスト:`iai_tests.gd`(段階判定)、`combat_tests.gd`(実シーンで居合・一閃・接触被弾。敵AIは止める)、`survival_tests.gd`(区間の出現間隔・上限・大群・出現位置・壁と岩の配置・追従カメラ・追跡・遠い敵の消去・クリアで停止)、`growth_tests.gd`(経験値の曲線・カードの選び方・強化の反映・魂の吸い寄せと踏み込みでの取得・レベルアップで止まる)、`flow_tests.gd`(最高記録・大鬼の突進・結果の新記録)。survival_tests は大鬼を倒してのクリアも見る
- 撮影:`Godot --path . --script res://tools/capture.gd`(ウィンドウあり)で `logs/shot_*.png`(タイトル・起動直後・フィールドの角・群れと大群・予告線・一閃・魂・レベルアップ画面・大鬼・突進の予告・結果表示)
- `.tscn` の変更は `tools/godot_apply_patch.gd`(headless-godot-skill-kit)経由
