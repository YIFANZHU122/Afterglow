extends Resource
class_name EncounterSpawnDefinition

## 一个区域遭遇中的静态生成项。

@export var entity_scene: PackedScene
@export var spawn_position: Vector2 = Vector2.ZERO


func is_valid() -> bool:
	return entity_scene != null
