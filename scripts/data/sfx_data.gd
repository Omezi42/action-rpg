class_name SfxData
extends Resource
## 合成する効果音1つぶん(GameDesign.md 10章)。音程は freq_start から freq_end へ直線的に変わり、音量は減衰する。

enum Wave { SQUARE, TRIANGLE, NOISE }

@export var wave := Wave.SQUARE
@export var freq_start := 0.0
@export var freq_end := 0.0
@export var duration := 0.0
@export var volume_db := 0.0
## 同じ音をこれより短い間隔では鳴らさない(魂の連続取得など)
@export var min_interval := 0.0
