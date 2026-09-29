class_name Enemy
extends CharacterBody2D
## 敵(追跡・被弾・撃破)。数値と色は EnemyData から読む(GameDesign.md 5章)。

signal defeated

enum State { CHASE, HURT, DOOMED }

@export var data: EnemyData

var state := State.CHASE

var _state_time := 0.0
var _knockback := Vector2.ZERO

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var contact_hitbox: Hitbox = $ContactHitbox


func _ready() -> void:
	health.setup(data.max_hp)
	hurtbox.hurt.connect(_on_hurt)
	contact_hitbox.power = data.contact_damage


func _physics_process(delta: float) -> void:
	_state_time += delta
	match state:
		State.CHASE:
			_chase()
		State.HURT:
			_process_hurt()
	contact_hitbox.active = state == State.CHASE


func is_doomed() -> bool:
	return state == State.DOOMED


## 一閃で倒された敵が、納刀の瞬間に倒れる
func fall() -> void:
	_defeat()


func _chase() -> void:
	var player := _player()
	velocity = Vector2.ZERO
	if player:
		velocity = global_position.direction_to(player.global_position) * data.chase_speed
	move_and_slide()


func _process_hurt() -> void:
	velocity = _knockback if _state_time < data.knockback_time else Vector2.ZERO
	move_and_slide()
	if _state_time >= data.hurt_time:
		state = State.CHASE


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
