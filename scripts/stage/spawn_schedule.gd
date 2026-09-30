class_name SpawnSchedule
extends RefCounted
## 経過時間・出現の番・出現位置の計算(GameDesign.md 5章)。ノードを持たないのでテストから直接使える。

const MAX_PICK_TRIES := 16

var elapsed := 0.0

var _data: SurvivalData
var _next_spawn := 0.0
var _next_horde := 0


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
	var index := _phase_index(time)
	var phase := _data.phases[index]
	var end_time := _data.clear_time
	if index + 1 < _data.phases.size():
		end_time = _data.phases[index + 1].start_time
	var t := clampf(inverse_lerp(phase.start_time, end_time, time), 0.0, 1.0)
	return lerpf(phase.interval_start, phase.interval_end, t)


func max_enemies_at(time: float) -> int:
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


## 主人公から最も遠い辺の沿いに、辺の中央ぞろえで horde_count 体ぶんの位置
func horde_points(screen: Rect2, player_pos: Vector2) -> Array[Vector2]:
	var area := screen.grow(-_data.spawn_margin)
	var sides := [
		[area.position, Vector2(area.end.x, area.position.y), player_pos.y - area.position.y],
		[Vector2(area.position.x, area.end.y), area.end, area.end.y - player_pos.y],
		[area.position, Vector2(area.position.x, area.end.y), player_pos.x - area.position.x],
		[Vector2(area.end.x, area.position.y), area.end, area.end.x - player_pos.x],
	]
	var far: Array = sides[0]
	for side: Array in sides:
		if side[2] > far[2]:
			far = side
	var from: Vector2 = far[0]
	var to: Vector2 = far[1]
	var along := from.direction_to(to)
	var center := (from + to) / 2.0
	var points: Array[Vector2] = []
	for i in _data.horde_count:
		var offset := (i - (_data.horde_count - 1) / 2.0) * _data.horde_spacing
		points.append(center + along * offset)
	return points


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
