class_name RunRecords
extends RefCounted
## 最高記録の読み書き(GameDesign.md 9章)。テストと撮影は path を別のファイルへ向ける。

const SECTION := "records"
const KEYS := ["best_time", "best_kills", "best_level", "clears", "plays"]

static var path := "user://records.cfg"

var best_time := 0.0
var best_kills := 0
var best_level := 0
var clears := 0
var plays := 0


static func load_saved() -> RunRecords:
	var records := RunRecords.new()
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return records
	for key in KEYS:
		records.set(key, file.get_value(SECTION, key, records.get(key)))
	return records


## 1回の挑戦の結果を記録して保存する。更新した最高記録の名前を返す
func submit(survived: float, kills: int, level: int, cleared: bool) -> Array[String]:
	var updated: Array[String] = []
	if survived > best_time:
		best_time = survived
		updated.append("best_time")
	if kills > best_kills:
		best_kills = kills
		updated.append("best_kills")
	if level > best_level:
		best_level = level
		updated.append("best_level")
	plays += 1
	if cleared:
		clears += 1
	save()
	return updated


func save() -> void:
	var file := ConfigFile.new()
	for key in KEYS:
		file.set_value(SECTION, key, get(key))
	file.save(path)
