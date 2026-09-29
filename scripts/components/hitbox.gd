class_name Hitbox
extends Area2D
## 攻撃側の当たり。Hurtbox が重なりを調べて try_hit() で当たりを確定する。

signal landed(hurtbox: Hurtbox)

@export var power := 1
## true なら activate() から次の activate() までに同じ相手へ当たるのは1度だけ
@export var hit_once_per_activation := false

var active := true
var direction := Vector2.ZERO
var delay_death := false

var _hit_targets: Dictionary = {}


func activate() -> void:
	active = true
	_hit_targets.clear()


func deactivate() -> void:
	active = false


func try_hit(hurtbox: Hurtbox) -> bool:
	if not active:
		return false
	if hit_once_per_activation:
		if _hit_targets.has(hurtbox):
			return false
		_hit_targets[hurtbox] = true
	return true
