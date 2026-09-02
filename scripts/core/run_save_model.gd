extends RefCounted
class_name RunSaveModel

## 本地运行存档服务。负责固定 schema、原子替换、边界回退和最终失效标记。

const RUN_SNAPSHOT_DATA_SCRIPT: Script = preload("res://scripts/core/run_snapshot_data.gd")
const SAVE_SUFFIX: String = ".safe.json"
const BOUNDARY_SUFFIX: String = ".boundary.json"
const INVALIDATION_SUFFIX: String = ".invalidated.json"
const TEMP_SUFFIX: String = ".tmp"
const BACKUP_SUFFIX: String = ".bak"

var _base_path: String


func _init(base_path: String = "user://afterglow_run") -> void:
	_base_path = base_path


func save_safe_exit(snapshot: RefCounted) -> bool:
	if not _is_valid_snapshot(snapshot):
		return false
	if _has_invalidation_marker():
		return false
	return _atomic_write(_safe_path(), JSON.stringify(snapshot.to_dictionary()))


func save_floor_boundary(snapshot: RefCounted) -> bool:
	if not _is_valid_snapshot(snapshot):
		return false
	if _has_invalidation_marker():
		return false
	return _atomic_write(_boundary_path(), JSON.stringify(snapshot.to_dictionary()))


func load_latest() -> RefCounted:
	if _has_invalidation_marker():
		return null
	var safe_snapshot: RefCounted = _load_snapshot(_safe_path())
	if safe_snapshot != null and safe_snapshot.is_recoverable():
		return safe_snapshot
	var boundary_snapshot: RefCounted = _load_snapshot(_boundary_path())
	if boundary_snapshot != null and boundary_snapshot.is_recoverable():
		return boundary_snapshot
	return null


func invalidate_run(settlement_id: String) -> bool:
	if settlement_id.is_empty():
		return false
	var marker: Dictionary = {
		"schema_version": RUN_SNAPSHOT_DATA_SCRIPT.CURRENT_SCHEMA_VERSION,
		"settlement_id": settlement_id,
		"invalidated": true,
	}
	return _atomic_write(_invalidation_path(), JSON.stringify(marker))


func has_valid_run() -> bool:
	return load_latest() != null


func clear_files() -> bool:
	var changed: bool = false
	for path: String in [
		_safe_path(),
		_boundary_path(),
		_invalidation_path(),
		_safe_path() + TEMP_SUFFIX,
		_boundary_path() + TEMP_SUFFIX,
		_invalidation_path() + TEMP_SUFFIX,
		_safe_path() + BACKUP_SUFFIX,
		_boundary_path() + BACKUP_SUFFIX,
		_invalidation_path() + BACKUP_SUFFIX,
	]:
		if FileAccess.file_exists(path):
			changed = DirAccess.remove_absolute(path) == OK or changed
	return changed


func corrupt_safe_exit_for_test() -> bool:
	var file := FileAccess.open(_safe_path(), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string("not valid json")
	file.close()
	return true


func _is_valid_snapshot(snapshot: RefCounted) -> bool:
	return snapshot != null and snapshot.get_script() == RUN_SNAPSHOT_DATA_SCRIPT \
		and bool(snapshot.call("is_recoverable"))


func _load_snapshot(path: String) -> RefCounted:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parser := JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not parser.data is Dictionary:
		return null
	var parsed: Dictionary = parser.data
	var snapshot: RefCounted = RUN_SNAPSHOT_DATA_SCRIPT.new()
	if not bool(snapshot.call("from_dictionary", parsed)):
		return null
	return snapshot


func _atomic_write(path: String, content: String) -> bool:
	var temp_path: String = path + TEMP_SUFFIX
	var backup_path: String = path + BACKUP_SUFFIX
	var temp_file := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp_file == null:
		return false
	temp_file.store_string(content)
	temp_file.flush()
	temp_file.close()
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	if FileAccess.file_exists(path):
		if DirAccess.rename_absolute(path, backup_path) != OK:
			DirAccess.remove_absolute(temp_path)
			return false
	if DirAccess.rename_absolute(temp_path, path) != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_path, path)
		DirAccess.remove_absolute(temp_path)
		return false
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	return true


func _has_invalidation_marker() -> bool:
	if not FileAccess.file_exists(_invalidation_path()):
		return false
	var file := FileAccess.open(_invalidation_path(), FileAccess.READ)
	if file == null:
		return true
	var parser := JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not parser.data is Dictionary:
		return true
	var parsed: Dictionary = parser.data
	return RUN_SNAPSHOT_DATA_SCRIPT.SUPPORTED_SCHEMA_VERSIONS.has(int(parsed.get("schema_version", -1))) \
		and bool(parsed.get("invalidated", false))


func _safe_path() -> String:
	return _base_path + SAVE_SUFFIX


func _boundary_path() -> String:
	return _base_path + BOUNDARY_SUFFIX


func _invalidation_path() -> String:
	return _base_path + INVALIDATION_SUFFIX
