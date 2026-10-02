class_name Enemy
extends CharacterBody2D
## 敵(うろつき・気づき・追跡・被弾・撃破・予告のある攻撃・矢)。数値と色は EnemyData から読む(GameDesign.md 5章)。

signal defeated(enemy: Enemy)
signal rush_warned
signal shot_fired(from: Vector2, direction: Vector2)

enum State { WANDER, NOTICE, CHASE, HURT, DOOMED, WINDUP, RUSH, SWEEP, JUMP, LAND, RECOVER, AIM }

const ATTACK_STATES := [
	State.WINDUP, State.RUSH, State.SWEEP, State.JUMP, State.LAND, State.RECOVER
]
const FLASH_TIME := 0.08
## 矢は体の高さから放つ
const SHOT_OFFSET := Vector2(0, -10)
## ratio * (1 - ratio) の最大(0.25)を1にそろえる
const PARABOLA_PEAK := 4.0

@export var data: EnemyData
## add_child の前に立てると気づいた状態(追跡)から始まる。大群に使う
@export var alerted := false

var state := State.WANDER
var flash_left := 0.0
## 攻撃・矢の向き。予告の始めに決める
var aim_direction := Vector2.ZERO
## ジャンプ斬りの着地点。予告の始めに決める
var jump_target := Vector2.ZERO

var _state_time := 0.0
var _knockback := Vector2.ZERO
var _wander_dir := Vector2.ZERO
var _wander_left := 0.0
var _attack_cooldown := 0.0
var _rush_traveled := 0.0
var _shot_cooldown := 0.0
var _sweep: SweepAttack
var _jump: JumpAttack
var _jump_from := Vector2.ZERO

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_hitbox: Hitbox = $AttackHitbox


func _ready() -> void:
	health.setup(data.max_hp)
	hurtbox.hurt.connect(_on_hurt)
	attack_hitbox.power = data.attack_damage
	attack_hitbox.deactivate()
	if data.sweep_radius > 0.0:
		_sweep = SweepAttack.new()
		add_child(_sweep)
		_sweep.setup(data.sweep_radius, data.attack_damage)
	if data.jump_radius > 0.0:
		_jump = JumpAttack.new()
		add_child(_jump)
		_jump.setup(data.jump_radius, data.attack_damage)
	if alerted:
		state = State.CHASE
	else:
		_face_player()


func _physics_process(delta: float) -> void:
	_state_time += delta
	flash_left = maxf(flash_left - delta, 0.0)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_shot_cooldown = maxf(_shot_cooldown - delta, 0.0)
	match state:
		State.WANDER:
			_wander(delta)
		State.NOTICE:
			_notice()
		State.CHASE:
			_chase()
		State.HURT:
			_process_hurt()
		State.WINDUP:
			_windup()
		State.RUSH:
			_rush()
		State.SWEEP, State.LAND:
			_strike()
		State.JUMP:
			_jump_through()
		State.RECOVER:
			_recover()
		State.AIM:
			_aim()
	attack_hitbox.active = state == State.RUSH
	if _sweep:
		_sweep.active = state == State.SWEEP
	if _jump:
		_jump.active = state == State.LAND
	hurtbox.invincible = state == State.JUMP or state == State.DOOMED


func is_doomed() -> bool:
	return state == State.DOOMED


## 一閃で倒された敵が、納刀の瞬間に倒れる
func fall() -> void:
	_defeat()


func _wander(delta: float) -> void:
	if _player_within(data.sight_range):
		_enter(State.NOTICE)
		return
	if _player() and not _player_within(data.despawn_range):
		queue_free()
		return
	_wander_left -= delta
	if _wander_left <= 0.0:
		_turn()
	velocity = _wander_dir * data.chase_speed * data.wander_speed_ratio
	if move_and_slide():
		_turn()


func _notice() -> void:
	velocity = Vector2.ZERO
	if _state_time >= data.notice_time:
		_enter(State.CHASE)


func _chase() -> void:
	var player := _player()
	if not player or not _player_within(data.lose_range):
		_enter(State.WANDER)
		return
	if _can_attack():
		_start_windup(player)
		return
	if _can_shoot():
		aim_direction = global_position.direction_to(player.global_position)
		_shot_cooldown = data.shot_interval
		_enter(State.AIM)
		return
	if data.hold_range > 0.0 and _player_within(data.hold_range):
		velocity = Vector2.ZERO
		return
	velocity = global_position.direction_to(player.global_position) * data.chase_speed
	move_and_slide()


func _can_attack() -> bool:
	var has_attack := data.rush_distance > 0.0 or data.sweep_radius > 0.0 or data.jump_radius > 0.0
	return has_attack and _attack_cooldown <= 0.0 and _player_within(data.attack_range)


func _can_shoot() -> bool:
	return data.shot_range > 0.0 and _shot_cooldown <= 0.0 and _player_within(data.shot_range)


## 向きは予告の始めに決める(予告を見て横へ避けられるように)
func _start_windup(player: Node2D) -> void:
	aim_direction = global_position.direction_to(player.global_position)
	_attack_cooldown = data.attack_interval
	_rush_traveled = 0.0
	if _sweep:
		_sweep.rotation = aim_direction.angle()
	if _jump:
		jump_target = player.global_position
		_jump.global_position = jump_target
	_enter(State.WINDUP)
	rush_warned.emit()


## 攻撃の予告の進み具合 0〜1
func windup_ratio() -> float:
	return clampf(_state_time / data.attack_windup, 0.0, 1.0) if state == State.WINDUP else 0.0


func _windup() -> void:
	velocity = Vector2.ZERO
	if _state_time < data.attack_windup:
		return
	if data.rush_distance > 0.0:
		attack_hitbox.activate()
		_enter(State.RUSH)
	elif _sweep:
		_sweep.activate()
		_enter(State.SWEEP)
	else:
		_jump_from = global_position
		_enter(State.JUMP)


func _rush() -> void:
	var delta := get_physics_process_delta_time()
	var step := minf(
		data.rush_distance / data.rush_time * delta, data.rush_distance - _rush_traveled
	)
	_rush_traveled += step
	if move_and_collide(aim_direction * step) or _rush_traveled >= data.rush_distance:
		_enter(State.RECOVER)


func _strike() -> void:
	velocity = Vector2.ZERO
	if _state_time >= data.strike_time:
		_enter(State.RECOVER)


## 壁・岩を飛び越えるので、物理で動かさず位置を直接進める
func _jump_through() -> void:
	var ratio := minf(_state_time / data.jump_time, 1.0)
	global_position = _jump_from.lerp(jump_target, ratio)
	if ratio >= 1.0:
		_jump.activate()
		_enter(State.LAND)


## ジャンプ中の見た目の高さ(放物線)
func air_height() -> float:
	if state != State.JUMP:
		return 0.0
	var ratio := clampf(_state_time / data.jump_time, 0.0, 1.0)
	return data.jump_height * PARABOLA_PEAK * ratio * (1.0 - ratio)


func _aim() -> void:
	velocity = Vector2.ZERO
	if _state_time >= data.shot_windup:
		shot_fired.emit(global_position + SHOT_OFFSET, aim_direction)
		_enter(State.CHASE)


func _recover() -> void:
	velocity = Vector2.ZERO
	if _state_time >= data.attack_recover:
		_enter(State.CHASE)


## 出現して最初のうろつきは主人公の方へ向ける(画面外から入ってくるように)
func _face_player() -> void:
	var player := _player()
	if not player:
		return
	var spread := randf_range(-data.initial_wander_spread, data.initial_wander_spread)
	_wander_dir = global_position.direction_to(player.global_position).rotated(spread)
	_wander_left = randf_range(data.wander_turn_min, data.wander_turn_max)


func _turn() -> void:
	_wander_dir = Vector2.RIGHT.rotated(randf() * TAU)
	_wander_left = randf_range(data.wander_turn_min, data.wander_turn_max)


func _enter(next: State) -> void:
	state = next
	_state_time = 0.0
	_wander_left = 0.0


func _player_within(distance: float) -> bool:
	var player := _player()
	return player != null and global_position.distance_to(player.global_position) <= distance


func _process_hurt() -> void:
	velocity = _knockback if _state_time < data.knockback_time else Vector2.ZERO
	move_and_slide()
	if _state_time >= data.hurt_time:
		_enter(State.CHASE)


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func _on_hurt(hitbox: Hitbox) -> void:
	health.damage(hitbox.power)
	flash_left = FLASH_TIME
	if data.attack_armor and state in ATTACK_STATES and not health.is_dead():
		return
	_knockback = hitbox.direction * data.knockback_distance / data.knockback_time
	_state_time = 0.0
	if not health.is_dead():
		state = State.HURT
	elif hitbox.delay_death:
		state = State.DOOMED
		hurtbox.invincible = true
	else:
		_defeat()


func _defeat() -> void:
	hurtbox.invincible = true
	defeated.emit(self)
	queue_free()
