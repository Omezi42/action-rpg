class_name Bgm
extends Node
## BGM(GameDesign.md 10章)。autoload `BgmPlayer` として置き、2つのプレイヤーを交互に使って曲を入れ替える。
## 時間が止まっている間は下げる。鳴らす側は `Bgm.play()` / `Bgm.stop()`(autoload が無いテストでは何もしない)。

const BANK_PATH := "res://data/bgm.tres"
const NODE_PATH := "/root/BgmPlayer"
const BUS := &"BGM"
const SILENT_DB := -60.0

var current := &""
var _bank: BgmBank
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _fade := 1.0
var _duck := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bank = load(BANK_PATH)
	for data: BgmData in _bank.tracks.values():
		if "loop" in data.stream:
			data.stream.loop = true
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = BUS
		add_child(player)
		_players.append(player)


static func play(track: StringName) -> void:
	var node := _node()
	if node:
		node.play_track(track)


static func stop() -> void:
	var node := _node()
	if node:
		node.play_track(&"")


static func _node() -> Bgm:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null(NODE_PATH) as Bgm if tree else null


func play_track(track: StringName) -> void:
	if track == current:
		return
	if track != &"" and not _bank.tracks.has(track):
		push_warning("unknown bgm: %s" % track)
		return
	current = track
	_active = 1 - _active
	_fade = 0.0
	var player := _players[_active]
	if track == &"":
		player.stop()
		return
	player.stream = _bank.tracks[track].stream
	player.volume_db = SILENT_DB
	player.play()


func _process(delta: float) -> void:
	_fade = minf(_fade + delta / _bank.fade_time, 1.0)
	var target_duck := _bank.duck_db if get_tree().paused else 0.0
	_duck = move_toward(_duck, target_duck, absf(_bank.duck_db) * delta / _bank.fade_time)
	var incoming := _players[_active]
	var outgoing := _players[1 - _active]
	if incoming.playing:
		incoming.volume_db = _volume(current, _fade)
	if outgoing.playing:
		outgoing.volume_db = lerpf(outgoing.volume_db, SILENT_DB, _fade)
		if _fade >= 1.0:
			outgoing.stop()


func _volume(track: StringName, weight: float) -> float:
	var full := _bank.tracks[track].volume_db + _duck
	return lerpf(SILENT_DB, full, weight)
