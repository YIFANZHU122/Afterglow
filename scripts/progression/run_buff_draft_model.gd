extends RefCounted
class_name RunBuffDraftModel

## 本局 Buff 候选和运行时叠加状态。

enum Quality { COMMON, RARE, EPIC, LEGENDARY }

const QUALITY_NAMES: PackedStringArray = ["普通", "稀有", "史诗", "传说"]
const QUALITY_MULTIPLIERS: PackedFloat32Array = [1.0, 1.3, 1.7, 2.3]
const LUCK_BUFF_ID: StringName = &"luck"

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _luck: float = 0.0
var _reroll_charges: int = 0
var _stacks: Dictionary = {}


func _init(seed_value: int = 0) -> void:
	_rng.seed = seed_value if seed_value != 0 else Time.get_ticks_usec()


func get_luck() -> float:
	return _luck


func add_luck(amount: float) -> bool:
	if not is_finite(amount) or amount <= 0.0:
		return false
	_luck += amount
	return true


func add_reroll_charges(amount: int) -> bool:
	if amount <= 0:
		return false
	_reroll_charges += amount
	return true


func get_reroll_charges() -> int:
	return _reroll_charges


func consume_reroll() -> bool:
	if _reroll_charges <= 0:
		return false
	_reroll_charges -= 1
	return true


func get_buff_stack(buff_id: StringName) -> int:
	return int(_stacks.get(buff_id, 0))


func apply_candidate(buff_id: StringName, luck_amount: float = 0.1) -> bool:
	if buff_id.is_empty() or not is_finite(luck_amount) or luck_amount < 0.0:
		return false
	_stacks[buff_id] = get_buff_stack(buff_id) + 1
	if buff_id == LUCK_BUFF_ID:
		_luck += maxf(luck_amount, 0.0)
	return true


func generate_candidates(buff_ids: Array, count: int = 4) -> Array[Dictionary]:
	var pool: Array[StringName] = []
	for raw_buff_id: Variant in buff_ids:
		var buff_id := StringName(raw_buff_id)
		if not buff_id.is_empty() and not pool.has(buff_id):
			pool.append(buff_id)
	var candidates: Array[Dictionary] = []
	while not pool.is_empty() and candidates.size() < maxi(count, 0):
		var index := _rng.randi_range(0, pool.size() - 1)
		var buff_id: StringName = pool[index]
		pool.remove_at(index)
		var quality := _roll_quality()
		candidates.append({
			"id": buff_id,
			"quality": quality,
			"quality_name": QUALITY_NAMES[quality],
			"stack": get_buff_stack(buff_id),
			"multiplier": QUALITY_MULTIPLIERS[quality],
		})
	return candidates


func _roll_quality() -> int:
	var rare_weight := 0.20 + _luck * 0.10
	var epic_weight := 0.06 + _luck * 0.05
	var legendary_weight := 0.01 + _luck * 0.02
	var roll := _rng.randf()
	if roll < legendary_weight:
		return Quality.LEGENDARY
	if roll < legendary_weight + epic_weight:
		return Quality.EPIC
	if roll < legendary_weight + epic_weight + rare_weight:
		return Quality.RARE
	return Quality.COMMON


func create_snapshot() -> Dictionary:
	return {
		"luck": _luck,
		"reroll_charges": _reroll_charges,
		"stacks": _stacks.duplicate(true),
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if snapshot.is_empty():
		return false
	var restored_luck := _parse_non_negative_float(snapshot.get("luck", 0.0))
	if restored_luck < 0.0:
		return false
	var restored_reroll_charges := _parse_non_negative_int(snapshot.get("reroll_charges", 0))
	if restored_reroll_charges < 0:
		return false
	var raw_stacks: Variant = snapshot.get("stacks", {})
	if not raw_stacks is Dictionary:
		return false
	var restored_stacks: Dictionary = {}
	for raw_id: Variant in (raw_stacks as Dictionary).keys():
		if not _is_string_like(raw_id):
			return false
		var stack := _parse_non_negative_int((raw_stacks as Dictionary)[raw_id])
		if stack < 0:
			return false
		if stack > 0:
			var buff_id := StringName(raw_id)
			if buff_id.is_empty():
				return false
			restored_stacks[buff_id] = stack
	_luck = restored_luck
	_reroll_charges = restored_reroll_charges
	_stacks = restored_stacks
	return true


func reset() -> bool:
	var changed := _luck != 0.0 or _reroll_charges != 0 or not _stacks.is_empty()
	_luck = 0.0
	_reroll_charges = 0
	_stacks.clear()
	return changed


func _is_string_like(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME


func _parse_non_negative_float(value: Variant) -> float:
	var value_type := typeof(value)
	if value_type != TYPE_INT and value_type != TYPE_FLOAT:
		return -1.0
	var numeric := float(value)
	return numeric if is_finite(numeric) and numeric >= 0.0 else -1.0


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
