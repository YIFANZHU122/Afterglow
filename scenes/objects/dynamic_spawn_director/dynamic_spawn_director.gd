extends Node
class_name DynamicSpawnDirector

const DIRECTOR_MODEL_SCRIPT: Script = preload("res://scripts/world/dynamic_spawn_director_model.gd")
const THREAT_BUDGET_MODEL_SCRIPT: Script = preload("res://scripts/world/threat_budget_model.gd")
const SPAWN_POINT_SCRIPT: Script = preload("res://scripts/data/dynamic_spawn_point_definition.gd")
const NIGHT_FOG_MODEL_SCRIPT: Script = preload("res://scripts/world/night_fog_model.gd")
const DROP_BUDGET_MODEL_SCRIPT: Script = preload("res://scripts/items/drop_budget_model.gd")
const ENEMY_DROP_SERVICE_SCRIPT: Script = preload("res://scripts/items/enemy_drop_service.gd")
const ENEMY_ROLE_MODEL_SCRIPT: Script = preload("res://scripts/combat/enemy_role_model.gd")

@export var enemy_scene: PackedScene
@export var spawn_points: Array[Resource] = []
@export var content_root_path: NodePath = NodePath("../DynamicContentRoot")
@export var protected_point_paths: Array[NodePath] = []
@export var map_center: Vector2 = Vector2.ZERO
@export var map_radius: float = 1000.0
@export_range(1, 8, 1) var max_dynamic_enemies: int = 4

var _model: RefCounted
var _threat_budget: RefCounted
var _content_root: Node2D
var _dynamic_count: int = 0
var _dynamic_entities: Dictionary = {}
var _next_entity_index: int = 1
var _active_new_moon_index: int = -1
var _darkness_budget_multiplier: float = 1.0
var _force_special_next_wave: bool = false
var _drop_budget: RefCounted
var _drop_service: RefCounted


func _ready() -> void:
	add_to_group("snapshot_dynamic_spawn_director")
	_model = DIRECTOR_MODEL_SCRIPT.new()
	_threat_budget = THREAT_BUDGET_MODEL_SCRIPT.new(GameManager.get_floor_day_index(), GameManager.get_overtime_stage())
	_drop_budget = DROP_BUDGET_MODEL_SCRIPT.new(3, 8, 2)
	_drop_service = ENEMY_DROP_SERVICE_SCRIPT.new()
	_content_root = get_node_or_null(content_root_path) as Node2D


func _process(delta: float) -> void:
	if _model == null or not GameManager.has_method("get_run_state") or GameManager.get_run_state() != 2:
		return
	var is_night: bool = GameManager.is_floor_night()
	_update_moon_pressure(is_night)
	var moon_multiplier: float = float(GameManager.get_monster_spawn_multiplier()) if GameManager.has_method("get_monster_spawn_multiplier") else 1.0
	var pressure_multiplier: float = maxf(moon_multiplier * _darkness_budget_multiplier, 0.1)
	_model.set_wave_interval_seconds(DIRECTOR_MODEL_SCRIPT.DEFAULT_WAVE_INTERVAL_SECONDS / pressure_multiplier)
	_threat_budget.set_time_context(GameManager.get_floor_day_index(), GameManager.get_overtime_stage())
	_threat_budget.set_disaster_bonus_ratio(maxf(pressure_multiplier - 1.0, 0.0))
	_model.advance(delta, is_night)
	if not is_night or not _model.is_wave_ready() or _dynamic_count >= max_dynamic_enemies:
		return
	var candidate_points: Array[Resource] = []
	for point: Resource in spawn_points:
		if point != null and point.get_script() == SPAWN_POINT_SCRIPT:
			candidate_points.append(point)
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null or _content_root == null:
		_model.register_retry()
		return
	var protected_points: Array[Vector2] = []
	for path: NodePath in protected_point_paths:
		var point_node: Node2D = _resolve_scene_node(path) as Node2D
		if point_node != null:
			protected_points.append(point_node.global_position / 40.0)
	var filtered_points: Array[Resource] = []
	for candidate: Resource in candidate_points:
		if _candidate_is_in_fog(candidate) and not _candidate_is_visible(candidate, player):
			filtered_points.append(candidate)
	var special_ratio: float = float(GameManager.get_special_spawn_ratio()) if GameManager.has_method("get_special_spawn_ratio") else 0.0
	var point: Resource = _model.choose_spawn_point(filtered_points, GameManager, player.global_position / 40.0, protected_points, false, true, false, special_ratio)
	if point == null or not _threat_budget.register_spawn(int(point.threat_cost)):
		_model.register_retry()
		return
	_model.consume_wave()
	var is_special: bool = _force_special_next_wave
	if not is_special and special_ratio > 0.0 and GameManager.has_method("random_float"):
		is_special = GameManager.random_float(&"enemy_special") < special_ratio
	var enemy: Node2D = enemy_scene.instantiate() as Node2D
	if enemy == null:
		_threat_budget.release_spawn(int(point.threat_cost))
		_model.register_retry()
		return
	enemy.add_to_group("dynamic_enemy")
	_content_root.add_child(enemy)
	var entity_id: String = "DynamicEnemy%d" % _next_entity_index
	enemy.name = entity_id
	enemy.global_position = point.position
	_dynamic_count += 1
	_next_entity_index += 1
	_dynamic_entities[entity_id] = {"threat_cost": int(point.threat_cost), "node": enemy}
	if is_special and enemy.has_method("set_dynamic_special"):
		enemy.call("set_dynamic_special", true)
		_force_special_next_wave = false
	if enemy.has_method("set_environment_speed_multiplier") and GameManager.has_method("get_enemy_speed_multiplier"):
		enemy.call("set_environment_speed_multiplier", float(GameManager.get_enemy_speed_multiplier()))
	if enemy.has_method("set_enemy_role"):
		var role: int = ENEMY_ROLE_MODEL_SCRIPT.Role.HUNTER
		if point.tags.has("forest"):
			role = ENEMY_ROLE_MODEL_SCRIPT.Role.INVESTIGATOR
		elif point.tags.has("east") or point.tags.has("scrub"):
			role = ENEMY_ROLE_MODEL_SCRIPT.Role.SIEGE
		enemy.call("set_enemy_role", role)
	var member: Node = enemy.get_node_or_null("EncounterMember")
	if member != null and member.has_signal("defeated"):
		member.defeated.connect(_on_dynamic_enemy_defeated.bind(entity_id, int(point.threat_cost)))


func get_dynamic_enemy_count() -> int:
	return _dynamic_count


func create_snapshot() -> Dictionary:
	var entities: Array[Dictionary] = []
	for entity_id: String in _dynamic_entities.keys():
		var entry: Dictionary = _dynamic_entities[entity_id]
		var node: Node = entry.get("node") as Node
		if node == null or not is_instance_valid(node) or not node.has_method("create_snapshot"):
			continue
		entities.append({
			"entity_id": entity_id,
			"threat_cost": int(entry.get("threat_cost", 1)),
			"state": node.call("create_snapshot"),
		})
	entities.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return String(left.get("entity_id", "")) < String(right.get("entity_id", "")))
	return {
		"format_version": 1,
		"director_state": _model.create_snapshot(),
		"threat_budget": _threat_budget.create_snapshot(),
		"drop_budget": _drop_budget.create_snapshot() if _drop_budget != null else {},
		"next_entity_index": _next_entity_index,
		"force_special_next_wave": _force_special_next_wave,
		"entities": entities,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if _model == null or _content_root == null or int(snapshot.get("format_version", -1)) != 1:
		return false
	var director_state: Dictionary = snapshot.get("director_state", {}) as Dictionary
	var restored_model: RefCounted = DIRECTOR_MODEL_SCRIPT.new()
	if not restored_model.restore_snapshot(director_state):
		return false
	var restored_budget: RefCounted = THREAT_BUDGET_MODEL_SCRIPT.new(GameManager.get_floor_day_index(), GameManager.get_overtime_stage())
	var restored_drop_budget: RefCounted = DROP_BUDGET_MODEL_SCRIPT.new(3, 8, 2)
	var expected_used_budget: int = 0
	if snapshot.has("threat_budget"):
		var budget_snapshot: Dictionary = snapshot.get("threat_budget", {}) as Dictionary
		expected_used_budget = int(budget_snapshot.get("used_budget", -1))
		var empty_budget_snapshot: Dictionary = budget_snapshot.duplicate(true)
		empty_budget_snapshot["used_budget"] = 0
		if not restored_budget.restore_snapshot(empty_budget_snapshot):
			return false
	if snapshot.has("drop_budget") and not restored_drop_budget.restore_snapshot(snapshot.get("drop_budget", {}) as Dictionary):
		return false
	var raw_entities: Array = snapshot.get("entities", []) as Array
	var new_entities: Dictionary = {}
	var next_index: int = maxi(int(snapshot.get("next_entity_index", 1)), 1)
	var force_special_next_wave: bool = bool(snapshot.get("force_special_next_wave", false))
	var max_index: int = 0
	for raw_entity: Variant in raw_entities:
		if not raw_entity is Dictionary:
			_free_entity_nodes(new_entities)
			return false
		var entity_data: Dictionary = raw_entity
		var entity_id: String = String(entity_data.get("entity_id", ""))
		var threat_cost: int = int(entity_data.get("threat_cost", 0))
		if entity_id.is_empty() or threat_cost < 1 or enemy_scene == null:
			_free_entity_nodes(new_entities)
			return false
		if new_entities.has(entity_id):
			_free_entity_nodes(new_entities)
			return false
		var suffix: String = entity_id.trim_prefix("DynamicEnemy")
		if suffix.is_valid_int():
			max_index = maxi(max_index, int(suffix))
		if not restored_budget.register_spawn(threat_cost):
			_free_entity_nodes(new_entities)
			return false
		var enemy: Node2D = enemy_scene.instantiate() as Node2D
		if enemy == null or not enemy.has_method("restore_snapshot"):
			restored_budget.release_spawn(threat_cost)
			_free_entity_nodes(new_entities)
			return false
		enemy.name = entity_id
		enemy.add_to_group("dynamic_enemy")
		_content_root.add_child(enemy)
		if not bool(enemy.call("restore_snapshot", entity_data.get("state", {}))):
			enemy.queue_free()
			restored_budget.release_spawn(threat_cost)
			_free_entity_nodes(new_entities)
			return false
		new_entities[entity_id] = {"threat_cost": threat_cost, "node": enemy}
		var member: Node = enemy.get_node_or_null("EncounterMember")
		if member != null and member.has_signal("defeated"):
			member.defeated.connect(_on_dynamic_enemy_defeated.bind(entity_id, threat_cost))
	if snapshot.has("threat_budget") and restored_budget.get_used_budget() != expected_used_budget:
		for entity_id: String in new_entities.keys():
			(new_entities[entity_id] as Dictionary).get("node").queue_free()
		return false
	for entity_id: String in _dynamic_entities.keys():
		var existing: Node = (_dynamic_entities[entity_id] as Dictionary).get("node") as Node
		if existing != null and is_instance_valid(existing):
			existing.queue_free()
	_dynamic_entities = new_entities
	_dynamic_count = new_entities.size()
	_next_entity_index = maxi(next_index, max_index + 1)
	_force_special_next_wave = force_special_next_wave
	_model = restored_model
	_threat_budget = restored_budget
	_drop_budget = restored_drop_budget
	return true


func _on_dynamic_enemy_defeated(_reward_xp: int, entity_id: String, threat_cost: int) -> void:
	if not _dynamic_entities.has(entity_id):
		return
	var entry: Dictionary = _dynamic_entities[entity_id]
	var defeated_entity: Node2D = entry.get("node") as Node2D
	if _drop_service != null and _drop_budget != null and defeated_entity != null:
		var tier: int = int(defeated_entity.call("get_enemy_tier")) if defeated_entity.has_method("get_enemy_tier") else 0
		var food_roll: float = GameManager.random_float(&"enemy_food") if GameManager.has_method("random_float") else 1.0
		var material_roll: float = GameManager.random_float(&"enemy_material") if GameManager.has_method("random_float") else 1.0
		var crystal_roll: float = GameManager.random_float(&"enemy_crystal") if GameManager.has_method("random_float") else 1.0
		_drop_service.spawn_for_enemy(_content_root, defeated_entity.global_position, tier, _drop_budget, food_roll, material_roll, crystal_roll)
	_dynamic_entities.erase(entity_id)
	_dynamic_count = maxi(_dynamic_count - 1, 0)
	_threat_budget.release_spawn(threat_cost)


func _update_moon_pressure(is_night: bool) -> void:
	if not is_night:
		_active_new_moon_index = -1
		_darkness_budget_multiplier = 1.0
		return
	var night_index: int = GameManager.get_night_index()
	if night_index == _active_new_moon_index:
		return
	_active_new_moon_index = night_index
	_darkness_budget_multiplier = 1.0
	if GameManager.is_new_moon() and GameManager.has_method("consume_new_moon_mark"):
		var mark_effect: Dictionary = GameManager.consume_new_moon_mark()
		_darkness_budget_multiplier = maxf(float(mark_effect.get("budget_multiplier", 1.0)), 1.0)
		_force_special_next_wave = bool(mark_effect.get("special_tier_two_warning", false))


func _candidate_is_in_fog(candidate: Resource) -> bool:
	if candidate == null or not candidate.is_valid():
		return false
	var phase: int = GameManager.get_night_fog_phase()
	var night_elapsed: float = GameManager.get_night_elapsed_seconds() if GameManager.has_method("get_night_elapsed_seconds") else 0.0
	var map_radius_steps: float = maxf(map_radius / 40.0, 1.0)
	var distance_steps: float = candidate.position.distance_to(map_center) / 40.0
	return phase > 0 and NIGHT_FOG_MODEL_SCRIPT.new().is_in_fog(distance_steps, map_radius_steps, night_elapsed, true)


func _candidate_is_visible(candidate: Resource, player: Node2D) -> bool:
	if candidate == null or player == null:
		return true
	var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if camera == null or not camera.enabled:
		return false
	var viewport_size: Vector2 = camera.get_viewport_rect().size / camera.zoom
	var visible_rect := Rect2(camera.global_position - viewport_size * 0.5, viewport_size).grow(64.0)
	return visible_rect.has_point(candidate.position)


func _resolve_scene_node(path: NodePath) -> Node:
	var parent_root: Node = get_parent()
	var node: Node = parent_root.get_node_or_null(path) if parent_root != null else null
	var scene_root: Node = owner if owner != null else get_tree().current_scene
	if node == null:
		node = scene_root.get_node_or_null(path) if scene_root != null else null
	if node == null:
		node = get_node_or_null(path)
	return node


func _free_entity_nodes(entities: Dictionary) -> void:
	for entity_id: String in entities.keys():
		var node: Node = (entities[entity_id] as Dictionary).get("node") as Node
		if node != null and is_instance_valid(node):
			node.queue_free()
