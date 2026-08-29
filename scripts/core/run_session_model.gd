extends RefCounted
class_name RunSessionModel

## 本局运行会话状态机，不依赖节点树、输入、UI 或全局服务。

const SURVIVAL_TUNING_SCRIPT: Script = preload("res://scripts/data/survival_tuning.gd")
const DEFAULT_TOTAL_FLOORS: int = 6

enum State {
	IDLE,
	PREPARING_FLOOR,
	EXPLORING,
	OBJECTIVE_COMPLETE,
	FLOOR_CLEAR,
	DEAD,
	RUN_ENDED,
	PAUSED,
	RUN_WON,
}

var _state: State = State.IDLE
var _floor_number: int = 0
var _state_before_death: State = State.EXPLORING
var _state_before_pause: State = State.EXPLORING
var _difficulty: int = SURVIVAL_TUNING_SCRIPT.Difficulty.NORMAL
var _difficulty_locked: bool = false
var _total_floors: int = DEFAULT_TOTAL_FLOORS


func configure_difficulty(difficulty: int) -> bool:
	if _state != State.IDLE or _difficulty_locked:
		return false
	_difficulty = SURVIVAL_TUNING_SCRIPT.normalize_difficulty(difficulty)
	return true


func start_run(difficulty: int = -1, total_floors: int = DEFAULT_TOTAL_FLOORS) -> bool:
	if _state != State.IDLE:
		return false
	if difficulty >= 0:
		_difficulty = SURVIVAL_TUNING_SCRIPT.normalize_difficulty(difficulty)
	_total_floors = maxi(total_floors, 1)
	_floor_number = 1
	_difficulty_locked = true
	_state = State.PREPARING_FLOOR
	return true


func prepare_floor() -> bool:
	if _state != State.PREPARING_FLOOR:
		return false
	_state = State.EXPLORING
	return true


func complete_objective() -> bool:
	if _state != State.EXPLORING:
		return false
	_state = State.OBJECTIVE_COMPLETE
	return true


func clear_floor() -> bool:
	if _state != State.OBJECTIVE_COMPLETE:
		return false
	_state = State.FLOOR_CLEAR
	return true


func start_next_floor() -> bool:
	if _state != State.FLOOR_CLEAR or is_final_floor():
		return false
	_floor_number += 1
	_state = State.PREPARING_FLOOR
	return true


func complete_run() -> bool:
	if _state != State.FLOOR_CLEAR or not is_final_floor():
		return false
	_state = State.RUN_WON
	return true


func mark_dead() -> bool:
	if _state == State.PAUSED or not is_run_active():
		return false
	_state_before_death = _state
	_state = State.DEAD
	return true


func revive() -> bool:
	if _state != State.DEAD:
		return false
	_state = _state_before_death
	return true


func end_run() -> bool:
	if _state != State.DEAD and _state != State.FLOOR_CLEAR:
		return false
	_state = State.RUN_ENDED
	return true


func pause() -> bool:
	if _state != State.PREPARING_FLOOR \
		and _state != State.EXPLORING \
		and _state != State.OBJECTIVE_COMPLETE \
		and _state != State.FLOOR_CLEAR:
		return false
	_state_before_pause = _state
	_state = State.PAUSED
	return true


func resume() -> bool:
	if _state != State.PAUSED:
		return false
	_state = _state_before_pause
	return true


func reset() -> bool:
	var changed: bool = _state != State.IDLE \
		or _floor_number != 0 \
		or _difficulty != SURVIVAL_TUNING_SCRIPT.Difficulty.NORMAL \
		or _difficulty_locked \
		or _total_floors != DEFAULT_TOTAL_FLOORS
	_state = State.IDLE
	_floor_number = 0
	_state_before_death = State.EXPLORING
	_state_before_pause = State.EXPLORING
	_difficulty = SURVIVAL_TUNING_SCRIPT.Difficulty.NORMAL
	_difficulty_locked = false
	_total_floors = DEFAULT_TOTAL_FLOORS
	return changed


func is_run_active() -> bool:
	return _state == State.PREPARING_FLOOR \
		or _state == State.EXPLORING \
		or _state == State.OBJECTIVE_COMPLETE \
		or _state == State.FLOOR_CLEAR \
		or _state == State.PAUSED


func is_paused() -> bool:
	return _state == State.PAUSED


func get_state() -> State:
	return _state


func get_floor_number() -> int:
	return _floor_number


func get_difficulty() -> int:
	return _difficulty


func is_difficulty_locked() -> bool:
	return _difficulty_locked


func get_total_floors() -> int:
	return _total_floors


func is_final_floor() -> bool:
	return _floor_number > 0 and _floor_number == _total_floors


func create_snapshot() -> Dictionary:
	return {
		"state": int(_state),
		"floor_number": _floor_number,
		"difficulty": _difficulty,
		"difficulty_locked": _difficulty_locked,
		"total_floors": _total_floors,
		"state_before_death": int(_state_before_death),
		"state_before_pause": int(_state_before_pause),
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	var required_keys: Array[String] = [
		"state",
		"floor_number",
		"difficulty",
		"difficulty_locked",
		"total_floors",
		"state_before_death",
		"state_before_pause",
	]
	for key: String in required_keys:
		if not snapshot.has(key):
			return false
	var restored_state: int = int(snapshot["state"])
	var restored_floor: int = int(snapshot["floor_number"])
	var restored_total_floors: int = int(snapshot["total_floors"])
	var restored_difficulty: int = int(snapshot["difficulty"])
	var restored_before_death: int = int(snapshot["state_before_death"])
	var restored_before_pause: int = int(snapshot["state_before_pause"])
	if not _is_valid_state(restored_state) \
		or not _is_valid_state(restored_before_death) \
		or not _is_valid_state(restored_before_pause):
		return false
	if restored_total_floors < 1 or restored_floor < 0 or restored_floor > restored_total_floors:
		return false
	if restored_state == State.IDLE and restored_floor != 0:
		return false
	if restored_state != State.IDLE and restored_floor == 0:
		return false
	if restored_difficulty < SURVIVAL_TUNING_SCRIPT.Difficulty.NORMAL \
		or restored_difficulty > SURVIVAL_TUNING_SCRIPT.Difficulty.HELL:
		return false
	var restored_difficulty_locked: bool = bool(snapshot["difficulty_locked"])
	if restored_state != State.IDLE and not restored_difficulty_locked:
		return false
	_state = restored_state as State
	_floor_number = restored_floor
	_difficulty = restored_difficulty
	_difficulty_locked = restored_difficulty_locked
	_total_floors = restored_total_floors
	_state_before_death = restored_before_death as State
	_state_before_pause = restored_before_pause as State
	return true


func _is_valid_state(value: int) -> bool:
	return value >= State.IDLE and value <= State.RUN_WON
