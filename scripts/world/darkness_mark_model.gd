extends RefCounted
class_name DarknessMarkModel

## 无月全黑受击标记；标记跨地图保留，只在下一次无月消费一次。

const FORMAT_VERSION: int = 1
var _pending_mark: bool = false
var _marked_night_index: int = -1


func register_dark_attack(is_new_moon: bool, fully_dark: bool, night_index: int) -> bool:
	if not is_new_moon or not fully_dark or night_index < 0 or _pending_mark:
		return false
	_pending_mark = true
	_marked_night_index = night_index
	return true


func has_pending_mark() -> bool:
	return _pending_mark


func consume_for_new_moon() -> Dictionary:
	var result := {"budget_multiplier": 1.0, "special_tier_two_warning": false}
	if not _pending_mark:
		return result
	_pending_mark = false
	_marked_night_index = -1
	result["budget_multiplier"] = 1.5
	result["special_tier_two_warning"] = true
	return result


func get_marked_night_index() -> int:
	return _marked_night_index


func create_snapshot() -> Dictionary:
	return {"format_version": FORMAT_VERSION, "pending_mark": _pending_mark, "marked_night_index": _marked_night_index}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if int(snapshot.get("format_version", -1)) != FORMAT_VERSION or snapshot.get("pending_mark") is not bool:
		return false
	var night_index: int = int(snapshot.get("marked_night_index", -1))
	if night_index < -1 or (bool(snapshot["pending_mark"]) and night_index < 0):
		return false
	_pending_mark = bool(snapshot["pending_mark"])
	_marked_night_index = night_index
	return true
