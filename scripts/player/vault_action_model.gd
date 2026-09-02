extends RefCounted
class_name VaultActionModel

const STEP_TERRAIN_MODEL_SCRIPT: Script = preload("res://scripts/world/step_terrain_model.gd")

## 翻越的前置条件、站定动作时间和中断状态。

enum State { IDLE, ACTIVE }

var _duration_seconds: float
var _remaining_seconds: float = 0.0
var _state: State = State.IDLE
var _height_steps: int = 0


func _init(duration_seconds: float = 2.0, high_vault_duration_multiplier: float = 1.5) -> void:
	_duration_seconds = maxf(duration_seconds, 0.1)
	_high_vault_duration_multiplier = maxf(high_vault_duration_multiplier, 1.0)

var _high_vault_duration_multiplier: float = 1.5


func try_start(height_steps: int, has_high_vault: bool, stamina_available: float, encumbrance_ratio: float = 1.0) -> bool:
	if _state != State.IDLE or not is_finite(stamina_available) or stamina_available < get_stamina_cost(height_steps, has_high_vault):
		return false
	if not STEP_TERRAIN_MODEL_SCRIPT.can_vault(height_steps, has_high_vault, encumbrance_ratio):
		return false
	_height_steps = height_steps
	_remaining_seconds = get_duration_seconds(height_steps, has_high_vault)
	_state = State.ACTIVE
	return true


func advance(delta: float) -> bool:
	if _state != State.ACTIVE or delta <= 0.0:
		return false
	_remaining_seconds = maxf(_remaining_seconds - delta, 0.0)
	if _remaining_seconds > 0.0:
		return false
	_state = State.IDLE
	return true


func cancel() -> bool:
	if _state == State.IDLE:
		return false
	_state = State.IDLE
	_remaining_seconds = 0.0
	_height_steps = 0
	return true


func get_state() -> State:
	return _state


func get_remaining_seconds() -> float:
	return _remaining_seconds


func get_duration_seconds(height_steps: int, has_high_vault: bool) -> float:
	return _duration_seconds * (_high_vault_duration_multiplier if has_high_vault and height_steps >= 3 else 1.0)


func get_stamina_cost(height_steps: int, has_high_vault: bool) -> float:
	return 2.0 if has_high_vault and height_steps >= 3 else 1.0


func create_snapshot() -> Dictionary:
	return {"format_version": 1, "state": int(_state), "duration_seconds": _duration_seconds, "remaining_seconds": _remaining_seconds, "height_steps": _height_steps}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if int(snapshot.get("format_version", -1)) != 1:
		return false
	var state := int(snapshot.get("state", -1))
	var duration := float(snapshot.get("duration_seconds", -1.0))
	var remaining := float(snapshot.get("remaining_seconds", -1.0))
	var height := int(snapshot.get("height_steps", -1))
	if state < State.IDLE or state > State.ACTIVE or not is_finite(duration) or not is_finite(remaining) or duration <= 0.0 or remaining < 0.0 or height < 0 or height > 3:
		return false
	_state = state as State
	_duration_seconds = duration
	_remaining_seconds = remaining
	_height_steps = height
	return true
