class_name SpawnPhase
extends Resource
## 出現の区間1つ(GameDesign.md 5章の区間表の1行)。区間の終わりは次の区間の start_time。

@export var start_time := 0.0
@export var interval_start := 0.0
@export var interval_end := 0.0
@export var max_enemies := 0
