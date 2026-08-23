extends Node
class_name EncounterController

const ENCOUNTER_DEFINITION_SCRIPT: Script = preload("res://scripts/data/encounter_definition.gd")
const ENCOUNTER_SPAWN_DEFINITION_SCRIPT: Script = preload("res://scripts/data/encounter_spawn_definition.gd")
const OBJECTIVE_PROGRESS_MODEL_SCRIPT: Script = preload("res://scripts/world/objective_progress_model.gd")

signal progress_changed(completed: int, target: int)
signal reward_earned(amount: int)
signal completed

var _progress: RefCounted
var _started: bool = false
var _completed_emitted: bool = false


func start(encounter_definition: Resource, content_root: Node2D) -> bool:
	if _started or encounter_definition == null or content_root == null:
		return false
	if encounter_definition.get_script() != ENCOUNTER_DEFINITION_SCRIPT:
		return false
	_started = true
	var valid_members: int = 0
	for spawn: Resource in encounter_definition.get("spawns"):
		if spawn == null or spawn.get_script() != ENCOUNTER_SPAWN_DEFINITION_SCRIPT \
			or not bool(spawn.call("is_valid")):
			push_warning("[EncounterController] ignored invalid spawn definition")
			continue
		var entity_scene: PackedScene = spawn.get("entity_scene") as PackedScene
		var entity: Node2D = entity_scene.instantiate() as Node2D
		if entity == null:
			push_warning("[EncounterController] spawn scene is not a Node2D")
			continue
		var member: Node = entity.get_node_or_null("EncounterMember")
		if member == null or not member.has_signal("defeated"):
			push_warning("[EncounterController] spawn scene lacks EncounterMember")
			entity.queue_free()
			continue
		entity.name = "EncounterEntity%d" % valid_members
		member.defeated.connect(_on_member_defeated)
		content_root.add_child(entity)
		entity.position = spawn.get("spawn_position")
		valid_members += 1
	_progress = OBJECTIVE_PROGRESS_MODEL_SCRIPT.new(valid_members)
	_emit_progress()
	if _progress.is_complete():
		_emit_completed()
	return true


func get_target_count() -> int:
	return _progress.get_target_count() if _progress != null else 0


func get_completed_count() -> int:
	return _progress.get_completed_count() if _progress != null else 0


func _on_member_defeated(reward_xp: int) -> void:
	if _progress == null or not _progress.register_completion():
		return
	reward_earned.emit(maxi(reward_xp, 0))
	_emit_progress()
	if _progress.is_complete():
		_emit_completed()


func _emit_progress() -> void:
	progress_changed.emit(get_completed_count(), get_target_count())


func _emit_completed() -> void:
	if _completed_emitted:
		return
	_completed_emitted = true
	completed.emit()
