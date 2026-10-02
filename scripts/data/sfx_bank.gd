class_name SfxBank
extends Resource
## 効果音の一覧(GameDesign.md 10章)。名前で引く。素材が届いたら同じ名前で差し替える。

@export var sounds: Dictionary[StringName, SfxData] = {}
