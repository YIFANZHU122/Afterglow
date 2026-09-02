extends RefCounted
class_name TorchModel

## 火把运行时状态；制作得到未点燃火把，点火后按剩余时间提供局部照明。

const FORMAT_VERSION: int = 1
const LIGHT_RADIUS: float = 180.0

var _remaining_seconds: float
var _lit: bool = false


func _init(burn_seconds: float = 90.0) -> void:
	_remaining_seconds = maxf(burn_seconds, 0.0)


func ignite_with_lighter() -> bool:
	return _ignite()


func ignite_from_campfire() -> bool:
	return _ignite()


func extinguish() -> bool:
	if not _lit:
		return false
	_lit = false
	return true


func advance(delta: float) -> bool:
	if not _lit or not is_finite(delta) or delta <= 0.0:
		return false
	_remaining_seconds = maxf(_remaining_seconds - delta, 0.0)
	if is_zero_approx(_remaining_seconds):
		_lit = false
	return true


func is_lit() -> bool:
	return _lit


func get_remaining_seconds() -> float:
	return _remaining_seconds


func get_light_radius() -> float:
	return LIGHT_RADIUS if _lit else 0.0


func create_snapshot() -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"remaining_seconds": _remaining_seconds,
		"lit": _lit,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["format_version", "remaining_seconds", "lit"]:
		if not snapshot.has(key):
			return false
	var remaining: float = float(snapshot["remaining_seconds"])
	if int(snapshot["format_version"]) != FORMAT_VERSION or not is_finite(remaining) or remaining < 0.0 \
		or snapshot["lit"] is not bool or (bool(snapshot["lit"]) and is_zero_approx(remaining)):
		return false
	_remaining_seconds = remaining
	_lit = bool(snapshot["lit"])
	return true


func _ignite() -> bool:
	if _lit or _remaining_seconds <= 0.0:
		return false
	_lit = true
	return true
