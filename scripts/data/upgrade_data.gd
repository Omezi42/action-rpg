class_name UpgradeData
extends Resource
## 強化1種ぶん(GameDesign.md 8章)。data/upgrades/ に置けば3択の候補に加わる。
## 1段上げるごとに PlayerStats の stat へ amount を足す(ADD)か掛ける(MULTIPLY)。

enum Mode { ADD, MULTIPLY }

@export var title := ""
@export_multiline var description := ""
@export var max_level := 0
@export var stat: StringName
@export var mode := Mode.ADD
@export var amount := 0.0
## 正なら能力値を変えず、HPをこれだけ回復する(手当)
@export var heal := 0
