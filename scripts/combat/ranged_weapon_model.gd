extends RefCounted
class_name RangedWeaponModel

## 枪械弹匣运行时状态；不依赖输入、库存或节点树。

const FORMAT_VERSION: int = 1

var _magazine_capacity: int = 0
var _reload_seconds: float = 2.0
var _fire_cooldown_seconds: float = 0.5
var _magazine_rounds: int = 0
var _reserve_rounds: int = 0
var _cooldown_remaining: float = 0.0
var _reload_remaining: float = 0.0
var _reload_target_rounds: int = 0


func _init(magazine_capacity: int = 6, reload_seconds: float = 2.0, fire_cooldown_seconds: float = 0.5) -> void:
	_magazine_capacity = maxi(magazine_capacity, 0)
	_reload_seconds = maxf(reload_seconds, 0.1)
	_fire_cooldown_seconds = maxf(fire_cooldown_seconds, 0.0)


func load_magazine(rounds: int) -> bool:
	if _magazine_capacity <= 0 or rounds < 0 or rounds > _magazine_capacity or is_reloading():
		return false
	_magazine_rounds = rounds
	return true


func try_fire() -> bool:
	if is_reloading() or _cooldown_remaining > 0.0 or _magazine_rounds <= 0:
		return false
	_magazine_rounds -= 1
	_cooldown_remaining = _fire_cooldown_seconds
	return true


func advance(delta: float) -> bool:
	if not is_finite(delta) or delta <= 0.0:
		return false
	var changed: bool = false
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
		changed = true
	if _reload_remaining > 0.0:
		_reload_remaining = maxf(_reload_remaining - delta, 0.0)
		changed = true
		if is_zero_approx(_reload_remaining):
			var loaded: int = mini(_reload_target_rounds, _reserve_rounds)
			_magazine_rounds = mini(_magazine_rounds + loaded, _magazine_capacity)
			_reserve_rounds -= loaded
			_reload_target_rounds = 0
	return changed


func start_reload(reserve_rounds: int) -> bool:
	if _magazine_capacity <= 0 or reserve_rounds <= 0 or is_reloading() or _magazine_rounds >= _magazine_capacity:
		return false
	_reserve_rounds = reserve_rounds
	_reload_target_rounds = _magazine_capacity - _magazine_rounds
	_reload_remaining = _reload_seconds
	return true


func interrupt_reload() -> bool:
	if not is_reloading():
		return false
	_reload_remaining = 0.0
	_reload_target_rounds = 0
	return true


func is_reloading() -> bool:
	return _reload_remaining > 0.0


func get_magazine_rounds() -> int:
	return _magazine_rounds


func get_magazine_capacity() -> int:
	return _magazine_capacity


func get_reserve_rounds() -> int:
	return _reserve_rounds


func get_cooldown_remaining() -> float:
	return _cooldown_remaining


func create_snapshot() -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"magazine_capacity": _magazine_capacity,
		"reload_seconds": _reload_seconds,
		"fire_cooldown_seconds": _fire_cooldown_seconds,
		"magazine_rounds": _magazine_rounds,
		"reserve_rounds": _reserve_rounds,
		"cooldown_remaining": _cooldown_remaining,
		"reload_remaining": _reload_remaining,
		"reload_target_rounds": _reload_target_rounds,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["format_version", "magazine_capacity", "reload_seconds", "fire_cooldown_seconds", "magazine_rounds", "reserve_rounds", "cooldown_remaining", "reload_remaining", "reload_target_rounds"]:
		if not snapshot.has(key):
			return false
	var capacity: int = int(snapshot["magazine_capacity"])
	var reload_seconds: float = float(snapshot["reload_seconds"])
	var fire_cooldown: float = float(snapshot["fire_cooldown_seconds"])
	var magazine: int = int(snapshot["magazine_rounds"])
	var reserve: int = int(snapshot["reserve_rounds"])
	var cooldown: float = float(snapshot["cooldown_remaining"])
	var reload_remaining: float = float(snapshot["reload_remaining"])
	var reload_target: int = int(snapshot["reload_target_rounds"])
	if int(snapshot["format_version"]) != FORMAT_VERSION or capacity < 0 or not is_finite(reload_seconds) or reload_seconds <= 0.0 \
		or not is_finite(fire_cooldown) or fire_cooldown < 0.0 or magazine < 0 or magazine > capacity or reserve < 0 \
		or not is_finite(cooldown) or cooldown < 0.0 or not is_finite(reload_remaining) or reload_remaining < 0.0 \
		or reload_target < 0 or reload_target > capacity - magazine:
		return false
	_magazine_capacity = capacity
	_reload_seconds = reload_seconds
	_fire_cooldown_seconds = fire_cooldown
	_magazine_rounds = magazine
	_reserve_rounds = reserve
	_cooldown_remaining = cooldown
	_reload_remaining = reload_remaining
	_reload_target_rounds = reload_target
	return true
