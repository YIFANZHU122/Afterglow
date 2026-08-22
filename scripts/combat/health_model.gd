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
	if _is_dead or amount <= 0.0:
		return
	_current_health = maxf(_current_health - amount, 0.0)
	if _current_health <= 0.0:
		_is_dead = true


func heal(amount: float) -> void:
	if _is_dead or amount <= 0.0:
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
