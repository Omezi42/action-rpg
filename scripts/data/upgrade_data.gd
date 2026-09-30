class_name UpgradeData
extends Resource
## 強化1種(GameDesign.md 8章の強化表の1行)。

enum Stat { CHARGE_TIME, DASH_DISTANCE, POWER, ISSEN_WINDOW, MOVE_SPEED, MAX_HP, HEAL }

@export var label := ""
@export_multiline var description := ""
@export var stat := Stat.CHARGE_TIME
@export var amount := 0.0
@export var max_level := 0
