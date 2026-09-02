extends Node

## 区域配置的最小场景注入点；不改变运行时规则，仅公开独立区域身份。

@export var region_id: StringName = &""


func get_region_id() -> StringName:
	return region_id
