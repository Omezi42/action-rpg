class_name SpawnSchedule
extends RefCounted
## 経過時間・出現の番・出現位置の計算(GameDesign.md 5章)。ノードを持たないのでテストから直接使える。

const MAX_PICK_TRIES := 32

var elapsed := 0.0

var _data: SurvivalData
var _next_spawn := 0.0
var _next_horde := 0
var _boss_taken := false


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
	if time >= _data.clear_time:
		return _data.boss_spawn_interval
	var index := _phase_index(time)
	var phase := _data.phases[index]
	var end_time := _data.clear_time
	if index + 1 < _data.phases.size():
		end_time = _data.phases[index + 1].start_time
	var t := clampf(inverse_lerp(phase.start_time, end_time, time), 0.0, 1.0)
	return lerpf(phase.interval_start, phase.interval_end, t)


func max_enemies_at(time: float) -> int:
	if time >= _data.clear_time:
		return _data.boss_max_enemies
	return _data.phases[_phase_index(time)].max_enemies


func _phase_index(time: float) -> int:
	var index := 0
	for i in _data.phases.size():
		if time >= _data.phases[i].start_time:
			index = i
	return index


## 大群の時刻を過ぎていれば true(1回につき1度だけ)
func take_horde() -> bool:
	if _next_horde >= _data.horde_times.size() or elapsed < _data.horde_times[_next_horde]:
		return false
	_next_horde += 1
	return true


## 残り時間が0になっていれば true(1度だけ)
func take_boss() -> bool:
	if _boss_taken or not is_boss_time():
		return false
	_boss_taken = true
	return true


func horde_points(view: Rect2) -> Array[Vector2]:
	return line_points(view, _data.horde_count, _data.horde_spacing)


## 大鬼の出現位置。大群と同じ辺の中央
func edge_center(view: Rect2) -> Vector2:
	return line_points(view, 1, 0.0)[0]


## 映す矩形の4辺のうち、外側にフィールドが最も広く残る辺の外側へ、辺の中央ぞろえで count 個の位置。
## フィールドからはみ出す分は内側へ詰める
func line_points(view: Rect2, count: int, spacing: float) -> Array[Vector2]:
	var field := field_rect()
	var area := view.grow(_data.spawn_margin)
	var sides := [
		[
			Vector2(view.get_center().x, area.position.y),
			Vector2.RIGHT,
			view.position.y - field.position.y
		],
		[Vector2(view.get_center().x, area.end.y), Vector2.RIGHT, field.end.y - view.end.y],
		[
			Vector2(area.position.x, view.get_center().y),
			Vector2.DOWN,
			view.position.x - field.position.x
		],
		[Vector2(area.end.x, view.get_center().y), Vector2.DOWN, field.end.x - view.end.x],
	]
	var far: Array = sides[0]
	for side: Array in sides:
		if side[2] > far[2]:
			far = side
	var along: Vector2 = far[1]
	var half_length := (count - 1) / 2.0 * spacing
	var inner := field.grow(-_data.spawn_margin).grow_individual(
		-half_length * along.x,
		-half_length * along.y,
		-half_length * along.x,
		-half_length * along.y
	)
	var center: Vector2 = far[0].clamp(inner.position, inner.end)
	var points: Array[Vector2] = []
	for i in count:
		var offset := (i - (count - 1) / 2.0) * spacing
		points.append(center + along * offset)
	return points


func field_rect() -> Rect2:
	return Rect2(Vector2.ZERO, _data.field_size)


func is_boss_time() -> bool:
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


## 映す矩形を spawn_margin だけ広げた周上の点。フィールドの外・is_blocked(point) が true の点は引き直す。
## 見つからなければ Vector2.INF
func pick_spawn_point(view: Rect2, is_blocked: Callable) -> Vector2:
	var area := view.grow(_data.spawn_margin)
	var field := field_rect()
	for i in MAX_PICK_TRIES:
		var point := perimeter_point(area, randf())
		if field.has_point(point) and not is_blocked.call(point):
			return point
	return Vector2.INF


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
