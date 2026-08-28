extends RefCounted
class_name ReviveModel

## 复活流程状态机，不依赖按钮、计时器或玩家节点。

enum State {
	ALIVE,
	DEAD,
	WAITING,
}

var _state: State = State.ALIVE


func mark_dead() -> bool:
	if _state != State.ALIVE:
		return false
	_state = State.DEAD
	return true


func request() -> bool:
	if _state != State.DEAD:
		return false
	_state = State.WAITING
	return true


func complete() -> bool:
	if _state != State.WAITING:
		return false
	_state = State.ALIVE
	return true


func is_alive() -> bool:
	return _state == State.ALIVE


func is_dead() -> bool:
	return _state != State.ALIVE


func get_state() -> State:
	return _state


func create_snapshot() -> Dictionary:
	return {"state": int(_state)}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if not snapshot.has("state"):
		return false
	var state: int = int(snapshot["state"])
	if state < State.ALIVE or state > State.WAITING:
		return false
	_state = state as State
	return true
