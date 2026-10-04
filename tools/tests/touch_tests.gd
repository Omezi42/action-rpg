extends RefCounted
## タッチ操作:スティックの向き・居合ボタン・小ボタン・タップの受け渡しを確かめる(GameDesign.md 2章)。


class ContextStub:
	extends Node
	var stick := false
	var buttons: Array = []
	var tapped := Vector2.INF

	func touch_context() -> Dictionary:
		return TouchControls.context(stick, buttons)

	func touch_tap(at: Vector2) -> void:
		tapped = at


const STICK_AT := Vector2(100, 150)
const STICK_PUSH := Vector2(24, 0)
const MENU_TAP := Vector2(120, 120)
## 流した入力が Input に届くまでのフレーム数
const SETTLE_FRAMES := 2

var _tree: SceneTree


func run(tree: SceneTree, check: Callable) -> void:
	_tree = tree
	_test_stick_actions(check)
	await _test_touch(check)


func _test_stick_actions(check: Callable) -> void:
	var deadzone := 6.0
	check.call(TouchControls.stick_actions(Vector2(3, 0), deadzone).is_empty(), "遊びの内側では動かない")
	check.call(TouchControls.stick_actions(Vector2(20, 2), deadzone) == [&"move_right"], "右へ倒すと右")
	var diagonal := TouchControls.stick_actions(Vector2(14, 14), deadzone)
	check.call(diagonal == [&"move_right", &"move_down"], "斜めは2方向を押す")
	check.call(TouchControls.stick_actions(Vector2(-3, -20), deadzone) == [&"move_up"], "上へ倒すと上")


func _test_touch(check: Callable) -> void:
	var stub := ContextStub.new()
	stub.add_to_group(TouchControls.GROUP)
	_tree.root.add_child(stub)
	var touch := TouchControls.new()
	_tree.root.add_child(touch)

	_touch(touch, 0, touch.iai_center, true)
	await _settle()
	check.call(touch._active and Input.is_action_pressed("iai"), "居合ボタンで居合を押す")
	_touch(touch, 0, touch.iai_center, false)
	await _settle()
	check.call(not Input.is_action_pressed("iai"), "指を離すと居合を離す")

	stub.stick = true
	_touch(touch, 1, STICK_AT, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = STICK_AT + STICK_PUSH
	touch._input(drag)
	await _settle()
	check.call(Input.is_action_pressed("move_right"), "スティックを倒すと移動を押す")
	_touch(touch, 1, STICK_AT + STICK_PUSH, false)
	await _settle()
	check.call(not Input.is_action_pressed("move_right"), "スティックを離すと移動を離す")

	stub.buttons = [["ポーズ", &"pause"]]
	var button := touch._button_rect(0, 1).get_center()
	_touch(touch, 2, button, true)
	await _settle()
	check.call(Input.is_action_pressed("pause"), "小ボタンでそのアクションを押す")
	_touch(touch, 2, button, false)
	await _settle()

	stub.stick = false
	stub.buttons = []
	_touch(touch, 3, MENU_TAP, true)
	check.call(stub.tapped == MENU_TAP, "スティックの無い画面のタップは画面へ渡す")
	_touch(touch, 3, MENU_TAP, false)
	stub.tapped = Vector2.INF
	stub.stick = true
	_touch(touch, 4, MENU_TAP, true)
	check.call(stub.tapped == Vector2.INF, "スティックのある画面ではタップを渡さない")
	_touch(touch, 4, MENU_TAP, false)

	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	touch._input(key)
	check.call(not touch._active, "キーを使うとタッチの表示を消す")
	touch.free()
	stub.free()


func _touch(touch: TouchControls, finger: int, at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = finger
	event.position = at
	event.pressed = pressed
	touch._input(event)


func _settle() -> void:
	for i in SETTLE_FRAMES:
		await _tree.process_frame
