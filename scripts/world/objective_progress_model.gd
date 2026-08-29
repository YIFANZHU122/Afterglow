extends RefCounted
class_name ObjectiveProgressModel

## 关卡目标进度规则，不依赖场景、敌人或 UI。

var _target_count: int
var _completed_count: int = 0


func _init(target_count: int = 0) -> void:
	_target_count = maxi(target_count, 0)


func register_completion() -> bool:
	if is_complete():
		return false
	_completed_count += 1
	return true


func is_complete() -> bool:
	return _completed_count >= _target_count


func get_target_count() -> int:
	return _target_count


func get_completed_count() -> int:
	return _completed_count
