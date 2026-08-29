extends RefCounted
class_name ThreatBudgetModel

## 迷雾敌人的运行时威胁预算；任务守卫和 Boss 使用独立预算。

const MIN_SPAWN_COST: int = 1
const MAX_SPAWN_COST: int = 8
const BASE_BUDGET_DAY_ONE: int = 12
const BASE_BUDGET_DAY_TWO: int = 15
const BASE_BUDGET_DAY_THREE: int = 18

var _day_index: int = 1
var _overtime_stage: int = 0
var _disaster_bonus_ratio: float = 0.0
var _used_budget: int = 0


func _init(day_index: int = 1, overtime_stage: int = 0) -> void:
	set_time_context(day_index, overtime_stage)


func set_time_context(day_index: int, overtime_stage: int) -> bool:
	var normalized_day: int = maxi(day_index, 1)
	var normalized_overtime: int = maxi(overtime_stage, 0)
	var changed: bool = normalized_day != _day_index or normalized_overtime != _overtime_stage
	_day_index = normalized_day
	_overtime_stage = normalized_overtime
	return changed


func set_disaster_bonus_ratio(disaster_bonus_ratio: float) -> bool:
	var normalized_ratio: float = maxf(disaster_bonus_ratio, 0.0)
	if is_equal_approx(normalized_ratio, _disaster_bonus_ratio):
		return false
	_disaster_bonus_ratio = normalized_ratio
	return true


func get_base_budget(day_index: int, overtime_stage: int) -> int:
	var safe_day: int = maxi(day_index, 1)
	var budget: int
	if safe_day == 1:
		budget = BASE_BUDGET_DAY_ONE
	elif safe_day == 2:
		budget = BASE_BUDGET_DAY_TWO
	else:
		budget = BASE_BUDGET_DAY_THREE
	var safe_overtime: int = maxi(overtime_stage, 0)
	for stage in range(1, safe_overtime + 1):
		budget += maxi(4 - stage, 1)
	return budget



func get_active_budget(disaster_bonus_ratio: float = 0.0) -> int:
	var ratio: float = maxf(disaster_bonus_ratio, _disaster_bonus_ratio)
	return maxi(roundi(float(get_base_budget(_day_index, _overtime_stage)) * (1.0 + ratio)), 0)


func can_spawn(cost: int, used_budget: int) -> bool:
	if cost < MIN_SPAWN_COST or cost > MAX_SPAWN_COST or used_budget < 0:
		return false
	return used_budget + cost <= get_active_budget()


func register_spawn(cost: int) -> bool:
	if not can_spawn(cost, _used_budget):
		return false
	_used_budget += cost
	return true


func release_spawn(cost: int) -> bool:
	if cost < MIN_SPAWN_COST or cost > _used_budget:
		return false
	_used_budget -= cost
	return true


func get_used_budget() -> int:
	return _used_budget


func create_snapshot() -> Dictionary:
	return {
		"day_index": _day_index,
		"overtime_stage": _overtime_stage,
		"disaster_bonus_ratio": _disaster_bonus_ratio,
		"used_budget": _used_budget,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["day_index", "overtime_stage", "disaster_bonus_ratio", "used_budget"]:
		if not snapshot.has(key):
			return false
	var used: int = int(snapshot["used_budget"])
	if used < 0:
		return false
	set_time_context(int(snapshot["day_index"]), int(snapshot["overtime_stage"]))
	_disaster_bonus_ratio = maxf(float(snapshot["disaster_bonus_ratio"]), 0.0)
	_used_budget = used
	return true
