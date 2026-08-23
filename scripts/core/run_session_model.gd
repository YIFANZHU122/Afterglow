extends RefCounted
class_name RunSessionModel

## 本局运行会话状态机，不依赖节点树、输入、UI 或全局服务。

enum State {
	IDLE,
	PREPARING_FLOOR,
	EXPLORING,
	OBJECTIVE_COMPLETE,
	FLOOR_CLEAR,
	DEAD,
	RUN_ENDED,
}

var _state: State = State.IDLE
var _floor_number: int = 0
var _state_before_death: State = State.EXPLORING


func start_run() -> bool:
	if _state != State.IDLE:
		return false
	_floor_number = 1
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
	if _state != State.FLOOR_CLEAR:
		return false
	_floor_number += 1
	_state = State.PREPARING_FLOOR
	return true


func mark_dead() -> bool:
	if not is_run_active():
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


func reset() -> bool:
	var changed: bool = _state != State.IDLE or _floor_number != 0
	_state = State.IDLE
	_floor_number = 0
	_state_before_death = State.EXPLORING
	return changed


func is_run_active() -> bool:
	return _state == State.PREPARING_FLOOR \
		or _state == State.EXPLORING \
		or _state == State.OBJECTIVE_COMPLETE \
		or _state == State.FLOOR_CLEAR


func get_state() -> State:
	return _state


func get_floor_number() -> int:
	return _floor_number
