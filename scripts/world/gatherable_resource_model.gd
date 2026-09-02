extends RefCounted
class_name GatherableResourceModel

## 有限世界资源的运行时数量模型，不依赖节点或 Inventory。

const SURVIVAL_TUNING_SCRIPT: Script = preload("res://scripts/data/survival_tuning.gd")
const WORLD_RESOURCE_DEFINITION_SCRIPT: Script = preload("res://scripts/data/world_resource_definition.gd")

var _definition: Resource
var _entity_id: StringName
var _remaining_units: int = 0
var _initial_units: int = 0


func _init(
	definition: Resource = null,
	difficulty: int = 0,
	entity_id: StringName = StringName()
) -> void:
	_definition = definition
	_entity_id = entity_id if not entity_id.is_empty() else (definition.id if definition != null else StringName())
	if definition != null and definition.is_valid():
		_initial_units = maxi(
			roundi(float(definition.base_units) * SURVIVAL_TUNING_SCRIPT.difficulty_resource_richness(difficulty)),
			1
		)
		_remaining_units = _initial_units


func get_definition() -> Resource:
	return _definition


func get_entity_id() -> StringName:
	return _entity_id


func get_remaining_units() -> int:
	return _remaining_units


func is_depleted() -> bool:
	return _remaining_units <= 0


func gather_once() -> int:
	if _definition == null or is_depleted():
		return 0
	var gathered: int = mini(_definition.gather_amount, _remaining_units)
	_remaining_units -= gathered
	return gathered


func create_snapshot() -> Dictionary:
	return {
		"entity_id": String(_entity_id),
		"remaining_units": _remaining_units,
		"depleted": is_depleted(),
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if snapshot.size() != 3 or not snapshot.has("entity_id") or not snapshot.has("remaining_units") or not snapshot.has("depleted"):
		return false
	if snapshot["entity_id"] is not String or snapshot["depleted"] is not bool:
		return false
	if StringName(snapshot["entity_id"]) != _entity_id:
		return false
	var remaining: int = _to_integral(snapshot["remaining_units"])
	if _definition == null or remaining < 0 or remaining > _initial_units:
		return false
	if bool(snapshot["depleted"]) != (remaining == 0):
		return false
	_remaining_units = remaining
	return true


func _to_integral(value: Variant) -> int:
	if value is int:
		return value
	if value is float and is_finite(value) and is_equal_approx(value, floor(value)):
		return int(value)
	return -1
