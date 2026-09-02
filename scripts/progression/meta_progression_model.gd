extends RefCounted
class_name MetaProgressionModel

## 跨运行保存的局外成长状态，不依赖场景或 UI。

const DEFAULT_INITIAL_BUFF_COST: int = 10
const MAX_REROLL_LEVEL: int = 5
const CANONICAL_MOVE_SPEED_ID: StringName = &"move_speed"
const LEGACY_MOVE_SPEED_ID: StringName = &"speed"
const ATTRIBUTE_POINTS_PER_TIER: int = 5
const CRYSTAL_TIER_THRESHOLDS: Array[int] = [0, 10, 30, 60, 100, 160]

var _crystals: int = 0
var _lifetime_crystals: int = 0
var _initial_buff_levels: Dictionary = {}
var _equipped_initial_buff: StringName = StringName()
var _reroll_level: int = 0


func add_crystals(amount: int) -> bool:
	if amount <= 0:
		return false
	_crystals += amount
	_lifetime_crystals += amount
	return true


func get_crystals() -> int:
	return _crystals


func get_meta_crystals() -> int:
	return _crystals


func get_lifetime_crystals() -> int:
	return _lifetime_crystals


func get_crystal_tier() -> int:
	for tier: int in range(CRYSTAL_TIER_THRESHOLDS.size() - 1, -1, -1):
		if _lifetime_crystals >= CRYSTAL_TIER_THRESHOLDS[tier]:
			return tier
	return 0


func get_attribute_point_bonus() -> int:
	return get_crystal_tier() * ATTRIBUTE_POINTS_PER_TIER


func purchase_initial_buff(buff_id: StringName, cost: int = DEFAULT_INITIAL_BUFF_COST) -> bool:
	var normalized_buff_id := _canonical_buff_id(buff_id)
	if normalized_buff_id.is_empty() or cost <= 0 or _crystals < cost:
		return false
	_crystals -= cost
	_initial_buff_levels[normalized_buff_id] = int(_initial_buff_levels.get(normalized_buff_id, 0)) + 1
	return true


func get_initial_buff_level(buff_id: StringName) -> int:
	return int(_initial_buff_levels.get(_canonical_buff_id(buff_id), 0))


func equip_initial_buff(buff_id: StringName) -> bool:
	var normalized_buff_id := _canonical_buff_id(buff_id)
	if normalized_buff_id.is_empty() or get_initial_buff_level(normalized_buff_id) <= 0:
		return false
	_equipped_initial_buff = normalized_buff_id
	return true


func get_equipped_initial_buff() -> StringName:
	return _equipped_initial_buff


func purchase_reroll_level(cost: int) -> bool:
	if cost <= 0 or _reroll_level >= MAX_REROLL_LEVEL or _crystals < cost:
		return false
	_crystals -= cost
	_reroll_level += 1
	return true


func get_reroll_level() -> int:
	return _reroll_level


func get_run_reroll_charges() -> int:
	return _reroll_level


func get_reroll_charges() -> int:
	return _reroll_level


func create_snapshot() -> Dictionary:
	return {
		"meta_crystals": _crystals,
		"lifetime_crystals": _lifetime_crystals,
		"initial_buff_levels": _initial_buff_levels.duplicate(true),
		"equipped_initial_buff": String(_equipped_initial_buff),
		"reroll_level": _reroll_level,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if snapshot.is_empty():
		return false
	var restored_crystals := _parse_non_negative_int(snapshot.get("meta_crystals", 0))
	if restored_crystals < 0:
		return false
	var restored_lifetime := restored_crystals
	if snapshot.has("lifetime_crystals"):
		restored_lifetime = _parse_non_negative_int(snapshot.get("lifetime_crystals"))
	if restored_lifetime < restored_crystals:
		return false
	var raw_levels: Variant = snapshot.get("initial_buff_levels", {})
	if not raw_levels is Dictionary:
		return false
	var restored_levels: Dictionary = {}
	for raw_id: Variant in (raw_levels as Dictionary).keys():
		if not _is_string_like(raw_id):
			return false
		var level := _parse_non_negative_int((raw_levels as Dictionary)[raw_id])
		if level < 0:
			return false
		if level > 0:
			var buff_id := _canonical_buff_id(StringName(raw_id))
			if buff_id.is_empty():
				return false
			restored_levels[buff_id] = maxi(int(restored_levels.get(buff_id, 0)), level)
	var raw_equipped: Variant = snapshot.get("equipped_initial_buff", "")
	if not _is_string_like(raw_equipped):
		return false
	var restored_equipped := _canonical_buff_id(StringName(raw_equipped))
	if not restored_equipped.is_empty() and int(restored_levels.get(restored_equipped, 0)) <= 0:
		restored_equipped = StringName()
	var restored_reroll_level := _parse_non_negative_int(snapshot.get("reroll_level", 0))
	if restored_reroll_level < 0:
		return false
	_crystals = restored_crystals
	_lifetime_crystals = restored_lifetime
	_initial_buff_levels = restored_levels
	_equipped_initial_buff = restored_equipped
	_reroll_level = clampi(restored_reroll_level, 0, MAX_REROLL_LEVEL)
	return true


func reset() -> bool:
	var changed := _crystals != 0 or _lifetime_crystals != 0 or not _initial_buff_levels.is_empty() \
		or not _equipped_initial_buff.is_empty() or _reroll_level != 0
	_crystals = 0
	_lifetime_crystals = 0
	_initial_buff_levels.clear()
	_equipped_initial_buff = StringName()
	_reroll_level = 0
	return changed


func _canonical_buff_id(buff_id: StringName) -> StringName:
	return CANONICAL_MOVE_SPEED_ID if buff_id == LEGACY_MOVE_SPEED_ID else buff_id


func _is_string_like(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME


func _parse_non_negative_int(value: Variant) -> int:
	var value_type := typeof(value)
	if value_type == TYPE_INT:
		return int(value) if int(value) >= 0 else -1
	if value_type == TYPE_FLOAT:
		var numeric := float(value)
		if not is_finite(numeric) or numeric < 0.0 or not is_equal_approx(numeric, floor(numeric)):
			return -1
		return int(numeric)
	return -1
