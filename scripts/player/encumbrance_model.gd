extends RefCounted
class_name EncumbranceModel

## 负重等级和行动许可模型。

const DEFAULT_BASE_CAPACITY: float = 20.0
const NORMAL_SPEED_MULTIPLIER: float = 1.0

var _base_capacity: float
var _bonus_capacity: float = 0.0
var _current_weight: float = 0.0


func _init(base_capacity: float = DEFAULT_BASE_CAPACITY) -> void:
	_base_capacity = maxf(base_capacity, 0.0) if is_finite(base_capacity) else DEFAULT_BASE_CAPACITY


func set_base_capacity(value: float) -> bool:
	if not is_finite(value) or value < 0.0:
		return false
	_base_capacity = value
	return true


func set_bonus_capacity(value: float) -> bool:
	if not is_finite(value):
		return false
	_bonus_capacity = value
	return true


func set_current_weight(value: float) -> bool:
	if not is_finite(value) or value < 0.0:
		return false
	_current_weight = value
	return true


func get_current_weight() -> float:
	return _current_weight


func get_max_capacity() -> float:
	return maxf(_base_capacity + _bonus_capacity, 0.0)


func get_ratio() -> float:
	var capacity := get_max_capacity()
	return _current_weight / capacity if capacity > 0.0 else (INF if _current_weight > 0.0 else 0.0)


func get_speed_multiplier() -> float:
	var ratio := get_ratio()
	if ratio <= 1.0: return 1.0
	if ratio <= 1.1: return 0.9
	if ratio <= 1.25: return 0.8
	if ratio <= 1.4: return 0.65
	return 0.5


func get_stamina_cost_multiplier() -> float:
	var ratio := get_ratio()
	if ratio <= 1.0: return 1.0
	if ratio <= 1.1: return 1.1
	if ratio <= 1.25: return 1.25
	if ratio <= 1.4: return 1.5
	return 2.0


func can_run() -> bool:
	return get_ratio() <= 1.25


func can_high_intensity_action() -> bool:
	return get_ratio() <= 1.4


func can_swim() -> bool:
	return get_ratio() <= 1.4


func can_vault() -> bool:
	return get_ratio() <= 1.4


func create_snapshot() -> Dictionary:
	return {"format_version": 1, "base_capacity": _base_capacity, "bonus_capacity": _bonus_capacity, "current_weight": _current_weight}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if int(snapshot.get("format_version", -1)) != 1:
		return false
	var base := _parse_non_negative_float(snapshot.get("base_capacity", -1.0))
	var bonus := _parse_finite_float(snapshot.get("bonus_capacity", 0.0))
	var weight := _parse_non_negative_float(snapshot.get("current_weight", -1.0))
	if base < 0.0 or not is_finite(bonus) or weight < 0.0:
		return false
	_base_capacity = base
	_bonus_capacity = bonus
	_current_weight = weight
	return true


func _parse_non_negative_float(value: Variant) -> float:
	var parsed := _parse_finite_float(value)
	return parsed if parsed >= 0.0 else -1.0


func _parse_finite_float(value: Variant) -> float:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return INF
	var parsed := float(value)
	return parsed if is_finite(parsed) else INF
