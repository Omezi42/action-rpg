class_name Enemy
extends CharacterBody2D
## 敵(うろつき・気づき・追跡・被弾・撃破・突進・矢)。数値と色は EnemyData から読む(GameDesign.md 5章)。

signal defeated(enemy: Enemy)
signal rush_warned
signal shot_fired(from: Vector2, direction: Vector2)

enum State { WANDER, NOTICE, CHASE, HURT, DOOMED, WINDUP, RUSH, RECOVER, AIM }

const RUSH_STATES := [State.WINDUP, State.RUSH, State.RECOVER]
const FLASH_TIME := 0.08
## 矢は体の高さから放つ
const SHOT_OFFSET := Vector2(0, -10)

@export var data: EnemyData
## add_child の前に立てると気づいた状態(追跡)から始まる。大群に使う
@export var alerted := false

var state := State.WANDER
var flash_left := 0.0
## 突進・矢の向き。構えの始めに決める
var aim_direction := Vector2.ZERO

var _state_time := 0.0
var _knockback := Vector2.ZERO
var _wander_dir := Vector2.ZERO
var _wander_left := 0.0
var _rush_cooldown := 0.0
var _rush_traveled := 0.0
var _shot_cooldown := 0.0

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var contact_hitbox: Hitbox = $ContactHitbox


func _ready() -> void:
	health.setup(data.max_hp)
	hurtbox.hurt.connect(_on_hurt)
	contact_hitbox.power = data.contact_damage
	if alerted:
		state = State.CHASE
	else:
		_face_player()


func _physics_process(delta: float) -> void:
	_state_time += delta
	flash_left = maxf(flash_left - delta, 0.0)
	_rush_cooldown = maxf(_rush_cooldown - delta, 0.0)
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
		State.RECOVER:
			_recover()
		State.AIM:
			_aim()
	contact_hitbox.active = state != State.HURT and state != State.DOOMED


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
	if _can_rush():
		_start_windup(player)
		return
	if data.shot_range > 0.0 and _player_within(data.shot_range):
		velocity = Vector2.ZERO
		if _shot_cooldown <= 0.0:
			aim_direction = global_position.direction_to(player.global_position)
			_shot_cooldown = data.shot_interval
			_enter(State.AIM)
		return
	velocity = global_position.direction_to(player.global_position) * data.chase_speed
	move_and_slide()


func _can_rush() -> bool:
	return data.rush_distance > 0.0 and _rush_cooldown <= 0.0 and _player_within(data.rush_range)


## 向きは予告の始めに決める(予告を見て横へ避けられるように)
func _start_windup(player: Node2D) -> void:
	aim_direction = global_position.direction_to(player.global_position)
	_rush_cooldown = data.rush_interval
	_rush_traveled = 0.0
	_enter(State.WINDUP)
	rush_warned.emit()


## 突進の予告の進み具合 0〜1
func windup_ratio() -> float:
	return clampf(_state_time / data.rush_windup, 0.0, 1.0) if state == State.WINDUP else 0.0


func _windup() -> void:
	velocity = Vector2.ZERO
	if _state_time >= data.rush_windup:
		_enter(State.RUSH)


func _rush() -> void:
	var delta := get_physics_process_delta_time()
	var step := minf(
		data.rush_distance / data.rush_time * delta, data.rush_distance - _rush_traveled
	)
	_rush_traveled += step
	if move_and_collide(aim_direction * step) or _rush_traveled >= data.rush_distance:
		_enter(State.RECOVER)


func _aim() -> void:
	velocity = Vector2.ZERO
	if _state_time >= data.shot_windup:
		shot_fired.emit(global_position + SHOT_OFFSET, aim_direction)
		_enter(State.CHASE)


func _recover() -> void:
	velocity = Vector2.ZERO
	if _state_time >= data.rush_recover:
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
	if state in RUSH_STATES and not health.is_dead():
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
