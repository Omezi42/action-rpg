class_name Enemy
extends CharacterBody2D
## 敵(うろつき・追跡・被弾・撃破)。数値と色は EnemyData から読む(GameDesign.md 5章)。

signal defeated

enum State { WANDER, CHASE, HURT, DOOMED }

@export var data: EnemyData

var state := State.WANDER

var _state_time := 0.0
var _wander_dir := Vector2.ZERO
var _wander_left := 0.0
var _knockback := Vector2.ZERO

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var contact_hitbox: Hitbox = $ContactHitbox


func _ready() -> void:
	health.setup(data.max_hp)
	hurtbox.hurt.connect(_on_hurt)
	contact_hitbox.power = data.contact_damage
	_pick_wander()


func _physics_process(delta: float) -> void:
	_state_time += delta
	match state:
		State.WANDER:
			_wander(delta)
		State.CHASE:
			_chase()
		State.HURT:
			_process_hurt()
	contact_hitbox.active = state == State.WANDER or state == State.CHASE


func is_doomed() -> bool:
	return state == State.DOOMED


## 一閃で倒された敵が、納刀の瞬間に倒れる
func fall() -> void:
	_defeat()


func _wander(delta: float) -> void:
	_wander_left -= delta
	if _wander_left <= 0.0:
		_pick_wander()
	velocity = _wander_dir * data.wander_speed
	move_and_slide()
	var player := _player()
	if player and global_position.distance_to(player.global_position) < data.notice_range:
		state = State.CHASE


func _chase() -> void:
	var player := _player()
	if not player or global_position.distance_to(player.global_position) > data.lose_range:
		state = State.WANDER
		_pick_wander()
		return
	velocity = global_position.direction_to(player.global_position) * data.chase_speed
	move_and_slide()


func _process_hurt() -> void:
	velocity = _knockback if _state_time < data.knockback_time else Vector2.ZERO
	move_and_slide()
	if _state_time >= data.hurt_time:
		state = State.WANDER
		_pick_wander()


func _pick_wander() -> void:
	_wander_left = randf_range(data.wander_interval_min, data.wander_interval_max)
	if randf() < data.wander_stop_chance:
		_wander_dir = Vector2.ZERO
	else:
		_wander_dir = Vector2.RIGHT.rotated(randf() * TAU)


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
	defeated.emit()
	queue_free()
