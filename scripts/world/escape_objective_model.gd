extends RefCounted
class_name EscapeObjectiveModel

## 当前地图的逃生物资和出口启动进度，不依赖拾取节点、输入或 HUD。

enum MaterialType {
	PARTS,
	FUEL,
	CLOTH,
	KEY,
}

const MATERIAL_TYPE_COUNT: int = 4
const MIN_BASIC_REQUIREMENT: int = 2
const MAX_BASIC_REQUIREMENT: int = 4
const KEY_REQUIREMENT: int = 1
const EXIT_STARTUP_REQUIRED_SECONDS: float = 10.0

var _required: PackedInt32Array = PackedInt32Array()
var _collected: PackedInt32Array = PackedInt32Array()
var _exit_startup_seconds: float = 0.0
var _exit_started: bool = false


func _init(parts_required: int = 2, fuel_required: int = 2, cloth_required: int = 2) -> void:
	_required = PackedInt32Array([
		clampi(parts_required, MIN_BASIC_REQUIREMENT, MAX_BASIC_REQUIREMENT),
		clampi(fuel_required, MIN_BASIC_REQUIREMENT, MAX_BASIC_REQUIREMENT),
		clampi(cloth_required, MIN_BASIC_REQUIREMENT, MAX_BASIC_REQUIREMENT),
		KEY_REQUIREMENT,
	])
	_collected.resize(MATERIAL_TYPE_COUNT)
	_collected.fill(0)


func collect_material(material_type: int, amount: int = 1) -> bool:
	if not _is_valid_material_type(material_type) or amount <= 0:
		return false
	var current: int = _collected[material_type]
	var required: int = _required[material_type]
	if current >= required:
		return false
	_collected[material_type] = mini(current + amount, required)
	return true


func get_required_amount(material_type: int) -> int:
	return _required[material_type] if _is_valid_material_type(material_type) else 0


func get_collected_amount(material_type: int) -> int:
	return _collected[material_type] if _is_valid_material_type(material_type) else 0


func has_all_materials() -> bool:
	for material_type: int in range(MATERIAL_TYPE_COUNT):
		if _collected[material_type] < _required[material_type]:
			return false
	return true


func advance_exit_startup(
	delta: float,
	player_moving: bool,
	was_hit: bool,
	enemy_nearby: bool
) -> bool:
	if delta <= 0.0 or _exit_started or not has_all_materials():
		return false
	if player_moving or was_hit or enemy_nearby:
		return false
	_exit_startup_seconds = minf(
		_exit_startup_seconds + delta,
		EXIT_STARTUP_REQUIRED_SECONDS
	)
	_exit_started = _exit_startup_seconds >= EXIT_STARTUP_REQUIRED_SECONDS
	return _exit_started


func get_exit_startup_seconds() -> float:
	return _exit_startup_seconds


func is_exit_started() -> bool:
	return _exit_started


func consume_for_departure() -> bool:
	if not _exit_started or not has_all_materials():
		return false
	_collected.fill(0)
	_exit_startup_seconds = 0.0
	_exit_started = false
	return true


func _is_valid_material_type(material_type: int) -> bool:
	return material_type >= 0 and material_type < MATERIAL_TYPE_COUNT


func create_snapshot() -> Dictionary:
	return {
		"required": Array(_required),
		"collected": Array(_collected),
		"exit_startup_seconds": _exit_startup_seconds,
		"exit_started": _exit_started,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["required", "collected", "exit_startup_seconds", "exit_started"]:
		if not snapshot.has(key):
			return false
	var required: Array = snapshot["required"] as Array
	var collected: Array = snapshot["collected"] as Array
	if required.size() != MATERIAL_TYPE_COUNT or collected.size() != MATERIAL_TYPE_COUNT:
		return false
	var normalized_required := PackedInt32Array()
	var normalized_collected := PackedInt32Array()
	for index in range(MATERIAL_TYPE_COUNT):
		var required_value: int = int(required[index])
		var collected_value: int = int(collected[index])
		if required_value < 1 or collected_value < 0 or collected_value > required_value:
			return false
		normalized_required.append(required_value)
		normalized_collected.append(collected_value)
	var startup: float = float(snapshot["exit_startup_seconds"])
	if startup < 0.0 or startup > EXIT_STARTUP_REQUIRED_SECONDS:
		return false
	_required = normalized_required
	_collected = normalized_collected
	_exit_startup_seconds = startup
	_exit_started = bool(snapshot["exit_started"])
	return true
