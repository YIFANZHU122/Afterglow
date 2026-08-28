extends RefCounted
class_name RunBuildModel

## 本局强化运行时状态，不依赖场景、节点树或 UI。

const BASE_MULTIPLIER: float = 1.0
const UPGRADE_DEFINITION_SCRIPT: Script = preload("res://scripts/data/upgrade_definition.gd")

var _damage_multiplier: float = BASE_MULTIPLIER
var _move_speed_multiplier: float = BASE_MULTIPLIER
var _max_health_multiplier: float = BASE_MULTIPLIER
var _damage_reduction: float = 0.0
var _max_stamina_multiplier: float = BASE_MULTIPLIER
var _stamina_regen_multiplier: float = BASE_MULTIPLIER
var _xp_multiplier: float = BASE_MULTIPLIER
var _luck: float = 0.0
var _survival_consumption_multiplier: float = BASE_MULTIPLIER
var _upgrade_stacks: Dictionary = {}
var _upgrade_qualities: Dictionary = {}


func apply_upgrade(definition: Resource) -> bool:
	if definition == null or definition.get_script() != UPGRADE_DEFINITION_SCRIPT \
		or not bool(definition.call("is_valid")):
		return false
	var upgrade_id: StringName = StringName(definition.get("id"))
	var effect_type: int = int(definition.get("effect_type"))
	var quality_multiplier := float(definition.get("quality_multiplier")) if definition.get("quality_multiplier") != null else 1.0
	var amount: float = float(definition.get("amount")) * maxf(quality_multiplier, 0.0)
	var quality: int = clampi(int(definition.get("quality")), 0, 3)
	_upgrade_stacks[upgrade_id] = int(_upgrade_stacks.get(upgrade_id, 0)) + 1
	_upgrade_qualities[upgrade_id] = maxi(int(_upgrade_qualities.get(upgrade_id, 0)), quality)
	match effect_type:
		UPGRADE_DEFINITION_SCRIPT.EffectType.DAMAGE_MULTIPLIER:
			_damage_multiplier += amount
		UPGRADE_DEFINITION_SCRIPT.EffectType.MOVE_SPEED_MULTIPLIER:
			_move_speed_multiplier += amount
		UPGRADE_DEFINITION_SCRIPT.EffectType.MAX_HEALTH_MULTIPLIER:
			_max_health_multiplier += amount
		UPGRADE_DEFINITION_SCRIPT.EffectType.DAMAGE_REDUCTION:
			_damage_reduction = minf(_damage_reduction + amount, 0.75)
		UPGRADE_DEFINITION_SCRIPT.EffectType.MAX_STAMINA_MULTIPLIER:
			_max_stamina_multiplier += amount
		UPGRADE_DEFINITION_SCRIPT.EffectType.STAMINA_REGEN_MULTIPLIER:
			_stamina_regen_multiplier += amount
		UPGRADE_DEFINITION_SCRIPT.EffectType.XP_MULTIPLIER:
			_xp_multiplier += amount
		UPGRADE_DEFINITION_SCRIPT.EffectType.LUCK:
			_luck += amount
		UPGRADE_DEFINITION_SCRIPT.EffectType.SURVIVAL_CONSUMPTION_MULTIPLIER:
			_survival_consumption_multiplier = maxf(_survival_consumption_multiplier - amount, 0.5)
		_:
			_upgrade_stacks.erase(upgrade_id)
			_upgrade_qualities.erase(upgrade_id)
			return false
	return true


func apply_effect(effect_type: int, amount: float, upgrade_id: StringName, stacks: int = 1, quality: int = 0) -> bool:
	if upgrade_id.is_empty() or not is_finite(amount) or amount <= 0.0 or stacks <= 0 \
		or effect_type < UPGRADE_DEFINITION_SCRIPT.EffectType.DAMAGE_MULTIPLIER \
		or effect_type > UPGRADE_DEFINITION_SCRIPT.EffectType.SURVIVAL_CONSUMPTION_MULTIPLIER:
		return false
	var accepted := true
	for _index: int in range(stacks):
		match effect_type:
			UPGRADE_DEFINITION_SCRIPT.EffectType.DAMAGE_MULTIPLIER:
				_damage_multiplier += amount
			UPGRADE_DEFINITION_SCRIPT.EffectType.MOVE_SPEED_MULTIPLIER:
				_move_speed_multiplier += amount
			UPGRADE_DEFINITION_SCRIPT.EffectType.MAX_HEALTH_MULTIPLIER:
				_max_health_multiplier += amount
			UPGRADE_DEFINITION_SCRIPT.EffectType.DAMAGE_REDUCTION:
				_damage_reduction = minf(_damage_reduction + amount, 0.75)
			UPGRADE_DEFINITION_SCRIPT.EffectType.MAX_STAMINA_MULTIPLIER:
				_max_stamina_multiplier += amount
			UPGRADE_DEFINITION_SCRIPT.EffectType.STAMINA_REGEN_MULTIPLIER:
				_stamina_regen_multiplier += amount
			UPGRADE_DEFINITION_SCRIPT.EffectType.XP_MULTIPLIER:
				_xp_multiplier += amount
			UPGRADE_DEFINITION_SCRIPT.EffectType.LUCK:
				_luck += amount
			UPGRADE_DEFINITION_SCRIPT.EffectType.SURVIVAL_CONSUMPTION_MULTIPLIER:
				_survival_consumption_multiplier = maxf(_survival_consumption_multiplier - amount, 0.5)
			_:
				accepted = false
				break
		if accepted:
			_upgrade_stacks[upgrade_id] = get_upgrade_stack(upgrade_id) + 1
			_upgrade_qualities[upgrade_id] = maxi(int(_upgrade_qualities.get(upgrade_id, 0)), clampi(quality, 0, 3))
	if not accepted:
		return false
	return true


func get_damage_multiplier() -> float:
	return _damage_multiplier


func get_move_speed_multiplier() -> float:
	return _move_speed_multiplier


func get_max_health_multiplier() -> float:
	return _max_health_multiplier


func get_damage_reduction() -> float:
	return _damage_reduction


func get_max_stamina_multiplier() -> float:
	return _max_stamina_multiplier


func get_stamina_regen_multiplier() -> float:
	return _stamina_regen_multiplier


func get_xp_multiplier() -> float:
	return _xp_multiplier


func get_luck() -> float:
	return _luck


func get_survival_consumption_multiplier() -> float:
	return _survival_consumption_multiplier


func get_upgrade_stack(upgrade_id: StringName) -> int:
	return int(_upgrade_stacks.get(upgrade_id, 0))


func get_upgrade_stacks() -> Dictionary:
	return _upgrade_stacks.duplicate(true)


func get_upgrade_quality(upgrade_id: StringName) -> int:
	return clampi(int(_upgrade_qualities.get(upgrade_id, 0)), 0, 3)


func get_buff_summary() -> Array[Dictionary]:
	var summary: Array[Dictionary] = []
	for raw_id: Variant in _upgrade_stacks.keys():
		var buff_id := StringName(raw_id)
		summary.append({
			"id": buff_id,
			"stack": get_upgrade_stack(buff_id),
			"quality": get_upgrade_quality(buff_id),
		})
	return summary


func reset() -> bool:
	var changed: bool = _damage_multiplier != BASE_MULTIPLIER \
		or _move_speed_multiplier != BASE_MULTIPLIER \
		or _max_health_multiplier != BASE_MULTIPLIER \
		or _damage_reduction != 0.0 \
		or _max_stamina_multiplier != BASE_MULTIPLIER \
		or _stamina_regen_multiplier != BASE_MULTIPLIER \
		or _xp_multiplier != BASE_MULTIPLIER \
		or _luck != 0.0 \
		or _survival_consumption_multiplier != BASE_MULTIPLIER \
		or not _upgrade_stacks.is_empty() \
		or not _upgrade_qualities.is_empty()
	_damage_multiplier = BASE_MULTIPLIER
	_move_speed_multiplier = BASE_MULTIPLIER
	_max_health_multiplier = BASE_MULTIPLIER
	_damage_reduction = 0.0
	_max_stamina_multiplier = BASE_MULTIPLIER
	_stamina_regen_multiplier = BASE_MULTIPLIER
	_xp_multiplier = BASE_MULTIPLIER
	_luck = 0.0
	_survival_consumption_multiplier = BASE_MULTIPLIER
	_upgrade_stacks.clear()
	_upgrade_qualities.clear()
	return changed


func create_snapshot() -> Dictionary:
	return {
		"damage_multiplier": _damage_multiplier,
		"move_speed_multiplier": _move_speed_multiplier,
		"max_health_multiplier": _max_health_multiplier,
		"damage_reduction": _damage_reduction,
		"max_stamina_multiplier": _max_stamina_multiplier,
		"stamina_regen_multiplier": _stamina_regen_multiplier,
		"xp_multiplier": _xp_multiplier,
		"luck": _luck,
		"survival_consumption_multiplier": _survival_consumption_multiplier,
		"upgrade_stacks": _upgrade_stacks.duplicate(true),
		"upgrade_qualities": _upgrade_qualities.duplicate(true),
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if not snapshot.has("damage_multiplier") or not snapshot.has("move_speed_multiplier") or not snapshot.has("upgrade_stacks"):
		return false
	var damage := _parse_finite_number(snapshot["damage_multiplier"])
	var speed := _parse_finite_number(snapshot["move_speed_multiplier"])
	if not is_finite(damage) or not is_finite(speed) or damage < BASE_MULTIPLIER or speed < BASE_MULTIPLIER:
		return false
	if not snapshot["upgrade_stacks"] is Dictionary:
		return false
	var stacks: Dictionary = snapshot["upgrade_stacks"] as Dictionary
	var restored_stacks: Dictionary = {}
	for raw_id: Variant in stacks.keys():
		if not _is_string_like(raw_id):
			return false
		var stack := _parse_non_negative_int(stacks[raw_id])
		if stack <= 0:
			return false
		var buff_id := StringName(raw_id)
		if buff_id.is_empty():
			return false
		restored_stacks[buff_id] = stack
	var max_health := _parse_finite_number(snapshot.get("max_health_multiplier", BASE_MULTIPLIER))
	var damage_reduction := _parse_finite_number(snapshot.get("damage_reduction", 0.0))
	var max_stamina := _parse_finite_number(snapshot.get("max_stamina_multiplier", BASE_MULTIPLIER))
	var stamina_regen := _parse_finite_number(snapshot.get("stamina_regen_multiplier", BASE_MULTIPLIER))
	var xp := _parse_finite_number(snapshot.get("xp_multiplier", BASE_MULTIPLIER))
	var luck := _parse_finite_number(snapshot.get("luck", 0.0))
	var survival_consumption := _parse_finite_number(snapshot.get("survival_consumption_multiplier", BASE_MULTIPLIER))
	if not is_finite(max_health) or max_health < BASE_MULTIPLIER \
		or not is_finite(damage_reduction) or damage_reduction < 0.0 or damage_reduction > 0.75 \
		or not is_finite(max_stamina) or max_stamina < BASE_MULTIPLIER \
		or not is_finite(stamina_regen) or stamina_regen < BASE_MULTIPLIER \
		or not is_finite(xp) or xp < BASE_MULTIPLIER \
		or not is_finite(luck) or luck < 0.0 \
		or not is_finite(survival_consumption) or survival_consumption < 0.5 or survival_consumption > BASE_MULTIPLIER:
		return false
	var restored_qualities: Dictionary = {}
	var raw_qualities: Variant = snapshot.get("upgrade_qualities", {})
	if not raw_qualities is Dictionary:
		return false
	for raw_id: Variant in (raw_qualities as Dictionary).keys():
		if not _is_string_like(raw_id):
			return false
		var quality := _parse_non_negative_int((raw_qualities as Dictionary)[raw_id])
		if quality < 0 or quality > 3:
			return false
		var buff_id := StringName(raw_id)
		if restored_stacks.has(buff_id):
			restored_qualities[buff_id] = quality
	_damage_multiplier = damage
	_move_speed_multiplier = speed
	_max_health_multiplier = max_health
	_damage_reduction = damage_reduction
	_max_stamina_multiplier = max_stamina
	_stamina_regen_multiplier = stamina_regen
	_xp_multiplier = xp
	_luck = luck
	_survival_consumption_multiplier = survival_consumption
	_upgrade_stacks = restored_stacks
	_upgrade_qualities = restored_qualities
	return true


func _is_string_like(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME


func _parse_finite_number(value: Variant) -> float:
	var value_type := typeof(value)
	if value_type != TYPE_INT and value_type != TYPE_FLOAT:
		return INF
	var numeric := float(value)
	return numeric if is_finite(numeric) else INF


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
