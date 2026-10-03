class_name BgmBank
extends Resource
## 場面ごとの BGM(GameDesign.md 10章)。名前で引く。

@export var tracks: Dictionary[StringName, BgmData] = {}
## 次の曲へ入れ替える時間(秒)
@export var fade_time := 0.0
## 時間が止まっている間に下げる量(dB)
@export var duck_db := 0.0
