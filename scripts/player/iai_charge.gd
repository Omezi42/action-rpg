class_name IaiCharge
extends RefCounted
## 居合の押し時間から段階と一閃の受付を決める(GameDesign.md 3章)。

var hold_time := 0.0

var _data: IaiData


func _init(data: IaiData) -> void:
	_data = data


func reset() -> void:
	hold_time = 0.0


## 段階が上がった瞬間に true を返す
func advance(delta: float) -> bool:
	var before := stage_index()
	hold_time += delta
	return stage_index() > before


func stage_index() -> int:
	var index := 0
	for i in _data.stages.size():
		if hold_time >= _data.stages[i].hold_time:
			index = i
	return index


func top_stage_index() -> int:
	return _data.stages.size() - 1


func is_issen_window() -> bool:
	var top_time := _data.stages[top_stage_index()].hold_time
	return hold_time >= top_time and hold_time < top_time + _data.issen_window


## 段階 index(1以上)へ向けた溜まり具合 0〜1
func fill_of(index: int) -> float:
	var from := _data.stages[index - 1].hold_time
	var to := _data.stages[index].hold_time
	return clampf((hold_time - from) / (to - from), 0.0, 1.0)


func release() -> IaiStage:
	if is_issen_window():
		return _data.issen
	return _data.stages[stage_index()]
