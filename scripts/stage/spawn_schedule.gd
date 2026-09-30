class_name SpawnSchedule
extends RefCounted
## 経過時間・出現の番・出現位置の計算(GameDesign.md 5章)。ノードを持たないのでテストから直接使える。

const MAX_PICK_TRIES := 16

var elapsed := 0.0

var _data: SurvivalData
var _next_spawn := 0.0


func _init(data: SurvivalData) -> void:
	_data = data


## 時間を進め、出現の番が来ていれば true
func advance(delta: float) -> bool:
	elapsed += delta
	if elapsed < _next_spawn:
		return false
	_next_spawn = elapsed + interval_at(elapsed)
	return true


func interval_at(time: float) -> float:
	var t := clampf(time / _data.clear_time, 0.0, 1.0)
	return lerpf(_data.spawn_interval_start, _data.spawn_interval_end, t)


func is_cleared() -> bool:
	return elapsed >= _data.clear_time


func time_left() -> float:
	return maxf(_data.clear_time - elapsed, 0.0)


## 出現を始めている種類から重みで1つ選ぶ。roll は 0〜1
func pick_enemy(roll: float = randf()) -> EnemyData:
	var available := _data.spawns.filter(
		func(e: SpawnEntry) -> bool: return e.start_time <= elapsed
	)
	if available.is_empty():
		return null
	var total := 0
	for entry: SpawnEntry in available:
		total += entry.weight
	var target := roll * total
	for entry: SpawnEntry in available:
		target -= entry.weight
		if target < 0.0:
			return entry.enemy
	return available.back().enemy


## screen を spawn_margin だけ縮めた周上の点。主人公に近すぎる点は引き直す
func pick_spawn_point(screen: Rect2, player_pos: Vector2) -> Vector2:
	var area := screen.grow(-_data.spawn_margin)
	var point := Vector2.ZERO
	for i in MAX_PICK_TRIES:
		point = perimeter_point(area, randf())
		if point.distance_to(player_pos) > _data.spawn_min_player_distance:
			break
	return point


## 矩形の周を t(0〜1)で一周する点。左上から時計回り
static func perimeter_point(rect: Rect2, t: float) -> Vector2:
	var d := t * 2.0 * (rect.size.x + rect.size.y)
	if d < rect.size.x:
		return rect.position + Vector2(d, 0)
	d -= rect.size.x
	if d < rect.size.y:
		return Vector2(rect.end.x, rect.position.y + d)
	d -= rect.size.y
	if d < rect.size.x:
		return Vector2(rect.end.x - d, rect.end.y)
	d -= rect.size.x
	return Vector2(rect.position.x, rect.end.y - d)
