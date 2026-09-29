# 6. 検証

- `bash tools/check.sh`(引数なしは変更された .gd だけ、`--all` で全部):gdformat → gdlint → `tools/tests/run_tests.gd` → 起動スモーク
- テスト:`iai_tests.gd`(段階判定)、`combat_tests.gd`(実シーンで居合・一閃・接触被弾。敵AIは止める)、`survival_tests.gd`(出現間隔・出現位置・追跡・クリアで停止)
- 撮影:`Godot --path . --script res://tools/capture.gd`(ウィンドウあり)で `logs/shot_*.png`(群れ・予告線・一閃・結果表示の7枚)
- `.tscn` の変更は `tools/godot_apply_patch.gd`(headless-godot-skill-kit)経由
