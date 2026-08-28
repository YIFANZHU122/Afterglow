extends RefCounted
class_name RunRewardModel

## 本局 XP 与等级规则，不依赖场景、玩家节点或 UI。

var _xp_per_level: int
var _xp: int = 0
var _level: int = 1


func _init(xp_per_level: int = 100) -> void:
	_xp_per_level = maxi(xp_per_level, 1)


func add_xp(amount: int) -> bool:
	if amount <= 0:
		return false
	_xp += amount
	var leveled_up: bool = false
	while _xp >= _xp_per_level:
		_xp -= _xp_per_level
		_level += 1
		leveled_up = true
	return leveled_up


func get_xp() -> int:
	return _xp


func get_level() -> int:
	return _level


func get_xp_to_next_level() -> int:
	return _xp_per_level - _xp


func reset() -> bool:
	var changed: bool = _xp != 0 or _level != 1
	_xp = 0
	_level = 1
	return changed


func create_snapshot() -> Dictionary:
	return {"xp_per_level": _xp_per_level, "xp": _xp, "level": _level}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if not snapshot.has("xp_per_level") or not snapshot.has("xp") or not snapshot.has("level"):
		return false
	var threshold: int = int(snapshot["xp_per_level"])
	var xp: int = int(snapshot["xp"])
	var level: int = int(snapshot["level"])
	if threshold < 1 or xp < 0 or xp >= threshold or level < 1:
		return false
	_xp_per_level = threshold
	_xp = xp
	_level = level
	return true
