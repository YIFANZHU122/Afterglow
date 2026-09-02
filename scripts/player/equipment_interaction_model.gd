extends RefCounted
class_name EquipmentInteractionModel

## 装备更换交互状态；实际装备变更由上层在完成事件后提交。

enum State {
	IDLE,
	CHANGING,
	COMPLETED,
}

enum Operation {
	EQUIP,
	UNEQUIP,
}

const SLOT_COUNT: int = 4
const DEFAULT_DURATION_SECONDS: float = 2.0

var _state: State = State.IDLE
var _operation: Operation = Operation.EQUIP
var _slot: int = -1
var _item_id: StringName = StringName()
var _progress_seconds: float = 0.0
var _duration_seconds: float = DEFAULT_DURATION_SECONDS


func start(slot: int, item_id: StringName, duration_seconds: float = DEFAULT_DURATION_SECONDS) -> bool:
	return _start_operation(Operation.EQUIP, slot, item_id, duration_seconds)


func start_unequip(slot: int, item_id: StringName, duration_seconds: float = DEFAULT_DURATION_SECONDS) -> bool:
	return _start_operation(Operation.UNEQUIP, slot, item_id, duration_seconds)


func _start_operation(operation: Operation, slot: int, item_id: StringName, duration_seconds: float) -> bool:
	if _state != State.IDLE or slot < 0 or slot >= SLOT_COUNT or item_id.is_empty() \
		or not is_finite(duration_seconds) or duration_seconds <= 0.0:
		return false
	_state = State.CHANGING
	_operation = operation
	_slot = slot
	_item_id = item_id
	_progress_seconds = 0.0
	_duration_seconds = duration_seconds
	return true


func advance(delta: float, is_moving: bool, was_hit: bool) -> bool:
	if _state != State.CHANGING or delta <= 0.0:
		return false
	if is_moving or was_hit:
		cancel()
		return false
	_progress_seconds = minf(_progress_seconds + delta, _duration_seconds)
	if _progress_seconds < _duration_seconds:
		return false
	_state = State.COMPLETED
	return true


func cancel() -> bool:
	if _state == State.IDLE:
		return false
	_state = State.IDLE
	_operation = Operation.EQUIP
	_slot = -1
	_item_id = StringName()
	_progress_seconds = 0.0
	_duration_seconds = DEFAULT_DURATION_SECONDS
	return true


func consume_completed() -> Dictionary:
	if _state != State.COMPLETED:
		return {}
	var result := {"operation": int(_operation), "slot": _slot, "item_id": String(_item_id)}
	cancel()
	return result


func get_state() -> State:
	return _state


func get_progress_seconds() -> float:
	return _progress_seconds


func get_remaining_seconds() -> float:
	return maxf(_duration_seconds - _progress_seconds, 0.0)


func create_snapshot() -> Dictionary:
	return {
		"state": int(_state),
		"operation": int(_operation),
		"slot": _slot,
		"item_id": String(_item_id),
		"progress_seconds": _progress_seconds,
		"duration_seconds": _duration_seconds,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	var state := int(snapshot.get("state", -1))
	var operation := int(snapshot.get("operation", Operation.EQUIP))
	var slot := int(snapshot.get("slot", -1))
	var raw_id: Variant = snapshot.get("item_id", "")
	var progress := _parse_finite_float(snapshot.get("progress_seconds", -1.0))
	var duration := _parse_finite_float(snapshot.get("duration_seconds", -1.0))
	if state < State.IDLE or state > State.COMPLETED or operation < Operation.EQUIP or operation > Operation.UNEQUIP \
		or slot < -1 or slot >= SLOT_COUNT \
		or (typeof(raw_id) != TYPE_STRING and typeof(raw_id) != TYPE_STRING_NAME) \
		or not is_finite(progress) or progress < 0.0 or not is_finite(duration) or duration <= 0.0 \
		or progress > duration:
		return false
	if state == State.IDLE and (slot != -1 or not String(raw_id).is_empty() or progress != 0.0):
		return false
	if state != State.IDLE and (slot < 0 or String(raw_id).is_empty()):
		return false
	_state = state as State
	_operation = operation as Operation
	_slot = slot
	_item_id = StringName(raw_id)
	_progress_seconds = progress
	_duration_seconds = duration
	return true


func _parse_finite_float(value: Variant) -> float:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return INF
	var parsed := float(value)
	return parsed if is_finite(parsed) else INF
