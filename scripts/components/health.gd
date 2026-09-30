class_name Health
extends Node
## HPを持ち、減ったとき・0になったときに知らせる。

signal changed(hp: int, max_hp: int)
signal died

var hp := 0
var max_hp := 0


func setup(value: int) -> void:
	max_hp = value
	hp = value
	changed.emit(hp, max_hp)


func damage(amount: int) -> void:
	if is_dead():
		return
	hp = maxi(hp - amount, 0)
	changed.emit(hp, max_hp)
	if is_dead():
		died.emit()


func heal(amount: int) -> void:
	if is_dead():
		return
	hp = mini(hp + amount, max_hp)
	changed.emit(hp, max_hp)


func is_dead() -> bool:
	return hp <= 0
