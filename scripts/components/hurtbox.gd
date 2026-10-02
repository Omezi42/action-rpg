class_name Hurtbox
extends Area2D
## 被弾側の当たり。重なっている Hitbox を毎フレーム調べる(重なったまま無敵が切れても当たるように)。

signal hurt(hitbox: Hitbox)
signal guarded(hitbox: Hitbox)

var invincible := false
## 設定されていて guard.call(hitbox) が true なら、hurt の代わりに guarded を出す(盾鬼)
var guard := Callable()


func _physics_process(_delta: float) -> void:
	for area in get_overlapping_areas():
		if invincible:
			return
		var hitbox := area as Hitbox
		if hitbox and hitbox.try_hit(self):
			if guard.is_valid() and guard.call(hitbox):
				guarded.emit(hitbox)
				continue
			hurt.emit(hitbox)
			hitbox.landed.emit(self)
