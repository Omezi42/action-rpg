extends RefCounted
## 効果音・BGM・音量を確かめる(GameDesign.md 10章)。

const SFX_BANK := preload("res://data/sfx.tres")
const BGM_BANK := preload("res://data/bgm.tres")
const PauseMenu = preload("res://scripts/ui/pause_menu.gd")
const SOUND_NAMES: Array[StringName] = [
	&"stage_1",
	&"stage_2",
	&"issen",
	&"dash",
	&"hit",
	&"chin",
	&"hurt",
	&"soul",
	&"level_up",
	&"boss_appear",
	&"boss_warn",
	&"boss_defeat",
	&"shot",
	&"confirm",
	&"cursor",
	&"purchase",
	&"hitokiri",
	&"elite_appear",
	&"scroll",
	&"return",
	&"guard",
	&"clear",
	&"game_over",
]
const TRACK_NAMES: Array[StringName] = [&"title", &"battle", &"boss"]
const OCTAVE := 12.0

var _tree: SceneTree


func run(tree: SceneTree, check: Callable) -> void:
	_tree = tree
	_test_banks(check)
	_test_settings(check)
	_test_bgm_switch(check)
	_test_pause_volume(check)


func _test_banks(check: Callable) -> void:
	var sounds: Dictionary = SFX_BANK.sounds
	for sound in SOUND_NAMES:
		check.call(sounds.has(sound), "効果音 %s がある" % sound)
	for sound in sounds:
		var sfx: SfxData = sounds[sound]
		var playable := (
			sfx.duration > 0.0 or (not sfx.streams.is_empty() and not sfx.streams.has(null))
		)
		check.call(playable, "効果音 %s は素材か合成で鳴らせる" % sound)
	for track in TRACK_NAMES:
		check.call(
			BGM_BANK.tracks.has(track) and BGM_BANK.tracks[track].stream != null,
			"BGM %s がある" % track
		)
	check.call(is_equal_approx(Sfx.pitch_scale(OCTAVE), 2.0), "12半音上げると周波数が2倍")


func _test_settings(check: Callable) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(AudioSettings.path))
	var settings := AudioSettings.load_saved()
	check.call(
		settings.bgm == AudioSettings.DEFAULT_LEVEL and settings.se == AudioSettings.DEFAULT_LEVEL,
		"設定が無ければ既定の音量"
	)
	settings.bgm = 3
	settings.se = 0
	settings.save()
	var loaded := AudioSettings.load_saved()
	check.call(loaded.bgm == 3 and loaded.se == 0, "保存した音量を読める")
	loaded.apply()
	var se_bus := AudioServer.get_bus_index(AudioSettings.SE_BUS)
	var bgm_bus := AudioServer.get_bus_index(AudioSettings.BGM_BUS)
	check.call(se_bus >= 0 and bgm_bus >= 0, "BGM と SE のバスがある")
	check.call(AudioServer.is_bus_mute(se_bus), "音量0はミュート")
	check.call(
		not AudioServer.is_bus_mute(bgm_bus) and AudioServer.get_bus_volume_db(bgm_bus) < 0.0,
		"音量3は下がる"
	)
	var file := ConfigFile.new()
	file.set_value(AudioSettings.SECTION, "bgm", AudioSettings.MAX_LEVEL + 5)
	file.save(AudioSettings.path)
	check.call(AudioSettings.load_saved().bgm == AudioSettings.MAX_LEVEL, "範囲外の音量は丸める")
	AudioSettings.new().apply()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(AudioSettings.path))


func _test_bgm_switch(check: Callable) -> void:
	var bgm := Bgm.new()
	_tree.root.add_child(bgm)
	bgm.play_track(&"battle")
	check.call(bgm.current == &"battle", "曲を切り替える")
	var active := bgm._active
	bgm.play_track(&"battle")
	check.call(bgm._active == active, "同じ曲は鳴らし直さない")
	bgm.play_track(&"boss")
	check.call(bgm.current == &"boss" and bgm._active != active, "別の曲はもう一方のプレイヤーで鳴らす")
	bgm.play_track(&"")
	check.call(bgm.current == &"", "止める")
	bgm.free()


func _test_pause_volume(check: Callable) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(AudioSettings.path))
	var pause: CanvasLayer = PauseMenu.new()
	_tree.root.add_child(pause)
	pause.change_level(0, -1)
	pause.change_level(1, 1)
	pause.change_level(1, 1)
	pause.change_level(1, 1)
	var loaded := AudioSettings.load_saved()
	check.call(loaded.bgm == AudioSettings.DEFAULT_LEVEL - 1, "ポーズ画面で BGM の音量を下げて保存する")
	check.call(loaded.se == AudioSettings.MAX_LEVEL, "効果音の音量は最大で止まる")
	pause.free()
	AudioSettings.new().apply()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(AudioSettings.path))
