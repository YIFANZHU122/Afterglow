extends RefCounted
class_name SurvivalVitalsModel

## 饥饿、水分和归零环境伤害模型，不依赖玩家节点或 HUD。

const SURVIVAL_TUNING_SCRIPT: Script = preload("res://scripts/data/survival_tuning.gd")

var _hunger: float
var _water: float
var _zero_state_seconds: float = 0.0


func _init(
	initial_hunger: float = SURVIVAL_TUNING_SCRIPT.INITIAL_HUNGER,
	initial_water: float = SURVIVAL_TUNING_SCRIPT.INITIAL_WATER
) -> void:
	_hunger = clampf(initial_hunger, 0.0, SURVIVAL_TUNING_SCRIPT.STATE_MAX)
	_water = clampf(initial_water, 0.0, SURVIVAL_TUNING_SCRIPT.STATE_MAX)


func tick(delta: float, consumption_multiplier: float = 1.0) -> float:
	if delta <= 0.0:
		return 0.0
	var safe_multiplier: float = maxf(consumption_multiplier, 0.0)
	var zero_duration: float = _get_zero_duration(delta, safe_multiplier)
	_hunger = maxf(
		_hunger - delta * safe_multiplier / SURVIVAL_TUNING_SCRIPT.HUNGER_SECONDS_PER_POINT,
		0.0
	)
	_water = maxf(
		_water - delta * safe_multiplier / SURVIVAL_TUNING_SCRIPT.WATER_SECONDS_PER_POINT,
		0.0
	)
	if _hunger > 0.0 and _water > 0.0:
		_zero_state_seconds = 0.0
		return 0.0
	var previous_zero_seconds: float = _zero_state_seconds
	_zero_state_seconds += zero_duration
	var damaging_seconds: float = maxf(
		_zero_state_seconds - maxf(previous_zero_seconds, SURVIVAL_TUNING_SCRIPT.ZERO_WARNING_SECONDS),
		0.0
	)
	return damaging_seconds * SURVIVAL_TUNING_SCRIPT.ENVIRONMENT_DAMAGE_RATIO_PER_SECOND


func consume_food(amount: float) -> bool:
	if amount <= 0.0:
		return false
	_hunger = minf(_hunger + amount, SURVIVAL_TUNING_SCRIPT.STATE_MAX)
	_clear_zero_timer_if_recovered()
	return true


func consume_water(amount: float) -> bool:
	if amount <= 0.0:
		return false
	_water = minf(_water + amount, SURVIVAL_TUNING_SCRIPT.STATE_MAX)
	_clear_zero_timer_if_recovered()
	return true


func get_hunger() -> float:
	return _hunger


func get_water() -> float:
	return _water


func create_snapshot() -> Dictionary:
	return {"hunger": _hunger, "water": _water, "zero_state_seconds": _zero_state_seconds}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if not snapshot.has("hunger") or not snapshot.has("water") or not snapshot.has("zero_state_seconds"):
		return false
	var hunger: float = float(snapshot["hunger"])
	var water: float = float(snapshot["water"])
	var zero_seconds: float = float(snapshot["zero_state_seconds"])
	if hunger < 0.0 or hunger > SURVIVAL_TUNING_SCRIPT.STATE_MAX or water < 0.0 or water > SURVIVAL_TUNING_SCRIPT.STATE_MAX or zero_seconds < 0.0:
		return false
	_hunger = hunger
	_water = water
	_zero_state_seconds = zero_seconds
	return true


func is_critical() -> bool:
	return _hunger < SURVIVAL_TUNING_SCRIPT.CRITICAL_THRESHOLD \
		or _water < SURVIVAL_TUNING_SCRIPT.CRITICAL_THRESHOLD


func get_stamina_recovery_multiplier() -> float:
	if _hunger < SURVIVAL_TUNING_SCRIPT.CRITICAL_THRESHOLD:
		return SURVIVAL_TUNING_SCRIPT.CRITICAL_HUNGER_STAMINA_REGEN_MULTIPLIER
	if _hunger < SURVIVAL_TUNING_SCRIPT.LOW_THRESHOLD:
		return SURVIVAL_TUNING_SCRIPT.LOW_HUNGER_STAMINA_REGEN_MULTIPLIER
	return 1.0


func get_healing_multiplier() -> float:
	if _hunger < SURVIVAL_TUNING_SCRIPT.CRITICAL_THRESHOLD:
		return SURVIVAL_TUNING_SCRIPT.CRITICAL_HUNGER_HEALING_MULTIPLIER
	if _hunger < SURVIVAL_TUNING_SCRIPT.LOW_THRESHOLD:
		return SURVIVAL_TUNING_SCRIPT.LOW_HUNGER_HEALING_MULTIPLIER
	return 1.0


func get_stamina_cost_multiplier() -> float:
	if _water < SURVIVAL_TUNING_SCRIPT.CRITICAL_THRESHOLD:
		return SURVIVAL_TUNING_SCRIPT.CRITICAL_WATER_STAMINA_COST_MULTIPLIER
	if _water < SURVIVAL_TUNING_SCRIPT.LOW_THRESHOLD:
		return SURVIVAL_TUNING_SCRIPT.LOW_WATER_STAMINA_COST_MULTIPLIER
	return 1.0


func get_move_speed_multiplier() -> float:
	if _water < SURVIVAL_TUNING_SCRIPT.CRITICAL_THRESHOLD:
		return SURVIVAL_TUNING_SCRIPT.CRITICAL_WATER_MOVE_SPEED_MULTIPLIER
	if _water < SURVIVAL_TUNING_SCRIPT.LOW_THRESHOLD:
		return SURVIVAL_TUNING_SCRIPT.LOW_WATER_MOVE_SPEED_MULTIPLIER
	return 1.0


func _clear_zero_timer_if_recovered() -> void:
	if _hunger > 0.0 and _water > 0.0:
		_zero_state_seconds = 0.0


func _get_zero_duration(delta: float, consumption_multiplier: float) -> float:
	if _hunger <= 0.0 or _water <= 0.0:
		return delta
	if consumption_multiplier <= 0.0:
		return 0.0
	var hunger_seconds_until_zero: float = _hunger \
		* SURVIVAL_TUNING_SCRIPT.HUNGER_SECONDS_PER_POINT / consumption_multiplier
	var water_seconds_until_zero: float = _water \
		* SURVIVAL_TUNING_SCRIPT.WATER_SECONDS_PER_POINT / consumption_multiplier
	var first_zero_time: float = minf(hunger_seconds_until_zero, water_seconds_until_zero)
	return maxf(delta - first_zero_time, 0.0)
