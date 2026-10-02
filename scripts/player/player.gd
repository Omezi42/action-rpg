class_name Player
extends CharacterBody2D
## 主人公。移動と居合(構え → 踏み込み → 納刀)、被弾を受け持つ(GameDesign.md 2〜4章)。

signal died
signal slashed(from: Vector2, to: Vector2, is_issen: bool)
signal hit_landed(at: Vector2)
## 1回の踏み込みの区切り(踏み込みの始め → 納刀の終わり)。人斬りの数に使う(GameDesign.md 3章)
signal strike_started
signal strike_finished(is_issen: bool)
## 効果音用(GameDesign.md 10章)
signal stage_reached(index: int, is_top: bool)
signal dash_started
signal issen_sheathed
signal damaged
signal return_started

enum State { MOVE, CHARGE, DASH, RETURN, SHEATHE, HURT, DEAD }

const STAGE_FLASH_TIME := 0.12

@export var data: PlayerData
@export var iai: IaiData

var state := State.MOVE
var facing := Vector2.DOWN
var charge: IaiCharge
var stats := PlayerStats.new()
var current_strike: IaiStage
var flash_left := 0.0
var invincible_left := 0.0

var _state_time := 0.0
var _iai_was_pressed := false
var _iai_buffered := false
var _knockback := Vector2.ZERO
var _dash_start := Vector2.ZERO
var _dash_traveled := 0.0
var _doomed: Array[Node] = []
var _hitstop_token := 0
var _aiming_with_mouse := false
var _returned := false
## 直前の踏み込みで進んだ距離(燕返し・極)
var _last_dash_length := 0.0

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var dash_hitbox: Hitbox = $DashHitbox


func _ready() -> void:
	add_to_group("player")
	charge = IaiCharge.new(iai, stats)
	health.setup(data.max_hp)
	health.died.connect(_on_died)
	hurtbox.hurt.connect(_on_hurt)
	dash_hitbox.landed.connect(_on_dash_landed)
	dash_hitbox.deactivate()
	_iai_was_pressed = Input.is_action_pressed("iai")


func _physics_process(delta: float) -> void:
	var iai_pressed := Input.is_action_pressed("iai")
	var iai_just_pressed := iai_pressed and not _iai_was_pressed
	_iai_was_pressed = iai_pressed
	_state_time += delta
	flash_left = maxf(flash_left - delta, 0.0)
	invincible_left = maxf(invincible_left - delta, 0.0)
	match state:
		State.MOVE:
			_move(data.move_speed * stats.move_speed_scale)
			if iai_just_pressed:
				_start_charge()
		State.CHARGE:
			_process_charge(delta, iai_pressed)
		State.DASH:
			_process_dash(delta)
		State.RETURN:
			_process_return(delta)
		State.SHEATHE:
			if iai_just_pressed and _can_return():
				_start_return()
			else:
				_iai_buffered = _iai_buffered or iai_just_pressed
			if state == State.SHEATHE and _state_time >= current_strike.sheathe_time:
				_finish_sheathe(iai_pressed)
		State.HURT:
			_process_hurt()
	hurtbox.invincible = is_invincible()


func is_invincible() -> bool:
	return is_striking() or state == State.DEAD or invincible_left > 0.0


## 踏み込み・燕返しの斬り返しの最中
func is_striking() -> bool:
	return state == State.DASH or state == State.RETURN


## 燕返しの斬り返しの距離(GameDesign.md 8章)。燕返し・極なら元の踏み込みと同じ距離
func return_distance() -> float:
	if stats.ougi_tsubame:
		return _last_dash_length
	return stats.return_distance


## レベルアップ画面を閉じたとき:構えを解き、居合ボタンは一度離すまで効かなくする
func interrupt_input() -> void:
	_iai_was_pressed = true
	if state == State.CHARGE:
		state = State.MOVE
		_state_time = 0.0


## 構え中に今離したときの踏み込みの終点(壁は考えない)
func aim_tip() -> Vector2:
	return global_position + facing * strike_distance(charge.release())


func strike_distance(strike: IaiStage) -> float:
	return strike.distance * stats.distance_scale


## 剛刃の強化は壱以上(一閃を含む)に乗る
func strike_power(strike: IaiStage) -> int:
	if strike == iai.stages[0]:
		return strike.power
	return strike.power + stats.power_bonus


func _move(speed: float) -> void:
	var input := _read_move_input()
	velocity = input * speed
	move_and_slide()


func _read_move_input() -> Vector2:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		facing = Vector2.RIGHT.rotated(snappedf(input.angle(), PI / 4.0))
	return input


func _start_charge() -> void:
	state = State.CHARGE
	_state_time = 0.0
	velocity = Vector2.ZERO
	charge.reset()
	_aiming_with_mouse = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	_aim_at_cursor()


func _process_charge(delta: float, iai_pressed: bool) -> void:
	_read_move_input()
	_aim_at_cursor()
	if charge.advance(delta):
		flash_left = STAGE_FLASH_TIME
		stage_reached.emit(charge.stage_index(), charge.stage_index() == charge.top_stage_index())
	if not iai_pressed:
		_start_dash(charge.release())


func _aim_at_cursor() -> void:
	if not _aiming_with_mouse:
		return
	var aim := cursor_direction(global_position, get_global_mouse_position(), iai.aim_deadzone)
	if aim != Vector2.ZERO:
		facing = aim


## カーソルの狙い:主人公からカーソルへの向き。近さが deadzone 未満なら ZERO
static func cursor_direction(origin: Vector2, cursor: Vector2, deadzone: float) -> Vector2:
	var offset := cursor - origin
	if offset.length() < deadzone:
		return Vector2.ZERO
	return offset.normalized()


func _start_dash(strike: IaiStage) -> void:
	current_strike = strike
	state = State.DASH
	_state_time = 0.0
	_dash_start = global_position
	_dash_traveled = 0.0
	_returned = false
	_doomed.clear()
	velocity = Vector2.ZERO
	dash_hitbox.power = strike_power(strike)
	dash_hitbox.direction = facing
	dash_hitbox.delay_death = strike == iai.issen
	dash_hitbox.guardable = strike != iai.issen
	dash_hitbox.bind_time = stats.bind_time
	dash_hitbox.activate()
	strike_started.emit()
	dash_started.emit()


func _process_dash(delta: float) -> void:
	var distance := strike_distance(current_strike)
	var speed := distance / current_strike.duration
	var step := minf(speed * delta, distance - _dash_traveled)
	_dash_traveled += step
	var collision := move_and_collide(facing * step)
	if collision or _dash_traveled >= distance:
		_end_dash()


func _end_dash() -> void:
	dash_hitbox.deactivate()
	_last_dash_length = _dash_traveled
	slashed.emit(_dash_start, global_position, current_strike == iai.issen)
	_bind_along_line()
	if current_strike != iai.stages[0]:
		_spawn_followups()
	state = State.SHEATHE
	_state_time = 0.0
	_iai_buffered = false


## 燕返し:壱以上の踏み込みの納刀中。1回の踏み込みにつき1回
func _can_return() -> bool:
	return stats.return_distance > 0.0 and not _returned and current_strike != iai.stages[0]


func _start_return() -> void:
	state = State.RETURN
	_state_time = 0.0
	_returned = true
	_dash_start = global_position
	_dash_traveled = 0.0
	facing = -facing
	dash_hitbox.power = data.return_power
	dash_hitbox.guardable = true
	dash_hitbox.bind_time = stats.bind_time
	dash_hitbox.direction = facing
	dash_hitbox.activate()
	return_started.emit()


## 斬り返しでは斬痕・残心を出さない(GameDesign.md 8章)
func _process_return(delta: float) -> void:
	var distance := return_distance()
	var step := minf(distance / data.return_time * delta, distance - _dash_traveled)
	_dash_traveled += step
	var collision := move_and_collide(facing * step)
	if collision or _dash_traveled >= distance:
		dash_hitbox.deactivate()
		slashed.emit(_dash_start, global_position, false)
		_bind_along_line()
		state = State.SHEATHE
		_state_time = 0.0
		_iai_buffered = false


## 斬痕・残心(GameDesign.md 8章)。壱以上の踏み込みの終わりに、取っている強化だけ出す
func _spawn_followups() -> void:
	if stats.linger_time > 0.0:
		var slash := LingeringSlash.new()
		if stats.ougi_homura:
			var life := stats.linger_time * data.homura_time_scale
			slash.setup(_dash_start, global_position, data.homura_power, life)
		else:
			slash.setup(_dash_start, global_position, data.linger_power, stats.linger_time)
		get_parent().add_child(slash)
	if stats.shockwave_radius > 0.0:
		var wave := Shockwave.new()
		wave.position = global_position
		var echo_delay := data.daizanshin_delay if stats.ougi_daizanshin else 0.0
		wave.setup(data.shockwave_power, stats.shockwave_radius, data.shockwave_time, echo_delay)
		get_parent().add_child(wave)


## 影縫い・極:斬った線の左右 kage_width 以内の敵を、斬られていなくても止める(GameDesign.md 8章)
func _bind_along_line() -> void:
	if not stats.ougi_kage or stats.bind_time <= 0.0:
		return
	var line := global_position - _dash_start
	if line == Vector2.ZERO:
		return
	var along := line.normalized()
	for node in get_parent().get_children():
		var enemy := node as Enemy
		if enemy == null:
			continue
		var offset := enemy.global_position - _dash_start
		var t := offset.dot(along)
		if t >= 0.0 and t <= line.length() and absf(offset.cross(along)) <= data.kage_width:
			enemy.bind(stats.bind_time)


## 納刀中に押された居合は、納刀が終わった瞬間に出す(連打で抜き打ちを出し続けるため)
func _finish_sheathe(iai_pressed: bool) -> void:
	_release_doomed()
	if current_strike == iai.issen:
		issen_sheathed.emit()
	state = State.MOVE
	strike_finished.emit(current_strike == iai.issen)
	if _returned and iai_pressed and not _iai_buffered:
		_start_charge()
		return
	if not _iai_buffered:
		return
	_start_charge()
	if not iai_pressed:
		_start_dash(charge.release())


func _process_hurt() -> void:
	velocity = _knockback
	move_and_slide()
	if _state_time >= data.knockback_time:
		state = State.MOVE


## 一閃で斬り抜けた敵は納刀の瞬間にまとめて倒れる
func _release_doomed() -> void:
	for enemy in _doomed:
		if is_instance_valid(enemy):
			enemy.fall()
	_doomed.clear()


func _on_dash_landed(target: Hurtbox) -> void:
	var enemy := target.get_parent()
	if dash_hitbox.delay_death and enemy.has_method("is_doomed") and enemy.is_doomed():
		_doomed.append(enemy)
	hit_landed.emit(target.global_position)
	_hitstop()


func _on_hurt(hitbox: Hitbox) -> void:
	_release_doomed()
	dash_hitbox.deactivate()
	if is_striking() or state == State.SHEATHE:
		strike_finished.emit(current_strike == iai.issen)
	var away := (global_position - hitbox.global_position).normalized()
	if away == Vector2.ZERO:
		away = -facing
	_knockback = away * data.knockback_distance / data.knockback_time
	invincible_left = data.invincible_time
	hurtbox.invincible = true
	state = State.HURT
	_state_time = 0.0
	damaged.emit()
	health.damage(hitbox.power)


func _on_died() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	died.emit()


func _hitstop() -> void:
	_hitstop_token += 1
	var token := _hitstop_token
	Engine.time_scale = 0.0
	await get_tree().create_timer(iai.hitstop_time, true, false, true).timeout
	if token == _hitstop_token:
		Engine.time_scale = 1.0
