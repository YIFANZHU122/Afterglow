extends RefCounted
class_name BossProgressModel

## 第六层 Boss 双路线进度，不依赖敌人节点、环境装置或 HUD。

enum Phase {
	FIRST,
	SECOND,
	THIRD,
	DEFEATED,
	WITHDRAWN,
}

enum CompletionRoute {
	NONE,
	COMBAT,
	ENVIRONMENT,
}

const MAX_HEALTH: float = 300.0
const PHASE_HEALTH_FLOORS: Array[float] = [200.0, 100.0, 0.0]
const COMPONENT_COUNT: int = 3

var _phase: Phase = Phase.FIRST
var _health: float = MAX_HEALTH
var _phase_transition_pending: bool = false
var _components: PackedByteArray = PackedByteArray([0, 0, 0])
var _next_device_index: int = 0
var _completion_route: CompletionRoute = CompletionRoute.NONE
var _completion_claimed: bool = false


func apply_combat_damage(amount: float) -> bool:
	if amount <= 0.0 or _completion_route != CompletionRoute.NONE or _phase_transition_pending:
		return false
	if _phase < Phase.FIRST or _phase > Phase.THIRD:
		return false
	var health_floor: float = PHASE_HEALTH_FLOORS[int(_phase)]
	_health = maxf(_health - amount, health_floor)
	if _health > health_floor:
		return true
	if _phase == Phase.THIRD:
		_phase = Phase.DEFEATED
		_completion_route = CompletionRoute.COMBAT
	else:
		_phase_transition_pending = true
	return true


func acknowledge_phase_transition() -> bool:
	if not _phase_transition_pending or _completion_route != CompletionRoute.NONE:
		return false
	_phase_transition_pending = false
	_phase = (int(_phase) + 1) as Phase
	return true


func collect_suppression_component(component_index: int) -> bool:
	if _completion_route != CompletionRoute.NONE or not _is_valid_component(component_index):
		return false
	if _components[component_index] == 1:
		return false
	_components[component_index] = 1
	return true


func activate_environment_device(device_index: int) -> bool:
	if _completion_route != CompletionRoute.NONE or not _is_valid_component(device_index):
		return false
	if device_index != _next_device_index or _components[device_index] == 0:
		return false
	_next_device_index += 1
	if _next_device_index >= COMPONENT_COUNT:
		_phase_transition_pending = false
		_phase = Phase.WITHDRAWN
		_completion_route = CompletionRoute.ENVIRONMENT
	return true


func claim_completion_route() -> CompletionRoute:
	if _completion_route == CompletionRoute.NONE or _completion_claimed:
		return CompletionRoute.NONE
	_completion_claimed = true
	return _completion_route


func get_phase() -> Phase:
	return _phase


func get_health() -> float:
	return _health


func is_phase_transition_pending() -> bool:
	return _phase_transition_pending


func has_component(component_index: int) -> bool:
	return _is_valid_component(component_index) and _components[component_index] == 1


func get_collected_component_count() -> int:
	var count: int = 0
	for value: int in _components:
		count += value
	return count


func get_activated_device_count() -> int:
	return _next_device_index


func get_completion_route() -> CompletionRoute:
	return _completion_route


func is_complete() -> bool:
	return _completion_route != CompletionRoute.NONE


func is_completion_claimed() -> bool:
	return _completion_claimed


func create_snapshot() -> Dictionary:
	return {
		"phase": int(_phase),
		"health": _health,
		"phase_transition_pending": _phase_transition_pending,
		"components": Array(_components),
		"next_device_index": _next_device_index,
		"completion_route": int(_completion_route),
		"completion_claimed": _completion_claimed,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	var required_keys: Array[String] = [
		"phase",
		"health",
		"phase_transition_pending",
		"components",
		"next_device_index",
		"completion_route",
		"completion_claimed",
	]
	for key: String in required_keys:
		if not snapshot.has(key):
			return false
	var restored_phase: int = int(snapshot["phase"])
	var restored_health: float = float(snapshot["health"])
	var restored_components: Array = snapshot["components"] as Array
	var restored_next_device: int = int(snapshot["next_device_index"])
	var restored_route: int = int(snapshot["completion_route"])
	if restored_phase < Phase.FIRST or restored_phase > Phase.WITHDRAWN:
		return false
	if restored_health < 0.0 or restored_health > MAX_HEALTH:
		return false
	if restored_components.size() != COMPONENT_COUNT:
		return false
	if restored_next_device < 0 or restored_next_device > COMPONENT_COUNT:
		return false
	if restored_route < CompletionRoute.NONE or restored_route > CompletionRoute.ENVIRONMENT:
		return false
	var normalized_components := PackedByteArray()
	for value: Variant in restored_components:
		var component_value: int = int(value)
		if component_value != 0 and component_value != 1:
			return false
		normalized_components.append(component_value)
	if not _is_snapshot_consistent(restored_phase, restored_health, restored_next_device, restored_route):
		return false
	_phase = restored_phase as Phase
	_health = restored_health
	_phase_transition_pending = bool(snapshot["phase_transition_pending"])
	_components = normalized_components
	_next_device_index = restored_next_device
	_completion_route = restored_route as CompletionRoute
	_completion_claimed = bool(snapshot["completion_claimed"])
	return true


func _is_snapshot_consistent(phase: int, health: float, next_device_index: int, route: int) -> bool:
	if route == CompletionRoute.COMBAT:
		return phase == Phase.DEFEATED and is_zero_approx(health)
	if route == CompletionRoute.ENVIRONMENT:
		return phase == Phase.WITHDRAWN and next_device_index == COMPONENT_COUNT
	return phase >= Phase.FIRST and phase <= Phase.THIRD and health > 0.0


func _is_valid_component(component_index: int) -> bool:
	return component_index >= 0 and component_index < COMPONENT_COUNT
