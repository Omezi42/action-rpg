class_name HitokiriCounter
extends RefCounted
## 1回の踏み込み(始め → 納刀の終わり)で倒れた敵を数える(GameDesign.md 3章)。

var best := 0

var _counting := false
var _count := 0


func start() -> void:
	_counting = true
	_count = 0


## 踏み込みの外で倒れた敵(納刀の後に斬痕が倒した敵など)は数えない
func add_kill() -> void:
	if _counting:
		_count += 1


## 数え終えた数を返し、最多を更新する
func finish() -> int:
	_counting = false
	best = maxi(best, _count)
	return _count
