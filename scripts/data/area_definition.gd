extends Resource
class_name AreaDefinition

## 通用区域配置；不把区域组织方式限定为楼层或爬塔。

const ENCOUNTER_DEFINITION_SCRIPT: Script = preload("res://scripts/data/encounter_definition.gd")

@export var id: StringName = &""
@export var display_name: String = ""
@export var encounter: Resource


func is_valid() -> bool:
	return not id.is_empty() and encounter != null \
		and encounter.get_script() == ENCOUNTER_DEFINITION_SCRIPT \
		and bool(encounter.call("is_valid"))
