extends SceneTree
## ヘッドレステストの入口。個々のスイートは別ファイルに置き、ここは呼び出しと判定だけを持つ。

const IaiTests = preload("res://tools/tests/iai_tests.gd")
const CombatTests = preload("res://tools/tests/combat_tests.gd")

var _failures := 0
var _checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	IaiTests.new().run(_assert_true)
	await CombatTests.new().run(self, _assert_true)
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
