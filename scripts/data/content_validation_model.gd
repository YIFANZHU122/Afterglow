extends RefCounted
class_name ContentValidationModel

## Read-only validation for static framework content resources.

const ENCOUNTER_SPAWN_DEFINITION_SCRIPT: Script = preload("res://scripts/data/encounter_spawn_definition.gd")
const ENCOUNTER_DEFINITION_SCRIPT: Script = preload("res://scripts/data/encounter_definition.gd")
const AREA_DEFINITION_SCRIPT: Script = preload("res://scripts/data/area_definition.gd")
const UPGRADE_DEFINITION_SCRIPT: Script = preload("res://scripts/data/upgrade_definition.gd")


func validate_spawn(definition: Resource) -> PackedStringArray:
	var errors := PackedStringArray()
	if definition == null:
		errors.append("spawn definition is null")
		return errors
	if definition.get_script() != ENCOUNTER_SPAWN_DEFINITION_SCRIPT:
		errors.append("spawn definition uses an unexpected script")
		return errors
	if not bool(definition.call("is_valid")):
		errors.append("spawn definition requires an entity scene")
	return errors


func validate_encounter(definition: Resource) -> PackedStringArray:
	var errors := PackedStringArray()
	if definition == null:
		errors.append("encounter definition is null")
		return errors
	if definition.get_script() != ENCOUNTER_DEFINITION_SCRIPT:
		errors.append("encounter definition uses an unexpected script")
		return errors

	var spawns: Array[Resource] = definition.get("spawns")
	if spawns.is_empty():
		errors.append("encounter definition requires at least one spawn")
		return errors
	for index: int in spawns.size():
		var spawn_errors: PackedStringArray = validate_spawn(spawns[index])
		for spawn_error: String in spawn_errors:
			errors.append("spawn %d: %s" % [index, spawn_error])
	if not bool(definition.call("is_valid")) and errors.is_empty():
		errors.append("encounter definition is invalid")
	return errors


func validate_area(definition: Resource) -> PackedStringArray:
	var errors := PackedStringArray()
	if definition == null:
		errors.append("area definition is null")
		return errors
	if definition.get_script() != AREA_DEFINITION_SCRIPT:
		errors.append("area definition uses an unexpected script")
		return errors
	if StringName(definition.get("id")).is_empty():
		errors.append("area definition requires an id")
	if String(definition.get("display_name")).is_empty():
		errors.append("area definition requires a display name")

	var encounter: Resource = definition.get("encounter")
	var encounter_errors: PackedStringArray = validate_encounter(encounter)
	for encounter_error: String in encounter_errors:
		errors.append("encounter: %s" % encounter_error)
	if not bool(definition.call("is_valid")) and errors.is_empty():
		errors.append("area definition is invalid")
	return errors


func validate_upgrade(definition: Resource) -> PackedStringArray:
	var errors := PackedStringArray()
	if definition == null:
		errors.append("upgrade definition is null")
		return errors
	if definition.get_script() != UPGRADE_DEFINITION_SCRIPT:
		errors.append("upgrade definition uses an unexpected script")
		return errors
	if not bool(definition.call("is_valid")):
		errors.append("upgrade definition requires an id, display name, supported effect, and positive amount")
	return errors
