extends SceneTree

const CONTENT_VALIDATION_MODEL_SCRIPT: Script = preload("res://scripts/data/content_validation_model.gd")

const BASEMENT_AREA_PATH := "res://assets/areas/basement_area.tres"
const DAMAGE_UPGRADE_PATH := "res://assets/upgrades/damage_upgrade.tres"
const MOVE_SPEED_UPGRADE_PATH := "res://assets/upgrades/move_speed_upgrade.tres"
const MAX_STAMINA_UPGRADE_PATH := "res://assets/upgrades/max_stamina_upgrade.tres"
const STAMINA_REGEN_UPGRADE_PATH := "res://assets/upgrades/stamina_regen_upgrade.tres"
const SURVIVAL_EFFICIENCY_UPGRADE_PATH := "res://assets/upgrades/survival_efficiency_upgrade.tres"
const LUCK_UPGRADE_PATH := "res://assets/upgrades/luck_upgrade.tres"
const ITEM_PATHS: PackedStringArray = [
	"res://assets/items/stone_sword.tres",
	"res://assets/items/wood.tres",
	"res://assets/items/stone.tres",
	"res://assets/items/wild_food.tres",
	"res://assets/items/scrap_parts.tres",
	"res://assets/items/small_food.tres",
	"res://assets/items/ration.tres",
	"res://assets/items/raw_meat.tres",
	"res://assets/items/cooked_meat.tres",
	"res://assets/items/empty_container.tres",
	"res://assets/items/medium_container.tres",
	"res://assets/items/large_container.tres",
	"res://assets/items/torch.tres",
	"res://assets/items/stone_knife.tres",
	"res://assets/items/simple_bandage.tres",
	"res://assets/items/temporary_container.tres",
	"res://assets/items/campfire_kit.tres",
	"res://assets/items/rain_shelter_kit.tres",
	"res://assets/items/wood_wall_kit.tres",
]
const WORLD_RESOURCE_PATHS: PackedStringArray = [
	"res://assets/world_resources/wood_resource.tres",
	"res://assets/world_resources/stone_resource.tres",
	"res://assets/world_resources/wild_food_resource.tres",
	"res://assets/world_resources/scrap_resource.tres",
	"res://assets/world_resources/ration_resource.tres",
]

var _failures: int = 0
var _validator: RefCounted


func _init() -> void:
	_validator = CONTENT_VALIDATION_MODEL_SCRIPT.new()
	_validate_area(BASEMENT_AREA_PATH)
	_validate_upgrade(DAMAGE_UPGRADE_PATH)
	_validate_upgrade(MOVE_SPEED_UPGRADE_PATH)
	_validate_upgrade(MAX_STAMINA_UPGRADE_PATH)
	_validate_upgrade(STAMINA_REGEN_UPGRADE_PATH)
	_validate_upgrade(SURVIVAL_EFFICIENCY_UPGRADE_PATH)
	_validate_upgrade(LUCK_UPGRADE_PATH)
	for item_path: String in ITEM_PATHS:
		_validate_item(item_path)
	for resource_path: String in WORLD_RESOURCE_PATHS:
		_validate_world_resource(resource_path)
	if _failures == 0:
		print("Framework validation passed")
	else:
		push_error("Framework validation failed: %d resource(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _validate_area(path: String) -> void:
	_validate_resource(path, "validate_area")


func _validate_upgrade(path: String) -> void:
	_validate_resource(path, "validate_upgrade")


func _validate_item(path: String) -> void:
	_validate_resource(path, "validate_item")


func _validate_world_resource(path: String) -> void:
	_validate_resource(path, "validate_world_resource")


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
