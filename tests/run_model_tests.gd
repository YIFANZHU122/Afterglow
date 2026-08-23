extends SceneTree

const HEALTH_MODEL_SCRIPT: Script = preload("res://scripts/combat/health_model.gd")
const STAMINA_MODEL_SCRIPT: Script = preload("res://scripts/player/stamina_model.gd")
const PLAYER_COMMAND_SCRIPT: Script = preload("res://scripts/player/player_command.gd")
const INVENTORY_MODEL_SCRIPT: Script = preload("res://scripts/items/inventory_model.gd")
const MELEE_ATTACK_MODEL_SCRIPT: Script = preload("res://scripts/combat/melee_attack_model.gd")
const REVIVE_MODEL_SCRIPT: Script = preload("res://scripts/progression/revive_model.gd")
const ITEM_DATA_SCRIPT: Script = preload("res://scripts/item_data.gd")
const RUN_SESSION_MODEL_SCRIPT: Script = preload("res://scripts/core/run_session_model.gd")
const OBJECTIVE_PROGRESS_MODEL_SCRIPT: Script = preload("res://scripts/world/objective_progress_model.gd")
const RUN_REWARD_MODEL_SCRIPT: Script = preload("res://scripts/progression/run_reward_model.gd")
const ENCOUNTER_SPAWN_DEFINITION_SCRIPT: Script = preload("res://scripts/data/encounter_spawn_definition.gd")
const ENCOUNTER_DEFINITION_SCRIPT: Script = preload("res://scripts/data/encounter_definition.gd")
const AREA_DEFINITION_SCRIPT: Script = preload("res://scripts/data/area_definition.gd")
const UPGRADE_DEFINITION_SCRIPT: Script = preload("res://scripts/data/upgrade_definition.gd")
const RUN_BUILD_MODEL_SCRIPT: Script = preload("res://scripts/progression/run_build_model.gd")
const CONTENT_VALIDATION_MODEL_SCRIPT: Script = preload("res://scripts/data/content_validation_model.gd")

const MOVE_STATE_WALKING: int = 0
const MOVE_STATE_RUNNING: int = 1
const MOVE_STATE_EXHAUSTED: int = 2
const RUN_STATE_IDLE: int = 0
const RUN_STATE_PREPARING_FLOOR: int = 1
const RUN_STATE_EXPLORING: int = 2
const RUN_STATE_OBJECTIVE_COMPLETE: int = 3
const RUN_STATE_FLOOR_CLEAR: int = 4
const RUN_STATE_DEAD: int = 5
const RUN_STATE_RUN_ENDED: int = 6

var _failures: int = 0


func _init() -> void:
	_run_health_model_tests()
	_run_stamina_model_tests()
	_run_player_command_tests()
	_run_inventory_model_tests()
	_run_melee_attack_model_tests()
	_run_revive_model_tests()
	_run_session_model_tests()
	_run_objective_progress_model_tests()
	_run_run_reward_model_tests()
	_run_content_definition_tests()
	_run_run_build_model_tests()
	_run_content_validation_model_tests()
	if _failures == 0:
		print("Model tests passed")
	else:
		push_error("Model tests failed: %d assertion(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	_assert_true(actual == expected, "%s (actual=%s, expected=%s)" % [message, actual, expected])


func _run_health_model_tests() -> void:
	var clamped_model = HEALTH_MODEL_SCRIPT.new(-25.0)
	_assert_equal(clamped_model.get_max_health(), 0.0, "negative max health is clamped")
	clamped_model.take_damage(1.0)
	_assert_true(clamped_model.is_dead(), "zero-capacity health becomes dead on damage")
	var model = HEALTH_MODEL_SCRIPT.new(100.0)
	_assert_equal(model.get_health(), 100.0, "health starts full")
	model.take_damage(25.0)
	_assert_equal(model.get_health(), 75.0, "positive damage reduces health")
	model.take_damage(-10.0)
	_assert_equal(model.get_health(), 75.0, "negative damage is rejected")
	model.heal(10.0)
	_assert_equal(model.get_health(), 85.0, "positive healing restores health")
	model.heal(-10.0)
	_assert_equal(model.get_health(), 85.0, "negative healing is rejected")
	model.take_damage(1000.0)
	_assert_true(model.is_dead(), "lethal damage marks the model dead")
	model.heal(10.0)
	_assert_equal(model.get_health(), 0.0, "dead model cannot be healed")
	model.take_damage(10.0)
	_assert_equal(model.get_health(), 0.0, "dead model ignores repeated damage")
	model.reset()
	_assert_true(not model.is_dead(), "reset clears the dead state")
	_assert_equal(model.get_health(), 100.0, "reset restores full health")


func _run_stamina_model_tests() -> void:
	var model = STAMINA_MODEL_SCRIPT.new(100.0, 30.0, 15.0)
	_assert_equal(model.get_state(), MOVE_STATE_WALKING, "stamina starts walking")
	model.tick(1.0, Vector2.RIGHT, true)
	_assert_equal(model.get_state(), MOVE_STATE_RUNNING, "sprint request enters running")
	_assert_equal(model.get_stamina(), 100.0, "entering running preserves the current frame stamina")
	model.tick(1.0, Vector2.RIGHT, true)
	_assert_equal(model.get_stamina(), 70.0, "running drains stamina")
	model.tick(3.0, Vector2.RIGHT, true)
	_assert_equal(model.get_state(), MOVE_STATE_EXHAUSTED, "empty stamina enters exhausted")
	_assert_equal(model.get_stamina(), 0.0, "stamina is clamped at zero")
	model.tick(1.0, Vector2.ZERO, false)
	_assert_equal(model.get_stamina(), 15.0, "exhausted state regenerates stamina")
	model.tick(1.0, Vector2.ZERO, false)
	_assert_equal(model.get_state(), MOVE_STATE_WALKING, "reaching the threshold leaves exhaustion")
	model.tick(-1.0, Vector2.RIGHT, true)
	_assert_equal(model.get_stamina(), 30.0, "negative delta is ignored")
	var zero_model = STAMINA_MODEL_SCRIPT.new(0.0, 30.0, 15.0)
	zero_model.tick(1.0, Vector2.RIGHT, true)
	_assert_equal(zero_model.get_stamina(), 0.0, "zero-capacity stamina stays at zero")


func _run_player_command_tests() -> void:
	var command = PLAYER_COMMAND_SCRIPT.new()
	_assert_equal(command.move_direction, Vector2.ZERO, "command defaults to no movement")
	_assert_true(not command.sprint_requested, "command defaults to no sprint")
	_assert_true(not command.attack_pressed, "command defaults to no attack")
	_assert_equal(command.cycle_delta, 0, "command defaults to no slot cycling")
	_assert_equal(command.selected_slot, -1, "command defaults to no direct slot selection")
	_assert_true(not command.drop_pressed, "command defaults to no drop")

	var populated = PLAYER_COMMAND_SCRIPT.new(Vector2.RIGHT, true, true, -1, 4, true)
	_assert_equal(populated.move_direction, Vector2.RIGHT, "command stores movement intent")
	_assert_true(populated.sprint_requested, "command stores sprint intent")
	_assert_true(populated.attack_pressed, "command stores attack edge")
	_assert_equal(populated.cycle_delta, -1, "command stores previous-slot intent")
	_assert_equal(populated.selected_slot, 4, "command stores direct slot intent")
	_assert_true(populated.drop_pressed, "command stores drop edge")

	var clamped = PLAYER_COMMAND_SCRIPT.new(Vector2(2.0, 0.0), false, false, 8, -5, false)
	_assert_equal(clamped.move_direction, Vector2.RIGHT, "command clamps movement length")
	_assert_equal(clamped.cycle_delta, 1, "command clamps slot cycling to one step")
	_assert_equal(clamped.selected_slot, -1, "command rejects negative slot selection")


func _run_inventory_model_tests() -> void:
	var model = INVENTORY_MODEL_SCRIPT.new(2)
	var sword = ITEM_DATA_SCRIPT.new()
	sword.item_type = 1
	sword.attack_damage = 10.0
	_assert_true(model.add_item(sword), "inventory accepts the first item")
	_assert_equal(model.get_selected_item(), sword, "inventory exposes selected item")
	_assert_true(not model.set_selected_slot(-1), "inventory rejects negative slot")
	_assert_true(model.set_selected_slot(1), "inventory selects a valid slot")
	_assert_true(model.add_item(sword), "inventory accepts the second item")
	_assert_true(not model.add_item(sword), "full inventory rejects another item")
	_assert_true(model.cycle_selected(-1), "inventory cycles selected slot")
	_assert_equal(model.get_selected_slot(), 0, "inventory cycle wraps to first slot")
	_assert_equal(model.drop_selected(), sword, "inventory drops selected item")
	_assert_equal(model.drop_selected(), null, "empty selected slot returns null")
	var dropped: Array = model.drop_all()
	_assert_equal(dropped.size(), 1, "drop_all returns remaining items")
	_assert_equal(model.get_items()[0], null, "drop_all clears all slots")


func _run_melee_attack_model_tests() -> void:
	var model = MELEE_ATTACK_MODEL_SCRIPT.new()
	var empty_item = null
	_assert_true(not model.can_attack(empty_item), "melee rejects empty item")
	var potion = ITEM_DATA_SCRIPT.new()
	potion.item_type = 2
	potion.attack_damage = 20.0
	_assert_true(not model.can_attack(potion), "melee rejects non-sword item")
	var zero_sword = ITEM_DATA_SCRIPT.new()
	zero_sword.item_type = 1
	_assert_true(not model.can_attack(zero_sword), "melee rejects zero damage sword")
	var sword = ITEM_DATA_SCRIPT.new()
	sword.item_type = 1
	sword.attack_damage = 20.0
	_assert_true(model.can_attack(sword), "melee accepts positive damage sword")
	_assert_equal(model.get_damage(sword), 20.0, "melee returns sword damage")


func _run_revive_model_tests() -> void:
	var model = REVIVE_MODEL_SCRIPT.new()
	_assert_true(model.is_alive(), "revive model starts alive")
	_assert_true(not model.request(), "alive model rejects revive request")
	_assert_true(model.mark_dead(), "alive model can become dead")
	_assert_true(not model.mark_dead(), "dead model rejects repeated death")
	_assert_true(model.request(), "dead model enters revive wait")
	_assert_true(not model.request(), "waiting model rejects duplicate request")
	_assert_true(model.complete(), "waiting model completes revive")
	_assert_true(model.is_alive(), "completed revive returns to alive")
	_assert_true(not model.complete(), "alive model rejects repeated completion")


func _run_session_model_tests() -> void:
	var model = RUN_SESSION_MODEL_SCRIPT.new()
	_assert_equal(model.get_state(), RUN_STATE_IDLE, "run session starts idle")
	_assert_equal(model.get_floor_number(), 0, "run session starts without a floor")
	_assert_true(not model.prepare_floor(), "idle session rejects preparing a floor")
	_assert_true(model.start_run(), "idle session starts a run")
	_assert_equal(model.get_state(), RUN_STATE_PREPARING_FLOOR, "starting a run prepares the first floor")
	_assert_equal(model.get_floor_number(), 1, "starting a run selects floor one")
	_assert_true(not model.start_run(), "preparing session rejects duplicate start")
	_assert_true(model.prepare_floor(), "preparing session enters exploration")
	_assert_equal(model.get_state(), RUN_STATE_EXPLORING, "prepared floor is explorable")
	_assert_true(not model.clear_floor(), "exploring session cannot clear a floor early")
	_assert_true(model.complete_objective(), "exploring session completes its objective")
	_assert_equal(model.get_state(), RUN_STATE_OBJECTIVE_COMPLETE, "objective completion is visible")
	_assert_true(model.clear_floor(), "completed objective clears the floor")
	_assert_equal(model.get_state(), RUN_STATE_FLOOR_CLEAR, "cleared floor enters floor-clear state")
	_assert_true(model.start_next_floor(), "cleared floor starts the next floor")
	_assert_equal(model.get_floor_number(), 2, "next floor increments the floor number")
	_assert_equal(model.get_state(), RUN_STATE_PREPARING_FLOOR, "next floor requires preparation")
	_assert_true(model.prepare_floor(), "second floor can be prepared")
	_assert_true(model.mark_dead(), "active run can enter dead state")
	_assert_equal(model.get_state(), RUN_STATE_DEAD, "death state is visible")
	_assert_true(not model.mark_dead(), "dead session rejects repeated death")
	_assert_true(model.revive(), "dead session can return to exploration")
	_assert_equal(model.get_state(), RUN_STATE_EXPLORING, "revive returns the run to exploration")
	_assert_true(not model.revive(), "active session rejects repeated revive")
	_assert_true(model.mark_dead(), "revived session can die again")
	_assert_true(model.end_run(), "dead session can end the run")
	_assert_equal(model.get_state(), RUN_STATE_RUN_ENDED, "ended run is terminal")
	_assert_true(not model.start_run(), "ended run rejects starting without reset")
	_assert_true(model.reset(), "reset returns the session to idle")
	_assert_equal(model.get_state(), RUN_STATE_IDLE, "reset clears the run state")
	_assert_equal(model.get_floor_number(), 0, "reset clears the floor number")
	var completed_model = RUN_SESSION_MODEL_SCRIPT.new()
	completed_model.start_run()
	completed_model.prepare_floor()
	completed_model.complete_objective()
	_assert_true(completed_model.mark_dead(), "completed objective can enter death state")
	_assert_true(completed_model.revive(), "completed objective can be restored after death")
	_assert_equal(completed_model.get_state(), RUN_STATE_OBJECTIVE_COMPLETE, "revive restores the pre-death state")


func _run_objective_progress_model_tests() -> void:
	var empty_model = OBJECTIVE_PROGRESS_MODEL_SCRIPT.new(-2)
	_assert_equal(empty_model.get_target_count(), 0, "negative objective count is clamped")
	_assert_true(empty_model.is_complete(), "zero-target objective starts complete")
	_assert_true(not empty_model.register_completion(), "completed empty objective rejects progress")

	var model = OBJECTIVE_PROGRESS_MODEL_SCRIPT.new(2)
	_assert_equal(model.get_completed_count(), 0, "objective starts with no completed targets")
	_assert_true(not model.is_complete(), "objective with targets starts incomplete")
	_assert_true(model.register_completion(), "objective accepts the first completion")
	_assert_equal(model.get_completed_count(), 1, "objective tracks one completion")
	_assert_true(not model.is_complete(), "objective remains incomplete before the target count")
	_assert_true(model.register_completion(), "objective accepts the final completion")
	_assert_true(model.is_complete(), "objective completes at the target count")
	_assert_true(not model.register_completion(), "objective rejects completion beyond the target count")
	_assert_equal(model.get_completed_count(), 2, "objective progress never exceeds the target count")


func _run_run_reward_model_tests() -> void:
	var model = RUN_REWARD_MODEL_SCRIPT.new(100)
	_assert_equal(model.get_level(), 1, "reward model starts at level one")
	_assert_equal(model.get_xp(), 0, "reward model starts with zero xp")
	_assert_equal(model.get_xp_to_next_level(), 100, "reward model starts with a full level threshold")
	_assert_true(not model.add_xp(0), "zero xp reward is rejected")
	_assert_true(not model.add_xp(-10), "negative xp reward is rejected")
	_assert_true(not model.add_xp(40), "partial reward does not level up")
	_assert_equal(model.get_xp(), 40, "partial reward is accumulated")
	_assert_true(model.add_xp(80), "reward crossing a threshold levels up")
	_assert_equal(model.get_level(), 2, "crossing a threshold increases the level")
	_assert_equal(model.get_xp(), 20, "level-up keeps xp overflow")
	_assert_equal(model.get_xp_to_next_level(), 80, "next threshold reflects overflow")
	_assert_true(model.add_xp(180), "large reward can cross multiple levels")
	_assert_equal(model.get_level(), 4, "large reward increments multiple levels")
	_assert_equal(model.get_xp(), 0, "exact multi-level reward has no remainder")
	var invalid_threshold = RUN_REWARD_MODEL_SCRIPT.new(0)
	_assert_true(invalid_threshold.add_xp(1), "invalid threshold is clamped to a usable value")
	_assert_equal(invalid_threshold.get_level(), 2, "one xp levels up with a one-point threshold")
	_assert_true(model.reset(), "reward reset reports changed state")
	_assert_equal(model.get_level(), 1, "reward reset restores level one")
	_assert_equal(model.get_xp(), 0, "reward reset clears xp")
	_assert_true(not model.reset(), "repeated reward reset reports no change")


func _run_content_definition_tests() -> void:
	var empty_spawn = ENCOUNTER_SPAWN_DEFINITION_SCRIPT.new()
	_assert_true(not empty_spawn.is_valid(), "spawn definition rejects an empty entity scene")
	var encounter = ENCOUNTER_DEFINITION_SCRIPT.new()
	_assert_equal(encounter.get_target_count(), 0, "empty encounter has no targets")
	var area = AREA_DEFINITION_SCRIPT.new()
	_assert_true(not area.is_valid(), "area definition rejects an empty id")
	var damage_upgrade = UPGRADE_DEFINITION_SCRIPT.new()
	damage_upgrade.id = &"damage_test"
	damage_upgrade.display_name = "伤害强化"
	damage_upgrade.effect_type = UPGRADE_DEFINITION_SCRIPT.EffectType.DAMAGE_MULTIPLIER
	damage_upgrade.amount = 0.2
	_assert_true(damage_upgrade.is_valid(), "upgrade definition accepts a positive damage modifier")


func _run_run_build_model_tests() -> void:
	var model = RUN_BUILD_MODEL_SCRIPT.new()
	_assert_equal(model.get_damage_multiplier(), 1.0, "run build starts with base damage multiplier")
	_assert_equal(model.get_move_speed_multiplier(), 1.0, "run build starts with base move speed multiplier")
	var damage_upgrade = UPGRADE_DEFINITION_SCRIPT.new()
	damage_upgrade.id = &"damage_test"
	damage_upgrade.display_name = "伤害强化"
	damage_upgrade.effect_type = UPGRADE_DEFINITION_SCRIPT.EffectType.DAMAGE_MULTIPLIER
	damage_upgrade.amount = 0.2
	_assert_true(model.apply_upgrade(damage_upgrade), "run build accepts a valid damage upgrade")
	_assert_equal(model.get_damage_multiplier(), 1.2, "damage upgrade increases damage multiplier")
	_assert_equal(model.get_upgrade_stack(&"damage_test"), 1, "run build records upgrade stack")
	_assert_true(model.apply_upgrade(damage_upgrade), "run build allows a second upgrade stack")
	_assert_equal(model.get_damage_multiplier(), 1.4, "damage upgrade stacks additively")
	var move_upgrade = UPGRADE_DEFINITION_SCRIPT.new()
	move_upgrade.id = &"move_test"
	move_upgrade.display_name = "移动强化"
	move_upgrade.effect_type = UPGRADE_DEFINITION_SCRIPT.EffectType.MOVE_SPEED_MULTIPLIER
	move_upgrade.amount = 0.15
	_assert_true(model.apply_upgrade(move_upgrade), "run build accepts a valid movement upgrade")
	_assert_equal(model.get_move_speed_multiplier(), 1.15, "movement upgrade increases move speed multiplier")
	var invalid_upgrade = UPGRADE_DEFINITION_SCRIPT.new()
	invalid_upgrade.id = &"invalid"
	invalid_upgrade.display_name = "无效强化"
	invalid_upgrade.amount = 0.0
	_assert_true(not model.apply_upgrade(invalid_upgrade), "run build rejects a non-positive modifier")
	_assert_true(model.reset(), "run build reset reports changed state")
	_assert_equal(model.get_damage_multiplier(), 1.0, "run build reset restores damage multiplier")
	_assert_equal(model.get_move_speed_multiplier(), 1.0, "run build reset restores move speed multiplier")
	_assert_equal(model.get_upgrade_stack(&"damage_test"), 0, "run build reset clears upgrade stacks")
	_assert_true(not model.reset(), "repeated run build reset reports no change")


func _run_content_validation_model_tests() -> void:
	var validator: RefCounted = CONTENT_VALIDATION_MODEL_SCRIPT.new()
	var valid_spawn: Resource = ENCOUNTER_SPAWN_DEFINITION_SCRIPT.new()
	valid_spawn.entity_scene = load("res://scenes/objects/chaser_enemy/chaser_enemy.tscn")
	_assert_equal(validator.call("validate_spawn", valid_spawn).size(), 0, "content validator accepts a valid spawn")
	_assert_true(validator.call("validate_spawn", null).size() > 0, "content validator rejects a null spawn")
	var invalid_spawn: Resource = ENCOUNTER_SPAWN_DEFINITION_SCRIPT.new()
	_assert_true(validator.call("validate_spawn", invalid_spawn).size() > 0, "content validator rejects a spawn without a scene")
	var valid_encounter: Resource = ENCOUNTER_DEFINITION_SCRIPT.new()
	var valid_spawns: Array[Resource] = [valid_spawn]
	valid_encounter.spawns = valid_spawns
	_assert_equal(validator.call("validate_encounter", valid_encounter).size(), 0, "content validator accepts a valid encounter")
	var invalid_encounter: Resource = ENCOUNTER_DEFINITION_SCRIPT.new()
	_assert_true(validator.call("validate_encounter", invalid_encounter).size() > 0, "content validator rejects an empty encounter")
	var valid_area: Resource = AREA_DEFINITION_SCRIPT.new()
	valid_area.id = &"validation_area"
	valid_area.display_name = "验证区域"
	valid_area.encounter = valid_encounter
	_assert_equal(validator.call("validate_area", valid_area).size(), 0, "content validator accepts a valid area")
	var invalid_area: Resource = AREA_DEFINITION_SCRIPT.new()
	_assert_true(validator.call("validate_area", invalid_area).size() > 0, "content validator rejects an incomplete area")
	var valid_upgrade: Resource = UPGRADE_DEFINITION_SCRIPT.new()
	valid_upgrade.id = &"validation_upgrade"
	valid_upgrade.display_name = "验证强化"
	valid_upgrade.amount = 0.1
	_assert_equal(validator.call("validate_upgrade", valid_upgrade).size(), 0, "content validator accepts a valid upgrade")
	var wrong_script: Resource = Resource.new()
	_assert_true(validator.call("validate_upgrade", wrong_script).size() > 0, "content validator rejects a resource with the wrong script")
