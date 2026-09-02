extends RefCounted
class_name WaterTraversalModel

## 0/1/2/3+ step 水深的通行、减速、体力和溺水缓冲。

enum State { IDLE, SWIMMING, STRUGGLING }

var _stamina: float
var _swim_drain_rate: float
var _state: State = State.IDLE
var _depth_steps: int = 0
var _drowning_buffer: float = 3.0


func _init(initial_stamina: float = 10.0, swim_drain_rate: float = 2.0) -> void:
	_stamina = maxf(initial_stamina, 0.0)
	_swim_drain_rate = maxf(swim_drain_rate, 0.0)


func get_speed_multiplier(depth_steps: int) -> float:
	if depth_steps <= 0:
		return 1.0
	if depth_steps == 1:
		return 0.8
	if depth_steps == 2:
		return 0.55
	return 0.35


func can_enter(depth_steps: int, encumbrance_ratio: float) -> bool:
	return depth_steps >= 0 and is_finite(encumbrance_ratio) and encumbrance_ratio <= 1.4


func start(depth_steps: int) -> bool:
	if not can_enter(depth_steps, 1.0):
		return false
	_depth_steps = depth_steps
	_state = State.SWIMMING if depth_steps >= 2 else State.IDLE
	_drowning_buffer = 3.0
	return true


func tick(delta: float, moving: bool) -> void:
	if delta <= 0.0 or _depth_steps < 2 or _state == State.IDLE:
		return
	if moving:
		_stamina = maxf(_stamina - _swim_drain_rate * delta, 0.0)
	if _stamina <= 0.0:
		_state = State.STRUGGLING
		_drowning_buffer = maxf(_drowning_buffer - delta, 0.0)


func get_state() -> State:
	return _state


func is_drowning() -> bool:
	return _state == State.STRUGGLING and _drowning_buffer < 3.0


func get_drowning_buffer() -> float:
	return _drowning_buffer


func get_depth_steps() -> int:
	return _depth_steps


func create_snapshot() -> Dictionary:
	return {"format_version": 1, "stamina": _stamina, "swim_drain_rate": _swim_drain_rate, "state": int(_state), "depth_steps": _depth_steps, "drowning_buffer": _drowning_buffer}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if int(snapshot.get("format_version", -1)) != 1:
		return false
	var stamina := float(snapshot.get("stamina", -1.0))
	var drain := float(snapshot.get("swim_drain_rate", -1.0))
	var state := int(snapshot.get("state", -1))
	var depth := int(snapshot.get("depth_steps", -1))
	var buffer := float(snapshot.get("drowning_buffer", -1.0))
	if not is_finite(stamina) or not is_finite(drain) or not is_finite(buffer) or stamina < 0.0 or drain < 0.0 or buffer < 0.0 or buffer > 3.0 or state < State.IDLE or state > State.STRUGGLING or depth < 0:
		return false
	_stamina = stamina
	_swim_drain_rate = drain
	_state = state as State
	_depth_steps = depth
	_drowning_buffer = buffer
	return true
