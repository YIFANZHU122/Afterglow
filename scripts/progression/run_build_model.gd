extends RefCounted
class_name RunBuildModel

## 本局强化运行时状态，不依赖场景、节点树或 UI。

const BASE_MULTIPLIER: float = 1.0
const UPGRADE_DEFINITION_SCRIPT: Script = preload("res://scripts/data/upgrade_definition.gd")

var _damage_multiplier: float = BASE_MULTIPLIER
var _move_speed_multiplier: float = BASE_MULTIPLIER
var _upgrade_stacks: Dictionary = {}


func apply_upgrade(definition: Resource) -> bool:
	if definition == null or definition.get_script() != UPGRADE_DEFINITION_SCRIPT \
		or not bool(definition.call("is_valid")):
		return false
	var upgrade_id: StringName = StringName(definition.get("id"))
	var effect_type: int = int(definition.get("effect_type"))
	var amount: float = float(definition.get("amount"))
	_upgrade_stacks[upgrade_id] = int(_upgrade_stacks.get(upgrade_id, 0)) + 1
	match effect_type:
		UPGRADE_DEFINITION_SCRIPT.EffectType.DAMAGE_MULTIPLIER:
			_damage_multiplier += amount
		UPGRADE_DEFINITION_SCRIPT.EffectType.MOVE_SPEED_MULTIPLIER:
			_move_speed_multiplier += amount
		_:
			_upgrade_stacks.erase(upgrade_id)
			return false
	return true


func get_damage_multiplier() -> float:
	return _damage_multiplier


func get_move_speed_multiplier() -> float:
	return _move_speed_multiplier


func get_upgrade_stack(upgrade_id: StringName) -> int:
	return int(_upgrade_stacks.get(upgrade_id, 0))


func reset() -> bool:
	var changed: bool = _damage_multiplier != BASE_MULTIPLIER \
		or _move_speed_multiplier != BASE_MULTIPLIER \
		or not _upgrade_stacks.is_empty()
	_damage_multiplier = BASE_MULTIPLIER
	_move_speed_multiplier = BASE_MULTIPLIER
	_upgrade_stacks.clear()
	return changed
