class_name UpgradeData
extends Resource
## 強化1種(GameDesign.md 8章の強化表の1行)。

enum Stat {
	CHARGE_TIME,
	DASH_DISTANCE,
	POWER,
	ISSEN_WINDOW,
	MOVE_SPEED,
	MAX_HP,
	HEAL,
	LINGER,
	SHOCKWAVE,
	FULL_HEAL,
	RETURN_SLASH,
	SHADOW_BIND,
	OUGI_HOMURA,
	OUGI_DAIZANSHIN,
	OUGI_TSUBAME,
	OUGI_KAGE,
}

## STAT:数値の強化 / BEHAVIOR:挙動の強化(巻物の候補)/ OUGI:奥義(巻物だけに出る)。GameDesign.md 8章
enum Kind { STAT, BEHAVIOR, OUGI }

@export var label := ""
@export_multiline var description := ""
@export var stat := Stat.CHARGE_TIME
@export var amount := 0.0
## 1段目だけ違う値にするとき(影縫い)。0なら amount
@export var base_amount := 0.0
@export var max_level := 0
@export var kind := Kind.STAT
## 奥義が巻物に出る条件(UpgradeData)。すべて max_level に達していること。
## 自分の型の配列にするとスクリプトが自分を参照し続けて解放されないので Resource で持つ
@export var requires: Array[Resource] = []
