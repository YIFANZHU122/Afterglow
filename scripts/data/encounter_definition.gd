extends Resource
class_name EncounterDefinition

## 区域中一次遭遇的静态配置。

const ENCOUNTER_SPAWN_DEFINITION_SCRIPT: Script = preload("res://scripts/data/encounter_spawn_definition.gd")

@export var objective_text: String = "击败全部敌人"
@export var spawns: Array[Resource] = []


func get_target_count() -> int:
	var count: int = 0
	for spawn: Resource in spawns:
		if spawn != null and spawn.get_script() == ENCOUNTER_SPAWN_DEFINITION_SCRIPT \
			and bool(spawn.call("is_valid")):
			count += 1
	return count


func is_valid() -> bool:
	return get_target_count() > 0
