class_name TouchControls
extends CanvasLayer
## タッチ操作(GameDesign.md 2章)。autoload `TouchControlsLayer` として置く。
## 移動・居合・小ボタンは InputEventAction に作り直して流すので、各画面はキーやパッドと同じに受け取る。
## 画面ごとの小ボタンとスティックの有無は、グループ `touch_context` のノードが `touch_context()` で返す。
## それ以外の場所のタップは、同じグループで `touch_tap(at)` を持つノードへ画面の座標で渡す。

const NODE_PATH := "/root/TouchControlsLayer"
const GROUP := &"touch_context"
const KEY_STICK := "stick"
const KEY_BUTTONS := "buttons"
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
const OCTANT := PI / 4.0
## 45度に丸めた向きの成分がこれを超えたらその方向を押す(斜めは約0.71)
const AXIS_THRESHOLD := 0.5
const NO_FINGER := -1

@export var draw_layer := 100
@export var stick_radius := 28.0
@export var stick_deadzone := 6.0
@export var knob_radius := 10.0
@export var iai_center := Vector2(444, 232)
@export var iai_radius := 26.0
@export var button_size := Vector2(52, 16)
@export var button_gap := 4.0
@export var buttons_top_right := Vector2(460, 36)
@export var font_size := 10
@export var fill_color := Color(1, 1, 1, 0.18)
@export var pressed_color := Color(1, 1, 1, 0.45)
@export var line_color := Color(1, 1, 1, 0.6)
@export var text_color := Color(1, 1, 1, 0.85)
@export var portrait_color := Color("1d2330")
@export var portrait_text := "画面を横にしてください"

var _active := false
var _context := {}
var _canvas: Control
## 指の番号 → 押しているアクション(居合・小ボタン)
var _held: Dictionary[int, StringName] = {}
var _stick_finger := NO_FINGER
var _stick_origin := Vector2.ZERO
var _stick_offset := Vector2.ZERO
var _stick_pressed: Array[StringName] = []


func _ready() -> void:
	layer = draw_layer
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_controls)
	add_child(_canvas)


static func active() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var node := tree.root.get_node_or_null(NODE_PATH) as TouchControls if tree else null
	return node != null and node._active


## 画面が `touch_context()` で返す値を作る。buttons は [表示名, アクション] の配列
static func context(stick: bool, buttons: Array = []) -> Dictionary:
	return {KEY_STICK: stick, KEY_BUTTONS: buttons}


func _process(_delta: float) -> void:
	_context = _collect_context()
	if not _context[KEY_STICK] and _stick_finger != NO_FINGER:
		_end_stick()
	_canvas.queue_redraw()


func _collect_context() -> Dictionary:
	var stick := false
	var buttons: Array = []
	for node in get_tree().get_nodes_in_group(GROUP):
		var part: Dictionary = node.touch_context()
		stick = stick or part.get(KEY_STICK, false)
		buttons.append_array(part.get(KEY_BUTTONS, []))
	return context(stick, buttons)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_active = true
		if event.pressed:
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_touch_drag(event.index, event.position)
		get_viewport().set_input_as_handled()
	elif _active and (event is InputEventKey or event is InputEventJoypadButton):
		_deactivate()


func _touch_down(finger: int, at: Vector2) -> void:
	_context = _collect_context()
	var action := _button_at(at)
	if action != &"":
		_held[finger] = action
		_send_action(action, true)
	elif at.distance_to(iai_center) <= iai_radius:
		_held[finger] = &"iai"
		_send_action(&"iai", true)
	elif _context[KEY_STICK]:
		if _stick_finger == NO_FINGER and at.x < _screen_size().x / 2.0:
			_stick_finger = finger
			_stick_origin = at
			_stick_offset = Vector2.ZERO
	else:
		for node in get_tree().get_nodes_in_group(GROUP):
			if node.has_method(&"touch_tap"):
				node.touch_tap(at)


func _touch_drag(finger: int, at: Vector2) -> void:
	if finger == _stick_finger:
		_stick_offset = (at - _stick_origin).limit_length(stick_radius)
		_update_stick()


func _touch_up(finger: int) -> void:
	if _held.has(finger):
		_send_action(_held[finger], false)
		_held.erase(finger)
	elif finger == _stick_finger:
		_end_stick()


func _deactivate() -> void:
	_active = false
	for finger: int in _held.keys():
		_send_action(_held[finger], false)
	_held.clear()
	_end_stick()


func _end_stick() -> void:
	_stick_finger = NO_FINGER
	_stick_offset = Vector2.ZERO
	_update_stick()


func _update_stick() -> void:
	var wanted := stick_actions(_stick_offset, stick_deadzone)
	for action in MOVE_ACTIONS:
		var now := action in wanted
		if now != (action in _stick_pressed):
			_send_action(action, now)
	_stick_pressed = wanted


## スティックの倒し方を、45度に丸めた向きの上下左右のアクションに分ける
static func stick_actions(offset: Vector2, deadzone: float) -> Array[StringName]:
	var result: Array[StringName] = []
	if offset.length() < deadzone:
		return result
	var direction := Vector2.from_angle(snappedf(offset.angle(), OCTANT))
	if direction.x < -AXIS_THRESHOLD:
		result.append(&"move_left")
	elif direction.x > AXIS_THRESHOLD:
		result.append(&"move_right")
	if direction.y < -AXIS_THRESHOLD:
		result.append(&"move_up")
	elif direction.y > AXIS_THRESHOLD:
		result.append(&"move_down")
	return result


func _send_action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _screen_size() -> Vector2:
	return get_viewport().get_visible_rect().size


func _button_at(at: Vector2) -> StringName:
	var buttons: Array = _context.get(KEY_BUTTONS, [])
	for i in buttons.size():
		if _button_rect(i, buttons.size()).has_point(at):
			return buttons[i][1]
	return &""


func _button_rect(index: int, count: int) -> Rect2:
	var from_right := count - 1 - index
	var right := buttons_top_right.x - from_right * (button_size.x + button_gap)
	return Rect2(Vector2(right - button_size.x, buttons_top_right.y), button_size)


func _is_portrait() -> bool:
	var window := get_viewport().get_visible_rect().size
	if get_window():
		window = Vector2(get_window().size)
	return window.y > window.x


func _draw_controls() -> void:
	var font := _canvas.get_theme_default_font()
	if _is_portrait():
		_canvas.draw_rect(Rect2(Vector2.ZERO, _screen_size()), portrait_color)
		_draw_centered(font, portrait_text, _screen_size() / 2.0)
		return
	if not _active:
		return
	var held := _held.values()
	var buttons: Array = _context.get(KEY_BUTTONS, [])
	for i in buttons.size():
		var rect := _button_rect(i, buttons.size())
		var color := pressed_color if buttons[i][1] in held else fill_color
		_canvas.draw_rect(rect, color)
		_canvas.draw_rect(rect, line_color, false)
		_draw_centered(font, buttons[i][0], rect.get_center())
	var iai_color := pressed_color if &"iai" in held else fill_color
	_canvas.draw_circle(iai_center, iai_radius, iai_color)
	_canvas.draw_arc(iai_center, iai_radius, 0.0, TAU, 32, line_color)
	_draw_centered(font, "居合", iai_center)
	if _stick_finger != NO_FINGER:
		_canvas.draw_circle(_stick_origin, stick_radius, fill_color)
		_canvas.draw_arc(_stick_origin, stick_radius, 0.0, TAU, 32, line_color)
		_canvas.draw_circle(_stick_origin + _stick_offset, knob_radius, pressed_color)


func _draw_centered(font: Font, text: String, center: Vector2) -> void:
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := (
		center + Vector2(-text_size.x / 2.0, font.get_ascent(font_size) - text_size.y / 2.0)
	)
	_canvas.draw_string(
		font, baseline.round(), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color
	)
