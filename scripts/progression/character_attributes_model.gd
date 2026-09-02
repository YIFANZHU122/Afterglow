extends RefCounted
class_name CharacterAttributesModel

## 本局属性分配模型；不依赖场景、UI 或 Autoload。

const FORMAT_VERSION: int = 1
const INITIAL_POINTS: int = 10
const MAX_VALUE: int = 20
const MAX_TOTAL_POINTS: int = MAX_VALUE * 3
const INTELLIGENCE_CRAFTING_TIME_REDUCTION: float = 0.03
const INTELLIGENCE_MATERIAL_DISCOUNT: float = 0.03
const MAX_MATERIAL_DISCOUNT: float = 0.15
const STRENGTH_MELEE_DAMAGE_BONUS: float = 0.04
const STRENGTH_CARRY_CAPACITY_BONUS: float = 2.0
const STRENGTH_GATHERING_TIME_REDUCTION: float = 0.02
const VITALITY_HEALTH_BONUS: float = 4.0
const VITALITY_STAMINA_BONUS: float = 6.0
const VITALITY_REGEN_BONUS: float = 0.01

enum Attribute {
	INTELLIGENCE,
	STRENGTH,
	VITALITY,
}

var _values: Dictionary = {
	Attribute.INTELLIGENCE: 0,
	Attribute.STRENGTH: 0,
	Attribute.VITALITY: 0,
}
var _total_points: int = INITIAL_POINTS
var _points_remaining: int = INITIAL_POINTS
var _confirmed: bool = false


func _init(total_points: int = INITIAL_POINTS) -> void:
	_total_points = clampi(total_points, 0, MAX_TOTAL_POINTS)
	_points_remaining = _total_points


func get_total_points() -> int:
	return _total_points


func get_points_remaining() -> int:
	return _points_remaining


func get_value(attribute: int) -> int:
	return int(_values.get(attribute, 0))


func allocate(attribute: int, amount: int = 1) -> bool:
	if _confirmed or not _is_valid_attribute(attribute) or amount <= 0:
		return false
	if amount > _points_remaining or get_value(attribute) + amount > MAX_VALUE:
		return false
	_values[attribute] = get_value(attribute) + amount
	_points_remaining -= amount
	return true


func confirm() -> bool:
	if _confirmed or _points_remaining != 0:
		return false
	_confirmed = true
	return true


func is_confirmed() -> bool:
	return _confirmed


func get_crafting_speed_multiplier() -> float:
	return maxf(1.0 - get_value(Attribute.INTELLIGENCE) * INTELLIGENCE_CRAFTING_TIME_REDUCTION, 0.5)


func get_crafting_material_discount_limit() -> float:
	return minf(get_value(Attribute.INTELLIGENCE) * INTELLIGENCE_MATERIAL_DISCOUNT, MAX_MATERIAL_DISCOUNT)


func get_melee_damage_multiplier() -> float:
	return 1.0 + get_value(Attribute.STRENGTH) * STRENGTH_MELEE_DAMAGE_BONUS


func get_carry_capacity_bonus() -> float:
	return get_value(Attribute.STRENGTH) * STRENGTH_CARRY_CAPACITY_BONUS


func get_gathering_speed_multiplier() -> float:
	return maxf(1.0 - get_value(Attribute.STRENGTH) * STRENGTH_GATHERING_TIME_REDUCTION, 0.6)


func get_max_health_bonus() -> float:
	return get_value(Attribute.VITALITY) * VITALITY_HEALTH_BONUS


func get_max_stamina_bonus() -> float:
	return get_value(Attribute.VITALITY) * VITALITY_STAMINA_BONUS


func get_stamina_regen_multiplier() -> float:
	return 1.0 + get_value(Attribute.VITALITY) * VITALITY_REGEN_BONUS


func has_unlock_at_least(attribute: int, threshold: int) -> bool:
	return _is_valid_attribute(attribute) and threshold >= 0 and get_value(attribute) >= threshold


func create_snapshot() -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"total_points": _total_points,
		"values": {
			"intelligence": get_value(Attribute.INTELLIGENCE),
			"strength": get_value(Attribute.STRENGTH),
			"vitality": get_value(Attribute.VITALITY),
		},
		"points_remaining": _points_remaining,
		"confirmed": _confirmed,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if snapshot.is_empty() or int(snapshot.get("format_version", -1)) != FORMAT_VERSION:
		return false
	var raw_values: Variant = snapshot.get("values", null)
	if not raw_values is Dictionary:
		return false
	var restored: Dictionary = {}
	for key: String in ["intelligence", "strength", "vitality"]:
		var value := _parse_non_negative_int((raw_values as Dictionary).get(key, -1))
		if value < 0 or value > MAX_VALUE:
			return false
		restored[_attribute_from_key(key)] = value
	var remaining := _parse_non_negative_int(snapshot.get("points_remaining", -1))
	if remaining < 0:
		return false
	var total := int(restored[Attribute.INTELLIGENCE]) + int(restored[Attribute.STRENGTH]) + int(restored[Attribute.VITALITY])
	var restored_total_points := total + remaining
	if snapshot.has("total_points"):
		restored_total_points = _parse_non_negative_int(snapshot.get("total_points"))
	if restored_total_points < 0 or restored_total_points > MAX_TOTAL_POINTS or total + remaining != restored_total_points:
		return false
	var confirmed: Variant = snapshot.get("confirmed", false)
	if typeof(confirmed) != TYPE_BOOL or (bool(confirmed) and remaining != 0):
		return false
	_values = restored
	_total_points = restored_total_points
	_points_remaining = remaining
	_confirmed = bool(confirmed)
	return true


func _is_valid_attribute(attribute: int) -> bool:
	return attribute >= Attribute.INTELLIGENCE and attribute <= Attribute.VITALITY


func _attribute_from_key(key: String) -> int:
	match key:
		"intelligence": return Attribute.INTELLIGENCE
		"strength": return Attribute.STRENGTH
		_: return Attribute.VITALITY


func _parse_non_negative_int(value: Variant) -> int:
	if typeof(value) == TYPE_INT:
		return int(value) if int(value) >= 0 else -1
	if typeof(value) == TYPE_FLOAT and is_finite(float(value)) and float(value) >= 0.0 and is_equal_approx(float(value), floor(float(value))):
		return int(value)
	return -1
