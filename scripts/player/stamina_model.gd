extends RefCounted
class_name StaminaModel

## 与 Input、CharacterBody2D 和 HUD 无关的体力状态机。

enum MoveState {
	WALKING,
	RUNNING,
	EXHAUSTED,
}

const RUN_STAMINA_RATIO: float = 0.25

var _max_stamina: float
var _stamina: float
var _stamina_drain_rate: float
var _stamina_regen_rate: float
var _move_state: MoveState = MoveState.WALKING


func _init(max_stamina: float = 100.0, stamina_drain_rate: float = 30.0, stamina_regen_rate: float = 15.0) -> void:
	_max_stamina = maxf(max_stamina, 0.0)
	_stamina = _max_stamina
	_stamina_drain_rate = maxf(stamina_drain_rate, 0.0)
	_stamina_regen_rate = maxf(stamina_regen_rate, 0.0)


func tick(delta: float, direction: Vector2, sprint_requested: bool) -> void:
	if delta <= 0.0:
		return
	var is_moving: bool = direction != Vector2.ZERO
	match _move_state:
		MoveState.WALKING:
			_stamina = minf(_stamina + _stamina_regen_rate * delta, _max_stamina)
			if sprint_requested and is_moving and _stamina >= _max_stamina * RUN_STAMINA_RATIO:
				_move_state = MoveState.RUNNING
		MoveState.RUNNING:
			_stamina = maxf(_stamina - _stamina_drain_rate * delta, 0.0)
			if _stamina <= 0.0:
				_move_state = MoveState.EXHAUSTED
			elif not sprint_requested or not is_moving:
				_move_state = MoveState.WALKING
		MoveState.EXHAUSTED:
			_stamina = minf(_stamina + _stamina_regen_rate * delta, _max_stamina)
			if _stamina >= _max_stamina * RUN_STAMINA_RATIO:
				_move_state = MoveState.WALKING


func get_stamina() -> float:
	return _stamina


func get_max_stamina() -> float:
	return _max_stamina


func get_state() -> MoveState:
	return _move_state


func get_speed_multiplier(run_speed_multiplier: float, exhausted_speed_multiplier: float) -> float:
	match _move_state:
		MoveState.RUNNING:
			return run_speed_multiplier
		MoveState.EXHAUSTED:
			return exhausted_speed_multiplier
		_:
			return 1.0
