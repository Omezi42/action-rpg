extends SceneTree
## ヘッドレステストの入口。個々のスイートは別ファイルに置き、ここは呼び出しと判定だけを持つ。

const IaiTests = preload("res://tools/tests/iai_tests.gd")
const CombatTests = preload("res://tools/tests/combat_tests.gd")
const SurvivalTests = preload("res://tools/tests/survival_tests.gd")
const GrowthTests = preload("res://tools/tests/growth_tests.gd")
const FlowTests = preload("res://tools/tests/flow_tests.gd")
const EnemyAttackTests = preload("res://tools/tests/enemy_attack_tests.gd")
const TrainingTests = preload("res://tools/tests/training_tests.gd")
const ShieldTests = preload("res://tools/tests/shield_tests.gd")
const AudioTests = preload("res://tools/tests/audio_tests.gd")
const TouchTests = preload("res://tools/tests/touch_tests.gd")
## 本物の最高記録に触れないよう、テスト中の記録はここへ書く
const TEST_RECORDS_PATH := "user://test_records.cfg"
const TEST_PROGRESS_PATH := "user://test_progress.cfg"
const TEST_SETTINGS_PATH := "user://test_settings.cfg"

var _failures := 0
var _checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	RunRecords.path = TEST_RECORDS_PATH
	TrainingProgress.path = TEST_PROGRESS_PATH
	AudioSettings.path = TEST_SETTINGS_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PROGRESS_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_RECORDS_PATH))
	IaiTests.new().run(_assert_true)
	await CombatTests.new().run(self, _assert_true)
	await SurvivalTests.new().run(self, _assert_true)
	await GrowthTests.new().run(self, _assert_true)
	await FlowTests.new().run(self, _assert_true)
	await EnemyAttackTests.new().run(self, _assert_true)
	await TrainingTests.new().run(self, _assert_true)
	await ShieldTests.new().run(self, _assert_true)
	AudioTests.new().run(self, _assert_true)
	await TouchTests.new().run(self, _assert_true)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PROGRESS_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_RECORDS_PATH))
	if _failures == 0:
		print("tests passed (%d checks)" % _checks)
		quit(0)
	else:
		printerr("tests FAILED: %d of %d checks" % [_failures, _checks])
		quit(1)


func _assert_true(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAILED: ", message)
