class_name Enemy
extends CharacterBody2D
## 敵(うろつき・気づき・追跡・被弾・撃破)。数値と色は EnemyData から読む(GameDesign.md 5章)。

signal defeated(enemy: Enemy)

enum State { WANDER, NOTICE, CHASE, HURT, DOOMED }

@export var data: EnemyData
## add_child の前に立てると気づいた状態(追跡)から始まる。大群に使う
@export var alerted := false

var state := State.WANDER

var _state_time := 0.0
var _knockback := Vector2.ZERO
var _wander_dir := Vector2.ZERO
var _wander_left := 0.0

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var contact_hitbox: Hitbox = $ContactHitbox


func _ready() -> void:
	health.setup(data.max_hp)
	hurtbox.hurt.connect(_on_hurt)
	contact_hitbox.power = data.contact_damage
	if alerted:
		state = State.CHASE


func _physics_process(delta: float) -> void:
	_state_time += delta
	match state:
		State.WANDER:
			_wander(delta)
		State.NOTICE:
			_notice()
		State.CHASE:
			_chase()
		State.HURT:
			_process_hurt()
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
	velocity = global_position.direction_to(player.global_position) * data.chase_speed
	move_and_slide()


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
