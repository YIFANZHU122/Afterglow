extends RefCounted
class_name HealthModel

## 与节点树和表现无关的生命状态规则。

var _max_health: float
var _current_health: float
var _is_dead: bool = false


func _init(max_health: float = 100.0) -> void:
	_max_health = maxf(max_health, 0.0)
	_current_health = _max_health


func take_damage(amount: float) -> void:
	if _is_dead or not is_finite(amount) or amount <= 0.0:
		return
	_current_health = maxf(_current_health - amount, 0.0)
	if _current_health <= 0.0:
		_is_dead = true


func heal(amount: float) -> void:
	if _is_dead or not is_finite(amount) or amount <= 0.0:
		return
	_current_health = minf(_current_health + amount, _max_health)


func reset() -> void:
	_is_dead = false
	_current_health = _max_health


func get_health() -> float:
	return _current_health


func get_max_health() -> float:
	return _max_health


func is_dead() -> bool:
	return _is_dead


func create_snapshot() -> Dictionary:
	return {"max_health": _max_health, "current_health": _current_health, "is_dead": _is_dead}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["max_health", "current_health", "is_dead"]:
		if not snapshot.has(key):
			return false
	var max_health: float = float(snapshot["max_health"])
	var current_health: float = float(snapshot["current_health"])
	if not _is_numeric(snapshot["max_health"]) or not _is_numeric(snapshot["current_health"]) \
		or not is_finite(max_health) or not is_finite(current_health) \
		or typeof(snapshot["is_dead"]) != TYPE_BOOL \
		or max_health < 0.0 or current_health < 0.0 or current_health > max_health:
		return false
	var is_dead: bool = bool(snapshot["is_dead"])
	if is_dead and not is_zero_approx(current_health):
		return false
	if not is_dead and max_health > 0.0 and is_zero_approx(current_health):
		return false
	_max_health = max_health
	_current_health = current_health
	_is_dead = is_dead
	return true


func _is_numeric(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
