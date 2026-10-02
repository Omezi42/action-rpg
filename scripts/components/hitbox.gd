class_name Hitbox
extends Area2D
## 攻撃側の当たり。Hurtbox が重なりを調べて try_hit() で当たりを確定する。

signal landed(hurtbox: Hurtbox)

## 足元に描く範囲攻撃の当たりを、Hurtbox(体の高さ)に合わせるずれ
const GROUND_TO_BODY := Vector2(0, -10)

@export var power := 1
## true なら activate() から次の activate() までに同じ相手へ当たるのは1度だけ
@export var hit_once_per_activation := false

var active := true
var direction := Vector2.ZERO
var delay_death := false
## 0より大きければ、当たって生き残った敵の被弾硬直をこの時間にする(影縫い)
var bind_time := 0.0
## true なら盾で弾かれうる(一閃以外の踏み込み・燕返し。GameDesign.md 5章「盾」)
var guardable := false

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
