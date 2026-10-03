class_name Sfx
extends Node
## 効果音(GameDesign.md 10章)。autoload `SfxPlayer` として置き、SfxBank の素材(無ければ合成した波形)を
## 決まった数のプレイヤーで順に鳴らす。鳴らす側は `Sfx.play()`(autoload が無いテストでは何もしない)。

const BANK_PATH := "res://data/sfx.tres"
const MIX_RATE := 22050
const VOICES := 8
const ATTACK_TIME := 0.004
const MSEC_PER_SEC := 1000.0
const NODE_PATH := "/root/SfxPlayer"
const BUS := &"SE"
const SEMITONES_PER_OCTAVE := 12.0

var _sounds: Dictionary[StringName, SfxData] = {}
var _streams: Dictionary[StringName, Array] = {}
var _last_played: Dictionary[StringName, int] = {}
var _players: Array[AudioStreamPlayer] = []
var _next_voice := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioSettings.load_saved().apply()
	var bank: SfxBank = load(BANK_PATH)
	for key in bank.sounds:
		var sfx: SfxData = bank.sounds[key]
		_sounds[key] = sfx
		_streams[key] = sfx.streams if not sfx.streams.is_empty() else [synthesize(sfx)]
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = BUS
		add_child(player)
		_players.append(player)


static func play(sound: StringName) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var node := tree.root.get_node_or_null(NODE_PATH) as Sfx if tree else null
	if node:
		node.play_sound(sound)


func play_sound(sound: StringName) -> void:
	if not _sounds.has(sound):
		push_warning("unknown sfx: %s" % sound)
		return
	var sfx := _sounds[sound]
	var now := Time.get_ticks_msec()
	if _last_played.has(sound) and now - _last_played[sound] < sfx.min_interval * MSEC_PER_SEC:
		return
	_last_played[sound] = now
	var player := _players[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	player.stream = _streams[sound].pick_random()
	player.volume_db = sfx.volume_db if not sfx.streams.is_empty() else 0.0
	player.pitch_scale = pitch_scale(
		sfx.pitch_shift + randf_range(-sfx.pitch_jitter, sfx.pitch_jitter)
	)
	player.play()


static func pitch_scale(semitones: float) -> float:
	return pow(2.0, semitones / SEMITONES_PER_OCTAVE)


static func synthesize(sfx: SfxData) -> AudioStreamWAV:
	var count := int(sfx.duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	var noise_value := 0.0
	var amplitude := db_to_linear(sfx.volume_db)
	for i in count:
		var t := float(i) / count
		var freq := lerpf(sfx.freq_start, sfx.freq_end, t)
		var previous := phase
		phase = fmod(phase + freq / MIX_RATE, 1.0)
		var sample := 0.0
		match sfx.wave:
			SfxData.Wave.SQUARE:
				sample = 1.0 if phase < 0.5 else -1.0
			SfxData.Wave.TRIANGLE:
				sample = 4.0 * absf(phase - 0.5) - 1.0
			SfxData.Wave.NOISE:
				if phase < previous:
					noise_value = randf_range(-1.0, 1.0)
				sample = noise_value
		var attack := minf(float(i) / (ATTACK_TIME * MIX_RATE), 1.0)
		var decay := pow(1.0 - t, 2.0)
		data.encode_s16(i * 2, int(sample * attack * decay * amplitude * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.data = data
	return stream
