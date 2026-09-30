class_name IaiCharge
extends RefCounted
## 居合の押し時間から段階と一閃の受付を決める(GameDesign.md 3章)。
## 強化(8章)で各段階の到達時間に hold_scale を掛け、一閃の受付に window_bonus を足す。

var hold_time := 0.0
var hold_scale := 1.0
var window_bonus := 0.0

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
		if hold_time >= threshold(i):
			index = i
	return index


func top_stage_index() -> int:
	return _data.stages.size() - 1


## 段階 index に届く押し時間
func threshold(index: int) -> float:
	return _data.stages[index].hold_time * hold_scale


func is_issen_window() -> bool:
	var top_time := threshold(top_stage_index())
	return hold_time >= top_time and hold_time < top_time + _data.issen_window + window_bonus


## 段階 index(1以上)へ向けた溜まり具合 0〜1
func fill_of(index: int) -> float:
	var from := threshold(index - 1)
	var to := threshold(index)
	return clampf((hold_time - from) / (to - from), 0.0, 1.0)


func release() -> IaiStage:
	if is_issen_window():
		return _data.issen
	return _data.stages[stage_index()]
