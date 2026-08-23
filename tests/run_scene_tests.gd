extends Node

const BASEMENT_SCENE: PackedScene = preload("res://scenes/world/basement/basement.tscn")
const CIHANG_SCENE: PackedScene = preload("res://scenes/world/cihang_outskirts/cihang_outskirts.tscn")
const PICKUP_OVERLAP_SCENE: PackedScene = preload("res://tests/pickup_overlap_test.tscn")
const CONTENT_VALIDATION_MODEL_SCRIPT: Script = preload("res://scripts/data/content_validation_model.gd")

var _failures: int = 0


func _init() -> void:
	call_deferred("_run_scene_tests")


func _run_scene_tests() -> void:
	var basement: Node = BASEMENT_SCENE.instantiate()
	add_child(basement)
	await get_tree().process_frame
	await get_tree().process_frame
	var area_config: Resource = basement.get("area_config") as Resource
	_assert_equal(
		area_config.resource_path,
		"res://assets/areas/basement_area.tres",
		"basement consumes an external area content resource"
	)
	var content_validator: RefCounted = CONTENT_VALIDATION_MODEL_SCRIPT.new()
	_assert_equal(
		content_validator.call("validate_area", area_config).size(),
		0,
		"basement external area content satisfies the framework contract"
	)
	_assert_true(basement.get_node_or_null("Player") != null, "basement instantiates a player")
	var encounter_controller: Node = basement.get_node("EncounterController")
	_assert_true(encounter_controller != null, "basement instantiates an encounter controller")
	_assert_equal(int(encounter_controller.call("get_target_count")), 2, "configured encounter has two generated targets")
	_assert_true(basement.get_node_or_null("ContentRoot/EncounterEntity0") != null, "encounter generates the first entity")
	_assert_true(basement.get_node_or_null("ContentRoot/EncounterEntity1") != null, "encounter generates the second entity")
	var objective_label: Label = basement.get_node("ObjectiveHUD/ObjectiveLabel") as Label
	_assert_true(objective_label.text.contains("0/2"), "basement starts with two incomplete objectives")
	var transition_zone: Node = basement.get_node("TransitionZone")
	_assert_true(bool(transition_zone.get("requires_objective_complete")), "basement exit requires objective completion")
	var player: Node2D = basement.get_node("Player") as Node2D
	_assert_true(player.get_node_or_null("Presenter") != null, "player exposes a replaceable presenter boundary")
	var stone_sword: Node2D = basement.get_node("StoneSword") as Node2D
	_assert_equal((stone_sword as Area2D).collision_mask, 1, "world item scans the player collision layer")
	_assert_equal((player as CharacterBody2D).collision_layer, 1, "player belongs to the interactable collision layer")
	_assert_true((stone_sword as Area2D).monitoring, "world item overlap monitoring is enabled")
	_assert_true(not bool(player.get_node("CollisionShape2D").get("disabled")), "player collision shape is enabled")
	_assert_true(not bool(stone_sword.get_node("CollisionShape2D").get("disabled")), "world item collision shape is enabled")
	Input.action_press(&"move_right")
	Input.action_press(&"move_up")
	for _frame in range(52):
		await get_tree().physics_frame
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	await get_tree().physics_frame
	_assert_true((stone_sword as Area2D).get_overlapping_bodies().has(player), "world item physics query sees the overlapping player")
	_assert_true(bool(stone_sword.get("_player_nearby")), "world item detects an overlapping player")
	await _press_interact_key(stone_sword)
	_assert_true(not is_instance_valid(stone_sword), "pressing interact while overlapping picks up the world item")
	var picked_item: ItemData = Inventory.get_selected_item()
	_assert_true(picked_item != null and picked_item.id == &"stone_sword", "picked item enters the selected inventory slot")
	Input.action_press(&"drop")
	await get_tree().physics_frame
	Input.action_release(&"drop")
	await get_tree().physics_frame
	var dropped_sword: Node2D = get_node_or_null("ItemWorld") as Node2D
	_assert_true(dropped_sword != null, "dropping the selected item creates a world item")
	await _press_interact_key(dropped_sword)
	_assert_true(not is_instance_valid(dropped_sword), "a world item dropped under the player can be picked up without moving away")
	picked_item = Inventory.get_selected_item()
	_assert_true(picked_item != null and picked_item.id == &"stone_sword", "re-picked dropped item returns to inventory")
	var player_health: Node = player.get_node("HealthComponent")
	var enemy: Node2D = basement.get_node("ContentRoot/EncounterEntity1") as Node2D
	_assert_true(enemy.get_node_or_null("Presenter") != null, "enemy exposes a replaceable presenter boundary")
	var enemy_health: Node = basement.get_node("ContentRoot/EncounterEntity1/HealthComponent")
	enemy.global_position = player.global_position + Vector2(42.0, 0.0)
	var enemy_health_before_attack: float = float(enemy_health.call("get_health"))
	Input.action_press(&"attack")
	await get_tree().physics_frame
	Input.action_release(&"attack")
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(0.12).timeout
	_assert_true(float(enemy_health.call("get_health")) < enemy_health_before_attack, "player attack damages an enemy without a pickup prerequisite")
	enemy.global_position = player.global_position + Vector2(70.0, 0.0)
	var health_before_contact: float = float(player_health.call("get_health"))
	await get_tree().create_timer(1.5).timeout
	_assert_true(float(player_health.call("get_health")) < health_before_contact, "chaser enemy deals contact damage after closing from a real distance")
	var dummy_health: Node = basement.get_node("ContentRoot/EncounterEntity0/HealthComponent")
	dummy_health.call("take_damage", 1000.0)
	enemy_health.call("take_damage", 1000.0)
	await get_tree().process_frame
	_assert_true(GameManager.is_objective_complete(), "defeating both enemies completes the objective")
	_assert_true(objective_label.text.contains("2/2"), "objective HUD shows both enemies defeated")
	_assert_true(objective_label.text.contains("选择强化"), "completed objective asks for a reward before exit")
	var reward_selection: Node = basement.get_node("RewardSelection")
	_assert_true(bool(reward_selection.get("visible")), "objective completion opens reward selection")
	_assert_true(not GameManager.is_floor_clear(), "area remains uncleared before reward selection")
	transition_zone.call("_on_body_entered", player)
	await get_tree().process_frame
	_assert_true(basement.is_inside_tree(), "exit remains locked before reward selection")
	_assert_true(not bool(reward_selection.call("choose_upgrade", &"unknown")), "unknown reward choice is rejected")
	_assert_true(bool(reward_selection.call("choose_upgrade", &"damage")), "valid reward choice is accepted")
	_assert_true(not bool(reward_selection.get("visible")), "reward selection closes after a valid choice")
	_assert_true(GameManager.is_floor_clear(), "valid reward choice clears the area")
	_assert_true(objective_label.text.contains("可前往出口"), "cleared area HUD unlocks the exit")
	_assert_equal(GameManager.get_run_damage_multiplier(), 1.2, "damage reward changes the run multiplier")
	_assert_true(not bool(reward_selection.call("choose_upgrade", &"damage")), "duplicate reward choice is rejected")
	_assert_true(GameManager.start_next_floor(), "cleared area can start the next area")
	_assert_true(GameManager.prepare_floor(), "next area can enter exploration")
	_assert_true(GameManager.complete_objective(), "next area objective can complete")
	var move_upgrade: Resource = reward_selection.get("move_speed_upgrade") as Resource
	_assert_true(GameManager.apply_run_upgrade(move_upgrade), "next area accepts a new reward choice")
	_assert_equal(GameManager.get_run_damage_multiplier(), 1.2, "previous area damage upgrade persists")
	_assert_equal(GameManager.get_run_move_speed_multiplier(), 1.15, "next area movement upgrade is applied")
	_assert_equal(GameManager.get_run_xp(), 0, "xp threshold is consumed by the level-up")
	_assert_equal(GameManager.get_run_level(), 2, "enemy defeats grant a level")
	GameManager.add_run_xp(30)
	basement.queue_free()
	await get_tree().process_frame
	var cihang: Node = CIHANG_SCENE.instantiate()
	add_child(cihang)
	await get_tree().process_frame
	_assert_equal(GameManager.get_run_xp(), 30, "run xp persists after changing world scenes")
	_assert_equal(GameManager.get_run_level(), 2, "run level persists after changing world scenes")
	var cihang_player_health: Node = cihang.get_node("Player/HealthComponent")
	cihang_player_health.call("take_damage", 1000.0)
	await get_tree().process_frame
	_assert_true(GameManager.is_run_dead(), "player death updates the run session")
	_assert_true(GameManager.revive(), "dead run session can revive")
	_assert_true(GameManager.is_objective_complete(), "revive restores the pre-death objective state")
	_assert_true(GameManager.reset_run(), "completed run state can be reset")
	_assert_true(GameManager.is_run_idle(), "run reset returns the session to idle")
	_assert_equal(GameManager.get_run_xp(), 0, "run reset clears persistent xp")
	_assert_equal(GameManager.get_run_level(), 1, "run reset restores level one")
	_assert_equal(GameManager.get_run_damage_multiplier(), 1.0, "run reset clears damage upgrades")
	_assert_equal(GameManager.get_run_move_speed_multiplier(), 1.0, "run reset clears movement upgrades")
	var pickup_overlap: Node = PICKUP_OVERLAP_SCENE.instantiate()
	add_child(pickup_overlap)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var initially_overlapping_item: Node2D = pickup_overlap.get_node("StoneSword") as Node2D
	_assert_true((initially_overlapping_item as Area2D).get_overlapping_bodies().size() > 0, "initial-overlap pickup scene has a physics overlap")
	await _press_interact_key(initially_overlapping_item)
	_assert_true(not is_instance_valid(initially_overlapping_item), "an initially overlapping world item can be picked up")
	if _failures == 0:
		print("Scene tests passed")
	else:
		push_error("Scene tests failed: %d assertion(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	_assert_true(actual == expected, "%s (actual=%s, expected=%s)" % [message, actual, expected])


func _press_interact_key(target: Node) -> void:
	var press_event := InputEventKey.new()
	press_event.keycode = KEY_E
	press_event.physical_keycode = KEY_E
	press_event.pressed = true
	_assert_true(press_event.is_action_pressed(&"interact"), "physical E event maps to interact")
	target.call("_input", press_event)
	await get_tree().process_frame
