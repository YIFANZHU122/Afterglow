extends RefCounted
class_name DisasterEventModel

## 单个灾难实例的预警、生效和主应对状态；并发由上层管理。

const DISASTER_SCHEDULER_MODEL_SCRIPT: Script = preload("res://scripts/world/disaster_scheduler_model.gd")

enum Phase {
	IDLE,
	WARNING,
	ACTIVE,
	RESOLVED,
	FAILED,
}

const WARNING_SECONDS: float = 10.0
const NORMAL_DURATION_MIN_SECONDS: float = 120.0
const NORMAL_DURATION_MAX_SECONDS: float = 240.0
const HARD_DURATION_MIN_SECONDS: float = 240.0
const HARD_DURATION_MAX_SECONDS: float = 360.0
const HARD_COUNTERMEASURE_REQUIRED: float = 10.0

var _kind: int = -1
var _phase: Phase = Phase.IDLE
var _remaining_seconds: float = 0.0
var _duration_seconds: float = 0.0
var _countermeasure_progress: float = 0.0
var _countermeasure_interrupted: bool = false


func start_warning(kind: int, elapsed_seconds: float) -> bool:
	if _phase != Phase.IDLE or not _is_valid_kind(kind):
		return false
	_kind = kind
	_phase = Phase.WARNING
	_remaining_seconds = WARNING_SECONDS
	_duration_seconds = _get_duration(kind, elapsed_seconds)
	_countermeasure_progress = 0.0
	_countermeasure_interrupted = false
	return true


func advance(delta: float, countermeasure_progress: float = 0.0) -> bool:
	if delta <= 0.0 or _phase == Phase.IDLE or _phase == Phase.RESOLVED or _phase == Phase.FAILED:
		return false
	if _phase == Phase.WARNING:
		_remaining_seconds -= delta
		if _remaining_seconds > 0.0:
			return false
		var active_delta: float = maxf(-_remaining_seconds, 0.0)
		_phase = Phase.ACTIVE
		_remaining_seconds = maxf(_duration_seconds - active_delta, 0.0)
		if _remaining_seconds <= 0.0:
			_phase = Phase.FAILED if _is_hard_disaster() else Phase.RESOLVED
		return true
	if _is_hard_disaster() and countermeasure_progress > 0.0:
		advance_countermeasure(countermeasure_progress)
		if is_resolved():
			return true
	_remaining_seconds = maxf(_remaining_seconds - delta, 0.0)
	if _remaining_seconds <= 0.0:
		_phase = Phase.FAILED if _is_hard_disaster() else Phase.RESOLVED
		return true
	return false


func advance_countermeasure(progress_delta: float) -> bool:
	if _phase != Phase.ACTIVE or not _is_hard_disaster() or progress_delta <= 0.0:
		return false
	_countermeasure_interrupted = false
	_countermeasure_progress = minf(
		_countermeasure_progress + progress_delta,
		HARD_COUNTERMEASURE_REQUIRED
	)
	if _countermeasure_progress >= HARD_COUNTERMEASURE_REQUIRED:
		_phase = Phase.RESOLVED
		_remaining_seconds = 0.0
	return true


func interrupt_countermeasure() -> bool:
	if _phase != Phase.ACTIVE or not _is_hard_disaster():
		return false
	_countermeasure_interrupted = true
	return true


func complete_countermeasure() -> bool:
	if _phase != Phase.ACTIVE or not _is_hard_disaster():
		return false
	if _countermeasure_progress < HARD_COUNTERMEASURE_REQUIRED:
		return false
	_phase = Phase.RESOLVED
	_remaining_seconds = 0.0
	return true


func get_phase() -> Phase:
	return _phase


func get_kind() -> int:
	return _kind


func get_remaining_seconds() -> float:
	return _remaining_seconds


func get_countermeasure_progress() -> float:
	return _countermeasure_progress


func get_countermeasure_required() -> float:
	return HARD_COUNTERMEASURE_REQUIRED if _is_hard_disaster() else 0.0


func is_active() -> bool:
	return _phase == Phase.WARNING or _phase == Phase.ACTIVE


func is_resolved() -> bool:
	return _phase == Phase.RESOLVED


func has_failed() -> bool:
	return _phase == Phase.FAILED


func _is_hard_disaster() -> bool:
	return _kind >= DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.FLASH_FLOOD


func _is_valid_kind(kind: int) -> bool:
	return kind >= DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.RAINSTORM \
		and kind <= DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.HUNTER


func _get_duration(kind: int, elapsed_seconds: float) -> float:
	var safe_elapsed: float = maxf(elapsed_seconds, 0.0)
	if kind >= DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.FLASH_FLOOD:
		return HARD_DURATION_MIN_SECONDS + fmod(safe_elapsed, HARD_DURATION_MAX_SECONDS - HARD_DURATION_MIN_SECONDS + 1.0)
	return NORMAL_DURATION_MIN_SECONDS + fmod(safe_elapsed, NORMAL_DURATION_MAX_SECONDS - NORMAL_DURATION_MIN_SECONDS + 1.0)


func create_snapshot() -> Dictionary:
	return {
		"kind": _kind,
		"phase": int(_phase),
		"remaining_seconds": _remaining_seconds,
		"duration_seconds": _duration_seconds,
		"countermeasure_progress": _countermeasure_progress,
		"countermeasure_interrupted": _countermeasure_interrupted,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["kind", "phase", "remaining_seconds", "duration_seconds", "countermeasure_progress", "countermeasure_interrupted"]:
		if not snapshot.has(key):
			return false
	var kind: int = int(snapshot["kind"])
	var phase: int = int(snapshot["phase"])
	var remaining: float = float(snapshot["remaining_seconds"])
	var duration: float = float(snapshot["duration_seconds"])
	var progress: float = float(snapshot["countermeasure_progress"])
	if kind < -1 or kind > DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.HUNTER or phase < Phase.IDLE or phase > Phase.FAILED or remaining < 0.0 or duration < 0.0 or progress < 0.0 or progress > HARD_COUNTERMEASURE_REQUIRED:
		return false
	_kind = kind
	_phase = phase as Phase
	_remaining_seconds = remaining
	_duration_seconds = duration
	_countermeasure_progress = progress
	_countermeasure_interrupted = bool(snapshot["countermeasure_interrupted"])
	return true
