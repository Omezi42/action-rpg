class_name AudioSettings
extends RefCounted
## BGM と効果音の音量(GameDesign.md 10章)。0〜MAX_LEVEL の段階で持ち、バスへ反映する。

const MAX_LEVEL := 10
const DEFAULT_LEVEL := 8
const SECTION := "volume"
const BGM_BUS := &"BGM"
const SE_BUS := &"SE"

static var path := "user://settings.cfg"

var bgm := DEFAULT_LEVEL
var se := DEFAULT_LEVEL


static func load_saved() -> AudioSettings:
	var settings := AudioSettings.new()
	var file := ConfigFile.new()
	if file.load(path) == OK:
		settings.bgm = clampi(file.get_value(SECTION, "bgm", DEFAULT_LEVEL), 0, MAX_LEVEL)
		settings.se = clampi(file.get_value(SECTION, "se", DEFAULT_LEVEL), 0, MAX_LEVEL)
	return settings


func save() -> void:
	var file := ConfigFile.new()
	file.set_value(SECTION, "bgm", bgm)
	file.set_value(SECTION, "se", se)
	file.save(path)


func apply() -> void:
	_apply_bus(BGM_BUS, bgm)
	_apply_bus(SE_BUS, se)


static func _apply_bus(bus_name: StringName, level: int) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus < 0:
		return
	AudioServer.set_bus_mute(bus, level <= 0)
	if level > 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(float(level) / MAX_LEVEL))
