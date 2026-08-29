extends Node
class_name EncounterController

const ENCOUNTER_DEFINITION_SCRIPT: Script = preload("res://scripts/data/encounter_definition.gd")
const ENCOUNTER_SPAWN_DEFINITION_SCRIPT: Script = preload("res://scripts/data/encounter_spawn_definition.gd")
const OBJECTIVE_PROGRESS_MODEL_SCRIPT: Script = preload("res://scripts/world/objective_progress_model.gd")
const THREAT_BUDGET_MODEL_SCRIPT: Script = preload("res://scripts/world/threat_budget_model.gd")
const SPAWN_PROTECTION_MODEL_SCRIPT: Script = preload("res://scripts/world/spawn_protection_model.gd")

const PIXELS_PER_STEP: float = 40.0

signal progress_changed(completed: int, target: int)
signal reward_earned(amount: int)
signal completed

var _progress: RefCounted
var _threat_budget: RefCounted
var _spawn_protection: RefCounted
var _protected_points: Array[Vector2] = []
var _started: bool = false
var _completed_emitted: bool = false


func set_protected_points(points: Array[Vector2]) -> void:
	_protected_points = points.duplicate()


func get_used_threat_budget() -> int:
	return int(_threat_budget.call("get_used_budget")) if _threat_budget != null else 0


func get_threat_budget_limit() -> int:
	return int(_threat_budget.call("get_active_budget")) if _threat_budget != null else 0


func get_protected_point_count() -> int:
	return _protected_points.size()


func start(encounter_definition: Resource, content_root: Node2D) -> bool:
	if _started or encounter_definition == null or content_root == null:
		return false
	if encounter_definition.get_script() != ENCOUNTER_DEFINITION_SCRIPT:
		return false
	_started = true
	_threat_budget = THREAT_BUDGET_MODEL_SCRIPT.new(GameManager.get_floor_day_index(), GameManager.get_overtime_stage())
	_spawn_protection = SPAWN_PROTECTION_MODEL_SCRIPT.new()
	var valid_members: int = 0
	for spawn: Resource in encounter_definition.get("spawns"):
		if spawn == null or spawn.get_script() != ENCOUNTER_SPAWN_DEFINITION_SCRIPT \
			or not bool(spawn.call("is_valid")):
			push_warning("[EncounterController] ignored invalid spawn definition")
			continue
		var entity_scene: PackedScene = spawn.get("entity_scene") as PackedScene
		var threat_cost: int = int(spawn.get("threat_cost"))
		if not bool(_threat_budget.call("register_spawn", threat_cost)):
			push_warning("[EncounterController] ignored spawn that exceeds the threat budget")
			continue
		var candidate: Vector2 = (spawn.get("spawn_position") as Vector2) / PIXELS_PER_STEP
		var player_position: Vector2 = _get_player_position_domain()
		if not bool(_spawn_protection.call(
			"is_valid_spawn",
			candidate,
			player_position,
			_protected_points,
			false,
			true
		)):
			_threat_budget.call("release_spawn", threat_cost)
			push_warning("[EncounterController] ignored spawn inside a protected or visible area")
			continue
		var entity: Node2D = entity_scene.instantiate() as Node2D
		if entity == null:
			_threat_budget.call("release_spawn", threat_cost)
			push_warning("[EncounterController] spawn scene is not a Node2D")
			continue
		var member: Node = entity.get_node_or_null("EncounterMember")
		if member == null or not member.has_signal("defeated"):
			_threat_budget.call("release_spawn", threat_cost)
			push_warning("[EncounterController] spawn scene lacks EncounterMember")
			entity.queue_free()
			continue
		entity.name = "EncounterEntity%d" % valid_members
		member.defeated.connect(_on_member_defeated.bind(threat_cost))
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


func _on_member_defeated(reward_xp: int, threat_cost: int) -> void:
	if _progress == null or not _progress.register_completion():
		return
	_threat_budget.call("release_spawn", threat_cost)
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


func _get_player_position_domain() -> Vector2:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.is_empty() or players[0] == null:
		return Vector2(-10000.0, -10000.0)
	return (players[0] as Node2D).global_position / PIXELS_PER_STEP
