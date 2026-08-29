extends RefCounted
class_name DisasterSchedulerModel

## 灾难概率、类型抽取和同类冷却模型；随机源由调用方注入。

const SURVIVAL_TUNING_SCRIPT: Script = preload("res://scripts/data/survival_tuning.gd")

enum DisasterKind {
	RAINSTORM,
	HEATWAVE,
	DENSE_FOG,
	COLD_SNAP,
	MONSTER_SURGE,
	SPAWN_MIGRATION,
	FLASH_FLOOD,
	TOXIC_FOG_LOCKDOWN,
	SPECIAL_INVASION,
	HUNTER,
}

const NORMAL_KINDS: Array[int] = [
	DisasterKind.RAINSTORM,
	DisasterKind.HEATWAVE,
	DisasterKind.DENSE_FOG,
	DisasterKind.COLD_SNAP,
	DisasterKind.MONSTER_SURGE,
	DisasterKind.SPAWN_MIGRATION,
]
const HARD_KINDS: Array[int] = [
	DisasterKind.FLASH_FLOOD,
	DisasterKind.TOXIC_FOG_LOCKDOWN,
	DisasterKind.SPECIAL_INVASION,
	DisasterKind.HUNTER,
]
const DAY_NORMAL_KINDS: Array[int] = [
	DisasterKind.RAINSTORM,
	DisasterKind.HEATWAVE,
	DisasterKind.DENSE_FOG,
	DisasterKind.COLD_SNAP,
	DisasterKind.SPAWN_MIGRATION,
]
const NIGHT_NORMAL_KINDS: Array[int] = [
	DisasterKind.DENSE_FOG,
	DisasterKind.COLD_SNAP,
	DisasterKind.MONSTER_SURGE,
	DisasterKind.SPAWN_MIGRATION,
]

var _difficulty: int
var _check_accumulator: float = 0.0
var _miss_count: int = 0
var _event_serial: int = 0
var _last_trigger_time_by_kind: Dictionary = {}
var _last_trigger_serial_by_kind: Dictionary = {}


func _init(difficulty: int = SURVIVAL_TUNING_SCRIPT.Difficulty.NORMAL) -> void:
	_difficulty = SURVIVAL_TUNING_SCRIPT.normalize_difficulty(difficulty)


func should_check(delta: float) -> bool:
	if delta <= 0.0:
		return false
	_check_accumulator += delta
	if _check_accumulator < SURVIVAL_TUNING_SCRIPT.DISASTER_CHECK_INTERVAL_SECONDS:
		return false
	_check_accumulator -= SURVIVAL_TUNING_SCRIPT.DISASTER_CHECK_INTERVAL_SECONDS
	return true


func get_trigger_probability(elapsed_seconds: float) -> float:
	var safe_elapsed: float = maxf(elapsed_seconds, 0.0)
	var day_index: int = int(floor(safe_elapsed / SURVIVAL_TUNING_SCRIPT.CYCLE_DURATION_SECONDS)) + 1
	var overtime_stage: int = 0
	if safe_elapsed > SURVIVAL_TUNING_SCRIPT.NORMAL_STAY_DURATION_SECONDS:
		overtime_stage = int(floor(
			(safe_elapsed - SURVIVAL_TUNING_SCRIPT.NORMAL_STAY_DURATION_SECONDS) \
			/ SURVIVAL_TUNING_SCRIPT.OVERTIME_STAGE_SECONDS
		)) + 1
	var probability: float = SURVIVAL_TUNING_SCRIPT.disaster_base_probability(day_index) \
		* SURVIVAL_TUNING_SCRIPT.difficulty_disaster_multiplier(_difficulty) \
		+ float(_miss_count) * SURVIVAL_TUNING_SCRIPT.DISASTER_MISS_BONUS \
		+ SURVIVAL_TUNING_SCRIPT.overtime_probability_bonus(overtime_stage)
	return clampf(probability, 0.0, SURVIVAL_TUNING_SCRIPT.DISASTER_PROBABILITY_MAX)


func roll_trigger(rng: RandomNumberGenerator, elapsed_seconds: float, active_count: int) -> bool:
	if rng == null or active_count < 0 or _are_slots_full(active_count):
		return false
	if rng.randf() < get_trigger_probability(elapsed_seconds):
		return true
	register_miss()
	return false


func roll_disaster_kind(rng: RandomNumberGenerator, elapsed_seconds: float, is_night: bool) -> int:
	if rng == null:
		return -1
	var hard_weight: float = SURVIVAL_TUNING_SCRIPT.hard_disaster_weight(_difficulty, maxf(elapsed_seconds, 0.0))
	if hard_weight > 0.0 and rng.randf() < hard_weight:
		return HARD_KINDS[rng.randi_range(0, HARD_KINDS.size() - 1)]
	var preferred_kinds: Array[int] = NIGHT_NORMAL_KINDS if is_night else DAY_NORMAL_KINDS
	return preferred_kinds[rng.randi_range(0, preferred_kinds.size() - 1)]


func register_miss() -> void:
	_miss_count += 1


func register_trigger(kind: int, elapsed_seconds: float) -> bool:
	if not _is_valid_kind(kind) or not can_trigger_kind(kind, elapsed_seconds):
		return false
	_event_serial += 1
	_last_trigger_time_by_kind[kind] = maxf(elapsed_seconds, 0.0)
	_last_trigger_serial_by_kind[kind] = _event_serial
	_miss_count = 0
	return true


func can_trigger_kind(kind: int, elapsed_seconds: float) -> bool:
	if not _is_valid_kind(kind):
		return false
	if not _last_trigger_time_by_kind.has(kind):
		return true
	var elapsed_since_same: float = maxf(elapsed_seconds, 0.0) - float(_last_trigger_time_by_kind[kind])
	var other_event_count: int = _event_serial - int(_last_trigger_serial_by_kind[kind])
	return elapsed_since_same >= SURVIVAL_TUNING_SCRIPT.SAME_DISASTER_COOLDOWN_SECONDS \
		and other_event_count >= SURVIVAL_TUNING_SCRIPT.SAME_DISASTER_OTHER_EVENT_COUNT


func _are_slots_full(active_count: int) -> bool:
	var slot_limit: int = SURVIVAL_TUNING_SCRIPT.disaster_slot_limit(_difficulty)
	return slot_limit >= 0 and active_count >= slot_limit


func _is_valid_kind(kind: int) -> bool:
	return kind >= DisasterKind.RAINSTORM and kind <= DisasterKind.HUNTER


func create_snapshot() -> Dictionary:
	return {
		"difficulty": _difficulty,
		"check_accumulator": _check_accumulator,
		"miss_count": _miss_count,
		"event_serial": _event_serial,
		"last_trigger_time_by_kind": _last_trigger_time_by_kind.duplicate(true),
		"last_trigger_serial_by_kind": _last_trigger_serial_by_kind.duplicate(true),
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["difficulty", "check_accumulator", "miss_count", "event_serial", "last_trigger_time_by_kind", "last_trigger_serial_by_kind"]:
		if not snapshot.has(key):
			return false
	var difficulty: int = int(snapshot["difficulty"])
	if difficulty < 0 or difficulty > 2 or float(snapshot["check_accumulator"]) < 0.0 or int(snapshot["miss_count"]) < 0 or int(snapshot["event_serial"]) < 0:
		return false
	_difficulty = difficulty
	_check_accumulator = float(snapshot["check_accumulator"])
	_miss_count = int(snapshot["miss_count"])
	_event_serial = int(snapshot["event_serial"])
	_last_trigger_time_by_kind = (snapshot["last_trigger_time_by_kind"] as Dictionary).duplicate(true)
	_last_trigger_serial_by_kind = (snapshot["last_trigger_serial_by_kind"] as Dictionary).duplicate(true)
	return true
