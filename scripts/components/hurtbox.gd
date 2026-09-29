class_name Hurtbox
extends Area2D
## 被弾側の当たり。重なっている Hitbox を毎フレーム調べる(重なったまま無敵が切れても当たるように)。

signal hurt(hitbox: Hitbox)

var invincible := false


func _physics_process(_delta: float) -> void:
	for area in get_overlapping_areas():
		if invincible:
			return
		var hitbox := area as Hitbox
		if hitbox and hitbox.try_hit(self):
			hurt.emit(hitbox)
			hitbox.landed.emit(self)
