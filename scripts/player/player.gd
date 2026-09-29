class_name Player
extends CharacterBody2D
## 主人公。移動と居合(構え → 踏み込み → 納刀)、被弾を受け持つ(GameDesign.md 2〜4章)。

signal died
signal slashed(from: Vector2, to: Vector2, is_issen: bool)
signal hit_landed(at: Vector2)

enum State { MOVE, CHARGE, DASH, SHEATHE, HURT, DEAD }

const STAGE_FLASH_TIME := 0.12

@export var data: PlayerData
@export var iai: IaiData

var state := State.MOVE
var facing := Vector2.DOWN
var charge: IaiCharge
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
var _aim_anchor := Vector2.ZERO

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var dash_hitbox: Hitbox = $DashHitbox


func _ready() -> void:
	add_to_group("player")
	charge = IaiCharge.new(iai)
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
			_move(data.move_speed)
			if iai_just_pressed:
				_start_charge()
		State.CHARGE:
			_process_charge(delta, iai_pressed)
		State.DASH:
			_process_dash(delta)
		State.SHEATHE:
			_iai_buffered = _iai_buffered or iai_just_pressed
			if _state_time >= current_strike.sheathe_time:
				_finish_sheathe(iai_pressed)
		State.HURT:
			_process_hurt()
	hurtbox.invincible = is_invincible()


func is_invincible() -> bool:
	return state == State.DASH or state == State.DEAD or invincible_left > 0.0


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
	_aim_anchor = get_global_mouse_position()


func _process_charge(delta: float, iai_pressed: bool) -> void:
	_read_move_input()
	if _aiming_with_mouse:
		var aim := slingshot_direction(_aim_anchor, get_global_mouse_position(), iai.aim_deadzone)
		if aim != Vector2.ZERO:
			facing = aim
	if charge.advance(delta):
		flash_left = STAGE_FLASH_TIME
	if not iai_pressed:
		_start_dash(charge.release())


## パチンコ式の狙い:押した位置から引いた向きの逆。引きが deadzone 未満なら ZERO
static func slingshot_direction(anchor: Vector2, pointer: Vector2, deadzone: float) -> Vector2:
	var pull := anchor - pointer
	if pull.length() < deadzone:
		return Vector2.ZERO
	return pull.normalized()


func _start_dash(strike: IaiStage) -> void:
	current_strike = strike
	state = State.DASH
	_state_time = 0.0
	_dash_start = global_position
	_dash_traveled = 0.0
	_doomed.clear()
	velocity = Vector2.ZERO
	dash_hitbox.power = strike.power
	dash_hitbox.direction = facing
	dash_hitbox.delay_death = strike == iai.issen
	dash_hitbox.activate()


func _process_dash(delta: float) -> void:
	var speed := current_strike.distance / current_strike.duration
	var step := minf(speed * delta, current_strike.distance - _dash_traveled)
	_dash_traveled += step
	var collision := move_and_collide(facing * step)
	if collision or _dash_traveled >= current_strike.distance:
		_end_dash()


func _end_dash() -> void:
	dash_hitbox.deactivate()
	slashed.emit(_dash_start, global_position, current_strike == iai.issen)
	state = State.SHEATHE
	_state_time = 0.0
	_iai_buffered = false


## 納刀中に押された居合は、納刀が終わった瞬間に出す(連打で抜き打ちを出し続けるため)
func _finish_sheathe(iai_pressed: bool) -> void:
	_release_doomed()
	state = State.MOVE
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
	var away := (global_position - hitbox.global_position).normalized()
	if away == Vector2.ZERO:
		away = -facing
	_knockback = away * data.knockback_distance / data.knockback_time
	invincible_left = data.invincible_time
	hurtbox.invincible = true
	state = State.HURT
	_state_time = 0.0
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
