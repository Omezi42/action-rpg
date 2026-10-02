class_name FollowCamera
extends Camera2D
## 主人公を追うカメラ(GameDesign.md 6章)。構え中は予告線の先端との中点へ寄せる。
## 位置は整数ピクセルにそろえるため、position_smoothing は使わず自前で補間する。

@export var charge_pan_time := 0.15
@export var return_pan_time := 0.3

var player: Player

var _offset := Vector2.ZERO
var _pan_from := Vector2.ZERO
var _pan_elapsed := 0.0
var _charging := false
var _shake_amplitude := 0.0
var _shake_time := 0.0
var _shake_left := 0.0


func setup(target: Player, field: Rect2) -> void:
	player = target
	limit_left = roundi(field.position.x)
	limit_top = roundi(field.position.y)
	limit_right = roundi(field.end.x)
	limit_bottom = roundi(field.end.y)
	global_position = player.global_position.round()
	reset_smoothing()


func _physics_process(delta: float) -> void:
	if not player:
		return
	var charging := player.state == Player.State.CHARGE
	if charging != _charging:
		_charging = charging
		_pan_from = _offset
		_pan_elapsed = 0.0
	_pan_elapsed += delta
	var target := (player.aim_tip() - player.global_position) / 2.0 if charging else Vector2.ZERO
	var pan_time := charge_pan_time if charging else return_pan_time
	_offset = _pan_from.lerp(target, smoothstep(0.0, pan_time, _pan_elapsed))
	global_position = (player.global_position + _offset).round()
	_process_shake(delta)


## 画面の揺れ(GameDesign.md 3章)。揺れ幅は時間とともに0へ戻る
func shake(amplitude: float, time: float) -> void:
	_shake_amplitude = amplitude
	_shake_time = time
	_shake_left = time


func _process_shake(delta: float) -> void:
	_shake_left = maxf(_shake_left - delta, 0.0)
	if _shake_left <= 0.0:
		offset = Vector2.ZERO
		return
	var amplitude := _shake_amplitude * _shake_left / _shake_time
	offset = Vector2(randf_range(-amplitude, amplitude), randf_range(-amplitude, amplitude)).round()


## いま映している矩形(フィールドの端での停止を含む)
func view_rect() -> Rect2:
	var size := get_viewport_rect().size / zoom
	return Rect2(get_screen_center_position() - size / 2.0, size)
