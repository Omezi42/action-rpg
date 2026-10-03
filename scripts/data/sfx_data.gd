class_name SfxData
extends Resource
## 効果音1つぶん(GameDesign.md 10章)。streams があれば鳴らすたびにその中から1つ選ぶ。
## 空なら wave から合成する(音程は freq_start から freq_end へ直線的に変わり、音量は減衰する)。

enum Wave { SQUARE, TRIANGLE, NOISE }

@export var streams: Array[AudioStream] = []
@export var wave := Wave.SQUARE
@export var freq_start := 0.0
@export var freq_end := 0.0
@export var duration := 0.0
@export var volume_db := 0.0
## 同じ音をこれより短い間隔では鳴らさない(魂の連続取得など)
@export var min_interval := 0.0
## 音程をずらす量(半音)
@export var pitch_shift := 0.0
## 鳴らすたびに ±この量(半音)の範囲で音程を揺らす
@export var pitch_jitter := 0.0
