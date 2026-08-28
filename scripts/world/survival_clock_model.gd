extends RefCounted
class_name SurvivalClockModel

## 昼夜、驻留时长和超时阶段模型，不依赖 Timer 或场景树。

const SURVIVAL_TUNING_SCRIPT: Script = preload("res://scripts/data/survival_tuning.gd")

var _elapsed_seconds: float = 0.0


func advance(delta: float) -> bool:
	if delta <= 0.0:
		return false
	_elapsed_seconds += delta
	return true


func get_elapsed_seconds() -> float:
	return _elapsed_seconds


func get_day_index() -> int:
	return int(floor(_elapsed_seconds / SURVIVAL_TUNING_SCRIPT.CYCLE_DURATION_SECONDS)) + 1


func is_night() -> bool:
	var cycle_seconds: float = fmod(_elapsed_seconds, SURVIVAL_TUNING_SCRIPT.CYCLE_DURATION_SECONDS)
	return cycle_seconds >= SURVIVAL_TUNING_SCRIPT.DAY_DURATION_SECONDS


func get_overtime_stage() -> int:
	if _elapsed_seconds <= SURVIVAL_TUNING_SCRIPT.NORMAL_STAY_DURATION_SECONDS:
		return 0
	return int(floor(
		(_elapsed_seconds - SURVIVAL_TUNING_SCRIPT.NORMAL_STAY_DURATION_SECONDS) \
		/ SURVIVAL_TUNING_SCRIPT.OVERTIME_STAGE_SECONDS
	)) + 1


func get_overtime_probability_bonus() -> float:
	return SURVIVAL_TUNING_SCRIPT.overtime_probability_bonus(get_overtime_stage())


func create_snapshot() -> Dictionary:
	return {"elapsed_seconds": _elapsed_seconds}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if not snapshot.has("elapsed_seconds"):
		return false
	var elapsed: float = float(snapshot["elapsed_seconds"])
	if elapsed < 0.0:
		return false
	_elapsed_seconds = elapsed
	return true
