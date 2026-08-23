extends SceneTree

const CONTENT_VALIDATION_MODEL_SCRIPT: Script = preload("res://scripts/data/content_validation_model.gd")

const BASEMENT_AREA_PATH := "res://assets/areas/basement_area.tres"
const DAMAGE_UPGRADE_PATH := "res://assets/upgrades/damage_upgrade.tres"
const MOVE_SPEED_UPGRADE_PATH := "res://assets/upgrades/move_speed_upgrade.tres"

var _failures: int = 0
var _validator: RefCounted


func _init() -> void:
	_validator = CONTENT_VALIDATION_MODEL_SCRIPT.new()
	_validate_area(BASEMENT_AREA_PATH)
	_validate_upgrade(DAMAGE_UPGRADE_PATH)
	_validate_upgrade(MOVE_SPEED_UPGRADE_PATH)
	if _failures == 0:
		print("Framework validation passed")
	else:
		push_error("Framework validation failed: %d resource(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _validate_area(path: String) -> void:
	_validate_resource(path, "validate_area")


func _validate_upgrade(path: String) -> void:
	_validate_resource(path, "validate_upgrade")


func _validate_resource(path: String, validation_method: StringName) -> void:
	var definition: Resource = load(path) as Resource
	if definition == null:
		_failures += 1
		push_error("FAIL: cannot load framework content: %s" % path)
		return
	var errors: PackedStringArray = _validator.call(validation_method, definition)
	if errors.is_empty():
		return
	_failures += 1
	for error: String in errors:
		push_error("FAIL: %s: %s" % [path, error])
