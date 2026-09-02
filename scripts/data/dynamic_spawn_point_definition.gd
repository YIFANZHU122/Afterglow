extends Resource
class_name DynamicSpawnPointDefinition

## 动态刷怪点静态契约；地图只提供位置和权重，导演决定是否实际生成。

@export var id: StringName = &""
@export var position: Vector2 = Vector2.ZERO
@export var tags: PackedStringArray = PackedStringArray()
@export_range(1, 8, 1) var threat_cost: int = 1
@export_range(0.0, 100.0, 0.1) var weight: float = 1.0
@export_range(0.0, 1.0, 0.01) var special_weight: float = 0.0


func is_valid() -> bool:
	if id.is_empty() or not position.is_finite() or threat_cost < 1 or threat_cost > 8 \
		or not is_finite(weight) or weight <= 0.0 or not is_finite(special_weight) or special_weight < 0.0 or special_weight > 1.0:
		return false
	var seen: Dictionary = {}
	for tag: String in tags:
		if tag.is_empty() or seen.has(tag):
			return false
		seen[tag] = true
	return true
