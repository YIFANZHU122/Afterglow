extends Area2D

## 传送区域
## 玩家进入后切换到 target_scene，并在目标场景的 spawn_point_name 出生点出现

# 目标场景路径（res:// 开头）
@export var target_scene: String = ""

# 目标场景中的出生点节点名称
@export var spawn_point_name: String = "PlayerSpawn"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not GameManager.can_transition():
		return
	if body.is_in_group("player"):
		GameManager.change_scene(target_scene, spawn_point_name)
