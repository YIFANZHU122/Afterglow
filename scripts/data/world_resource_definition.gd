extends Resource
class_name WorldResourceDefinition

## 可采集世界资源的静态内容定义；不保存运行时剩余数量。

@export var id: StringName = &""
@export var display_name: String = ""
@export var output_item: ItemData
@export_range(1, 999, 1) var base_units: int = 1
@export_range(1, 999, 1) var gather_amount: int = 1
@export var display_color: Color = Color.WHITE


func is_valid() -> bool:
	return not id.is_empty() \
		and not display_name.is_empty() \
		and output_item != null \
		and output_item.is_valid() \
		and base_units >= 1 \
		and gather_amount >= 1
