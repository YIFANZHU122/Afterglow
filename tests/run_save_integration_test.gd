extends Node

const BASEMENT_SCENE: PackedScene = preload("res://scenes/world/basement/basement.tscn")
const CIHANG_SCENE: PackedScene = preload("res://scenes/world/cihang_outskirts/cihang_outskirts.tscn")
const RUN_RANDOM_STREAM_MODEL_SCRIPT: Script = preload("res://scripts/core/run_random_stream_model.gd")
const RUN_SNAPSHOT_DATA_SCRIPT: Script = preload("res://scripts/core/run_snapshot_data.gd")
const ESCAPE_OBJECTIVE_MODEL_SCRIPT: Script = preload("res://scripts/world/escape_objective_model.gd")

class RecordingSaveService extends RefCounted:
	var boundary_should_succeed: bool = true
	var boundary_calls: int = 0
	var last_boundary_snapshot: RefCounted = null
	var latest_snapshot: RefCounted = null

	func save_floor_boundary(snapshot: RefCounted) -> bool:
		boundary_calls += 1
		last_boundary_snapshot = snapshot
		return boundary_should_succeed

	func save_safe_exit(_snapshot: RefCounted) -> bool:
		return true

	func load_latest() -> RefCounted:
		return latest_snapshot

var _failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	GameManager.reset_run()
	_assert_true(GameManager.start_run(0, 97531, 2), "integration run starts")
	_assert_true(GameManager.prepare_floor(), "integration run enters exploration")
	var basement: Node = BASEMENT_SCENE.instantiate()
	add_child(basement)
	await get_tree().process_frame
	await get_tree().process_frame
	var player: Node2D = basement.get_node("Player") as Node2D
	var enemy: Node2D = basement.get_node("ContentRoot/EncounterEntity1") as Node2D
	player.global_position = Vector2(333.0, 277.0)
	player.velocity = Vector2(41.0, -13.0)
	var player_health: Node = player.get_node("HealthComponent")
	player_health.call("take_damage", 17.0)
	var enemy_health: Node = enemy.get_node("HealthComponent")
	enemy_health.call("take_damage", 13.0)
	enemy.global_position = Vector2(811.0, 402.0)
	var escape_part: Node = basement.get_node_or_null("EscapeParts0")
	if escape_part != null:
		escape_part.call("_try_pickup")
	GameManager.start_disaster(0)
	GameManager.advance_disasters(3.0)
	GameManager.tick_survival(27.0)
	Inventory.reset_for_new_run()
	var empty_container: ItemData = preload("res://assets/items/empty_container.tres")
	var wood_item: ItemData = preload("res://assets/items/wood.tres")
	var water_source: Node = basement.get_node("WaterSourceBasement01")
	_assert_true(Inventory.add_item(empty_container), "save integration adds a container")
	_assert_true(bool(water_source.call("fill_selected_container")), "save integration fills a container")
	_assert_equal(int(Inventory.get_selected_container_snapshot().get("amount", 0)), 1, "filled water is present before saving")
	_assert_true(Inventory.add_quantity(wood_item, 1), "save integration adds campfire fuel")
	Inventory.set_selected_slot(1)
	_assert_equal(Inventory.get_selected_slot(), 1, "save integration selects campfire fuel")
	var campfire: Node = basement.get_node("CampfireBasement01")
	_assert_true(bool(campfire.call("add_fuel_from_inventory")), "save integration fuels the campfire")
	_assert_true(bool(campfire.call("ignite_with_lighter")), "save integration lights the campfire")
	Inventory.set_selected_slot(0)
	_assert_equal(Inventory.get_selected_slot(), 0, "save integration returns to the water container")
	var snapshot: RefCounted = GameManager.call("_create_run_snapshot") as RefCounted
	_assert_true(snapshot != null, "runtime snapshot can be created")
	if snapshot != null:
		_assert_true((snapshot.get("player_state") as Dictionary).has("position"), "snapshot records player state")
		_assert_true((snapshot.get("player_state") as Dictionary).has("traversal"), "snapshot records traversal state")
		_assert_true(((snapshot.get("player_state") as Dictionary).get("traversal", {}) as Dictionary).has("water"), "snapshot records water traversal state")
		_assert_true(snapshot.get("character_build_state") is Dictionary, "snapshot records the character build state")
		_assert_true((snapshot.get("character_build_state") as Dictionary).has("attributes"), "snapshot records character attributes for safe exit")
		_assert_true((snapshot.get("enemy_state") as Dictionary).has("entities"), "snapshot records enemy entities")
		_assert_true((snapshot.get("survival_state") as Dictionary).has("night_fog"), "snapshot records night fog state")
		_assert_true((snapshot.get("survival_state") as Dictionary).has("moon_cycle"), "snapshot records moon cycle state")
		_assert_true((snapshot.get("survival_state") as Dictionary).has("darkness_mark"), "snapshot records darkness mark state")
		_assert_true((snapshot.get("survival_state") as Dictionary).has("environment_effects"), "snapshot records aggregated environment effects")
		_assert_true((snapshot.get("interaction_state") as Dictionary).has("escape_material_ids"), "snapshot records interaction state")
		var resource_nodes: Array = ((snapshot.get("interaction_state") as Dictionary).get("resource_nodes", []) as Array)
		_assert_equal(resource_nodes.size(), 3, "snapshot records all basement resource nodes")
		_assert_equal(String((resource_nodes[0] as Dictionary).get("entity_id", "")), "basement_ration_01", "resource snapshots are sorted by stable id")
		var campfire_snapshots: Array = ((snapshot.get("interaction_state") as Dictionary).get("campfires", []) as Array)
		_assert_equal(campfire_snapshots.size(), 1, "snapshot records the campfire runtime state")
		_assert_true(bool((campfire_snapshots[0] as Dictionary).get("lit", false)), "snapshot records the lit campfire")
		var torch_snapshots: Array = ((snapshot.get("interaction_state") as Dictionary).get("torches", []) as Array)
		_assert_equal(torch_snapshots.size(), 1, "snapshot records the torch runtime state")
		var building_snapshots: Array = ((snapshot.get("building_state") as Dictionary).get("entities", []) as Array)
		_assert_equal(building_snapshots.size(), 2, "snapshot records placed building entities")
		var location_state: Dictionary = snapshot.get("run_session_state") as Dictionary
		_assert_equal(location_state.get("scene_id", StringName()), StringName("basement"), "snapshot records scene id")
		_assert_equal(location_state.get("scene_path", ""), "res://scenes/world/basement/basement.tscn", "snapshot records scene path")
		_assert_equal(location_state.get("spawn_point_name", StringName()), StringName("PlayerSpawn"), "snapshot records spawn point")
		_assert_equal(GameManager.get_resume_scene_id(), StringName("basement"), "resume getter exposes scene id")
		_assert_equal(GameManager.get_resume_scene_path(), "res://scenes/world/basement/basement.tscn", "resume getter exposes scene path")
		_assert_equal(GameManager.get_resume_spawn_point_name(), StringName("PlayerSpawn"), "resume getter exposes spawn point")
	_assert_true(GameManager.save_safe_exit(snapshot), "complete runtime snapshot saves")
	var next_random_value: int = GameManager.random_int(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_TERRAIN, 0, 1000000)
	var expected_player_position: Vector2 = player.global_position
	var expected_player_health: float = float(player_health.call("get_health"))
	var expected_enemy_health: float = float(enemy_health.call("get_health"))
	var expected_hunger: float = GameManager.get_hunger()
	var expected_event_index: int = int((snapshot.get("random_stream_state") as Dictionary).get("streams", [])[0].get("event_index", -1))
	basement.queue_free()
	await get_tree().process_frame
	_assert_true(GameManager.reset_run(), "reset clears runtime memory without deleting save")
	var save_service: RefCounted = GameManager.get("_run_save") as RefCounted
	var loaded_snapshot: RefCounted = save_service.call("load_latest") as RefCounted
	var legacy_snapshot: RefCounted = RUN_SNAPSHOT_DATA_SCRIPT.new()
	_assert_true(bool(legacy_snapshot.call("from_dictionary", loaded_snapshot.call("to_dictionary"))), "legacy snapshot copy can be created")
	var legacy_session_state: Dictionary = legacy_snapshot.get("run_session_state") as Dictionary
	legacy_session_state.erase("scene_id")
	legacy_session_state.erase("scene_path")
	legacy_session_state.erase("spawn_point_name")
	legacy_snapshot.set("run_session_state", legacy_session_state)
	_assert_true(bool(GameManager.call("_restore_run_snapshot", legacy_snapshot)), "legacy snapshot without location metadata restores")
	_assert_equal(GameManager.get_resume_scene_id(), StringName("basement"), "legacy snapshot derives scene id from floor")
	_assert_equal(GameManager.get_resume_scene_path(), "res://scenes/world/basement/basement.tscn", "legacy snapshot derives scene path from floor")
	_assert_equal(GameManager.get_resume_spawn_point_name(), StringName("PlayerSpawn"), "legacy snapshot derives spawn point from floor")
	_assert_true(GameManager.reset_run(), "reset after legacy snapshot restore")
	var partial_legacy_snapshot: RefCounted = RUN_SNAPSHOT_DATA_SCRIPT.new()
	_assert_true(bool(partial_legacy_snapshot.call("from_dictionary", loaded_snapshot.call("to_dictionary"))), "partial legacy snapshot copy can be created")
	var partial_session_state: Dictionary = partial_legacy_snapshot.get("run_session_state") as Dictionary
	partial_session_state.erase("scene_path")
	partial_legacy_snapshot.set("run_session_state", partial_session_state)
	_assert_true(not bool(GameManager.call("_restore_run_snapshot", partial_legacy_snapshot)), "partial location metadata remains rejected")
	var restored_direct: bool = bool(GameManager.call("_restore_run_snapshot", loaded_snapshot))
	_assert_true(restored_direct, "safe-exit snapshot restores runtime models")
	_assert_equal(int(Inventory.get_selected_container_snapshot().get("amount", 0)), 1, "filled container contents survive restore")
	_assert_true(bool(GameManager.get("_pending_scene_state").get("interaction_state", {}).get("campfires", [])[0].get("lit", false)), "pending restore keeps campfire ignition state")
	var pending_before_scene_match: Dictionary = (GameManager.get("_pending_scene_state") as Dictionary).duplicate(true)
	_assert_true(pending_before_scene_match.has("run_session_state"), "pending scene state carries location metadata")
	var pending_session_state: Dictionary = pending_before_scene_match.get("run_session_state", {}) as Dictionary
	_assert_equal(pending_session_state.get("scene_id", StringName()), StringName("basement"), "pending scene state carries scene id")
	_assert_equal(pending_session_state.get("scene_path", ""), "res://scenes/world/basement/basement.tscn", "pending scene state carries scene path")
	_assert_equal(pending_session_state.get("spawn_point_name", StringName()), StringName("PlayerSpawn"), "pending scene state carries spawn point")
	var pending_for_location_match: Dictionary = pending_before_scene_match.duplicate(true)
	pending_for_location_match["enemy_state"] = {"entities": []}
	GameManager.set("_pending_scene_state", pending_for_location_match)
	var wrong_scene: Node = CIHANG_SCENE.instantiate()
	_assert_true(not GameManager.register_runtime_scene(wrong_scene), "wrong runtime scene registration is rejected")
	_assert_equal(GameManager.get_resume_scene_path(), "res://scenes/world/basement/basement.tscn", "wrong registration keeps resume location")
	_assert_true(not GameManager.apply_pending_scene_state(wrong_scene), "wrong scene rejects pending state")
	_assert_true(not (GameManager.get("_pending_scene_state") as Dictionary).is_empty(), "wrong scene leaves pending state untouched")
	var correct_scene: Node = BASEMENT_SCENE.instantiate()
	_assert_equal(String(correct_scene.scene_file_path), "res://scenes/world/basement/basement.tscn", "correct scene exposes source path")
	add_child(correct_scene)
	_assert_true(GameManager.apply_pending_scene_state(correct_scene), "correct scene applies pending state")
	_assert_true((GameManager.get("_pending_scene_state") as Dictionary).is_empty(), "correct scene clears pending state")
	wrong_scene.free()
	correct_scene.free()
	GameManager.set("_pending_scene_state", pending_before_scene_match)
	var invalid_spawn_state: Dictionary = (loaded_snapshot.get("run_session_state") as Dictionary).duplicate(true)
	invalid_spawn_state["spawn_point_name"] = StringName("NotARealSpawn")
	loaded_snapshot.set("run_session_state", invalid_spawn_state)
	var invalid_spawn_save_service := RecordingSaveService.new()
	invalid_spawn_save_service.latest_snapshot = loaded_snapshot
	GameManager.set("_run_save", invalid_spawn_save_service)
	_assert_true(GameManager.reset_run(), "reset before invalid spawn restore")
	_assert_true(not GameManager.restore_safe_exit(), "invalid spawn point is rejected")
	_assert_equal(GameManager.get_run_state(), 0, "invalid spawn restore keeps the run idle")
	GameManager.set("_run_save", save_service)
	_assert_true(GameManager.restore_safe_exit(), "valid snapshot restores after invalid spawn rejection")
	_assert_true(not GameManager.restore_safe_exit(), "duplicate restore is rejected while a run is active")
	var invalid_snapshot: RefCounted = loaded_snapshot
	invalid_snapshot.set("interaction_state", {"escape_material_ids": "invalid"})
	_assert_true(not bool(GameManager.call("_restore_run_snapshot", invalid_snapshot)), "invalid interaction section is rejected")
	_assert_equal(GameManager.get_run_state(), 2, "invalid restore keeps the active run state unchanged")
	_assert_true(is_equal_approx(GameManager.get_hunger(), expected_hunger), "restore keeps survival vitals")
	_assert_equal(GameManager.get_random_event_index(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_TERRAIN), expected_event_index, "restore keeps random stream position")
	var restored_basement: Node = BASEMENT_SCENE.instantiate()
	add_child(restored_basement)
	await get_tree().process_frame
	await get_tree().process_frame
	var restored_player: Node2D = restored_basement.get_node("Player") as Node2D
	var restored_enemy: Node2D = restored_basement.get_node("ContentRoot/EncounterEntity1") as Node2D
	_assert_equal(restored_player.global_position, expected_player_position, "restore applies player position")
	_assert_equal(float((restored_player.get_node("HealthComponent") as Node).call("get_health")), expected_player_health, "restore applies player health")
	_assert_equal(float((restored_enemy.get_node("HealthComponent") as Node).call("get_health")), expected_enemy_health, "restore applies enemy health")
	_assert_equal(GameManager.random_int(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_TERRAIN, 0, 1000000), next_random_value, "restored random stream produces the same next value")
	_assert_true(restored_basement.get_node_or_null("EscapeParts0") == null, "restored interaction removes collected material pickup")
	_assert_true(GameManager.pause_run(), "restored run can be paused before a second save")
	_assert_true(GameManager.save_safe_exit(), "paused run can be saved safely")
	_assert_true(GameManager.reset_run(), "paused run memory can be reset")
	_assert_true(GameManager.restore_safe_exit(), "paused run can be restored")
	_assert_equal(GameManager.get_run_state(), 7, "paused state survives safe-exit restore")
	_assert_true(get_tree().paused, "restored paused run pauses the scene tree")
	_assert_true(GameManager.resume_run(), "restored paused run can resume")
	_assert_true(GameManager.complete_objective(), "floor can complete before boundary save")
	_assert_true(GameManager.clear_floor(), "floor can clear before boundary save")
	for material_type: int in range(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MATERIAL_TYPE_COUNT):
		_assert_true(
			GameManager.collect_escape_material(material_type, GameManager.get_escape_material_required(material_type)),
			"boundary setup collects material %d" % material_type
		)
	_assert_true(GameManager.advance_escape_exit(10.0, false, false, false), "boundary setup starts exit")
	var original_save_service: RefCounted = GameManager.get("_run_save") as RefCounted
	var failing_save_service := RecordingSaveService.new()
	failing_save_service.boundary_should_succeed = false
	GameManager.set("_run_save", failing_save_service)
	var floor_before_failure: int = GameManager.get_floor_number()
	var state_before_failure: int = GameManager.get_run_state()
	var startup_before_failure: float = GameManager.get_escape_startup_seconds()
	_assert_true(not GameManager.depart_floor(), "boundary save failure blocks departure")
	_assert_equal(GameManager.get_floor_number(), floor_before_failure, "boundary failure keeps floor")
	_assert_equal(GameManager.get_run_state(), state_before_failure, "boundary failure keeps run state")
	_assert_equal(GameManager.get_escape_startup_seconds(), startup_before_failure, "boundary failure keeps exit startup")
	var recording_save_service := RecordingSaveService.new()
	GameManager.set("_run_save", recording_save_service)
	_assert_true(GameManager.depart_floor(), "successful boundary save allows departure")
	_assert_equal(recording_save_service.boundary_calls, 1, "departure saves one floor boundary")
	if recording_save_service.last_boundary_snapshot != null:
		var boundary_session_state: Dictionary = recording_save_service.last_boundary_snapshot.get("run_session_state") as Dictionary
		_assert_equal(boundary_session_state.get("floor_number", 0), 1, "boundary snapshot captures old floor")
		_assert_equal(boundary_session_state.get("state", -1), 4, "boundary snapshot captures floor-clear state")
	GameManager.set("_run_save", original_save_service)
	_assert_equal(GameManager.get_floor_number(), 2, "departure advances to next floor")
	_assert_true(GameManager.prepare_floor(), "final floor enters exploration")
	_assert_true(GameManager.complete_objective(), "final floor objective completes")
	_assert_true(GameManager.clear_floor(), "final floor clears")
	for material_type: int in range(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MATERIAL_TYPE_COUNT):
		_assert_true(
			GameManager.collect_escape_material(material_type, GameManager.get_escape_material_required(material_type)),
			"final floor setup collects material %d" % material_type
		)
	_assert_true(GameManager.advance_escape_exit(10.0, false, false, false), "final floor exit starts")
	var final_floor_before: int = GameManager.get_floor_number()
	var final_state_before: int = GameManager.get_run_state()
	var final_startup_before: float = GameManager.get_escape_startup_seconds()
	var final_materials_before: Array[int] = []
	for material_type: int in range(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MATERIAL_TYPE_COUNT):
		final_materials_before.append(GameManager.get_escape_material_collected(material_type))
	var final_save_service := RecordingSaveService.new()
	GameManager.set("_run_save", final_save_service)
	_assert_true(not GameManager.depart_floor(), "final floor departure is rejected")
	_assert_equal(final_save_service.boundary_calls, 0, "final floor departure does not save a boundary")
	_assert_equal(GameManager.get_floor_number(), final_floor_before, "final departure keeps floor")
	_assert_equal(GameManager.get_run_state(), final_state_before, "final departure keeps run state")
	_assert_equal(GameManager.get_escape_startup_seconds(), final_startup_before, "final departure keeps exit startup")
	for material_type: int in range(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MATERIAL_TYPE_COUNT):
		_assert_equal(
			GameManager.get_escape_material_collected(material_type),
			final_materials_before[material_type],
			"final departure keeps material %d" % material_type
		)
	if _failures == 0:
		print("Run save integration test passed")
	else:
		push_error("Run save integration test failed: %d assertion(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	_assert_true(actual == expected, "%s (actual=%s, expected=%s)" % [message, actual, expected])
