extends SceneTree

const HEALTH_MODEL_SCRIPT: Script = preload("res://scripts/combat/health_model.gd")
const STAMINA_MODEL_SCRIPT: Script = preload("res://scripts/player/stamina_model.gd")
const PLAYER_COMMAND_SCRIPT: Script = preload("res://scripts/player/player_command.gd")
const INVENTORY_MODEL_SCRIPT: Script = preload("res://scripts/items/inventory_model.gd")
const MELEE_ATTACK_MODEL_SCRIPT: Script = preload("res://scripts/combat/melee_attack_model.gd")
const REVIVE_MODEL_SCRIPT: Script = preload("res://scripts/progression/revive_model.gd")
const ITEM_DATA_SCRIPT: Script = preload("res://scripts/item_data.gd")
const ITEM_STACK_MODEL_SCRIPT: Script = preload("res://scripts/items/item_stack_model.gd")
const ITEM_CATALOG_SCRIPT: Script = preload("res://scripts/items/item_catalog.gd")
const WORLD_RESOURCE_DEFINITION_SCRIPT: Script = preload("res://scripts/data/world_resource_definition.gd")
const GATHERABLE_RESOURCE_MODEL_SCRIPT: Script = preload("res://scripts/world/gatherable_resource_model.gd")
const SURVIVAL_CONSUMPTION_MODEL_SCRIPT: Script = preload("res://scripts/player/survival_consumption_model.gd")
const WATER_CONTAINER_MODEL_SCRIPT: Script = preload("res://scripts/items/water_container_model.gd")
const RUN_SESSION_MODEL_SCRIPT: Script = preload("res://scripts/core/run_session_model.gd")
const RUN_RANDOM_STREAM_MODEL_SCRIPT: Script = preload("res://scripts/core/run_random_stream_model.gd")
const BOSS_PROGRESS_MODEL_SCRIPT: Script = preload("res://scripts/combat/boss_progress_model.gd")
const RUN_SNAPSHOT_DATA_SCRIPT: Script = preload("res://scripts/core/run_snapshot_data.gd")
const RUN_SAVE_MODEL_SCRIPT: Script = preload("res://scripts/core/run_save_model.gd")
const OBJECTIVE_PROGRESS_MODEL_SCRIPT: Script = preload("res://scripts/world/objective_progress_model.gd")
const RUN_REWARD_MODEL_SCRIPT: Script = preload("res://scripts/progression/run_reward_model.gd")
const ENCOUNTER_SPAWN_DEFINITION_SCRIPT: Script = preload("res://scripts/data/encounter_spawn_definition.gd")
const ENCOUNTER_DEFINITION_SCRIPT: Script = preload("res://scripts/data/encounter_definition.gd")
const AREA_DEFINITION_SCRIPT: Script = preload("res://scripts/data/area_definition.gd")
const UPGRADE_DEFINITION_SCRIPT: Script = preload("res://scripts/data/upgrade_definition.gd")
const RUN_BUILD_MODEL_SCRIPT: Script = preload("res://scripts/progression/run_build_model.gd")
const CONTENT_VALIDATION_MODEL_SCRIPT: Script = preload("res://scripts/data/content_validation_model.gd")
const SURVIVAL_TUNING_SCRIPT: Script = preload("res://scripts/data/survival_tuning.gd")
const SURVIVAL_VITALS_MODEL_SCRIPT: Script = preload("res://scripts/player/survival_vitals_model.gd")
const SURVIVAL_CLOCK_MODEL_SCRIPT: Script = preload("res://scripts/world/survival_clock_model.gd")
const DISASTER_SCHEDULER_MODEL_SCRIPT: Script = preload("res://scripts/world/disaster_scheduler_model.gd")
const RESOURCE_BUDGET_MODEL_SCRIPT: Script = preload("res://scripts/world/resource_budget_model.gd")
const ESCAPE_OBJECTIVE_MODEL_SCRIPT: Script = preload("res://scripts/world/escape_objective_model.gd")
const THREAT_BUDGET_MODEL_SCRIPT: Script = preload("res://scripts/world/threat_budget_model.gd")
const SPAWN_PROTECTION_MODEL_SCRIPT: Script = preload("res://scripts/world/spawn_protection_model.gd")
const ENEMY_PERCEPTION_MODEL_SCRIPT: Script = preload("res://scripts/combat/enemy_perception_model.gd")
const DISASTER_EVENT_MODEL_SCRIPT: Script = preload("res://scripts/world/disaster_event_model.gd")
const META_PROGRESSION_MODEL_SCRIPT: Script = preload("res://scripts/progression/meta_progression_model.gd")
const RUN_BUFF_DRAFT_MODEL_SCRIPT: Script = preload("res://scripts/progression/run_buff_draft_model.gd")
const RECIPE_INGREDIENT_SCRIPT: Script = preload("res://scripts/data/recipe_ingredient.gd")
const RECIPE_DEFINITION_SCRIPT: Script = preload("res://scripts/data/recipe_definition.gd")
const CRAFTING_MODEL_SCRIPT: Script = preload("res://scripts/items/crafting_model.gd")
const CAMPFIRE_MODEL_SCRIPT: Script = preload("res://scripts/world/campfire_model.gd")
const TORCH_MODEL_SCRIPT: Script = preload("res://scripts/items/torch_model.gd")
const PROCESSING_STATION_MODEL_SCRIPT: Script = preload("res://scripts/items/processing_station_model.gd")
const BUILDING_MODEL_SCRIPT: Script = preload("res://scripts/world/building_model.gd")
const NIGHT_FOG_MODEL_SCRIPT: Script = preload("res://scripts/world/night_fog_model.gd")
const MOON_CYCLE_MODEL_SCRIPT: Script = preload("res://scripts/world/moon_cycle_model.gd")
const DARKNESS_MARK_MODEL_SCRIPT: Script = preload("res://scripts/world/darkness_mark_model.gd")
const DYNAMIC_SPAWN_POINT_SCRIPT: Script = preload("res://scripts/data/dynamic_spawn_point_definition.gd")
const DYNAMIC_SPAWN_DIRECTOR_SCRIPT: Script = preload("res://scripts/world/dynamic_spawn_director_model.gd")
const CHARACTER_ATTRIBUTES_MODEL_SCRIPT: Script = preload("res://scripts/progression/character_attributes_model.gd")
const EQUIPMENT_MODEL_SCRIPT: Script = preload("res://scripts/items/equipment_model.gd")
const ENCUMBRANCE_MODEL_SCRIPT: Script = preload("res://scripts/player/encumbrance_model.gd")
const CHARACTER_BUILD_MODEL_SCRIPT: Script = preload("res://scripts/progression/character_build_model.gd")
const EQUIPMENT_DEFINITION_SCRIPT: Script = preload("res://scripts/data/equipment_definition.gd")
const EQUIPMENT_INTERACTION_MODEL_SCRIPT: Script = preload("res://scripts/player/equipment_interaction_model.gd")
const STEP_TERRAIN_MODEL_SCRIPT: Script = preload("res://scripts/world/step_terrain_model.gd")
const VAULT_ACTION_MODEL_SCRIPT: Script = preload("res://scripts/player/vault_action_model.gd")
const DIGGING_MODEL_SCRIPT: Script = preload("res://scripts/world/digging_model.gd")
const WATER_TRAVERSAL_MODEL_SCRIPT: Script = preload("res://scripts/player/water_traversal_model.gd")
const ROUTE_VALIDATION_MODEL_SCRIPT: Script = preload("res://scripts/world/route_validation_model.gd")
const ENVIRONMENT_EFFECT_RESOLVER_SCRIPT: Script = preload("res://scripts/world/environment_effect_resolver.gd")
const DISASTER_COUNTERMEASURE_MODEL_SCRIPT: Script = preload("res://scripts/world/disaster_countermeasure_model.gd")
const REGION_PROFILE_MODEL_SCRIPT: Script = preload("res://scripts/world/region_profile_model.gd")
const REGION_ROUTE_MODEL_SCRIPT: Script = preload("res://scripts/world/region_route_model.gd")
const RELEASE_READINESS_MODEL_SCRIPT: Script = preload("res://scripts/core/release_readiness_model.gd")
const ACCESSIBILITY_SETTINGS_MODEL_SCRIPT: Script = preload("res://scripts/presentation/accessibility_settings_model.gd")
const LOCAL_TELEMETRY_MODEL_SCRIPT: Script = preload("res://scripts/core/local_telemetry_model.gd")
const PLAN036_RECIPE_PATHS: PackedStringArray = [
	"res://assets/recipes/torch.tres",
	"res://assets/recipes/stone_knife.tres",
	"res://assets/recipes/simple_bandage.tres",
	"res://assets/recipes/temporary_container.tres",
	"res://assets/recipes/campfire.tres",
	"res://assets/recipes/rain_shelter.tres",
	"res://assets/recipes/wood_wall.tres",
]

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
const RUN_STATE_PAUSED: int = 7

var _failures: int = 0


func _init() -> void:
	_run_health_model_tests()
	_run_stamina_model_tests()
	_run_player_command_tests()
	_run_inventory_model_tests()
	_run_item_stack_model_tests()
	_run_item_catalog_tests()
	_run_gatherable_resource_model_tests()
	_run_survival_consumption_model_tests()
	_run_water_container_model_tests()
	_run_melee_attack_model_tests()
	_run_revive_model_tests()
	_run_session_model_tests()
	_run_random_stream_model_tests()
	_run_boss_progress_model_tests()
	_run_run_save_model_tests()
	_run_objective_progress_model_tests()
	_run_run_reward_model_tests()
	_run_content_definition_tests()
	_run_run_build_model_tests()
	_run_content_validation_model_tests()
	_run_survival_tuning_tests()
	_run_survival_vitals_model_tests()
	_run_survival_clock_model_tests()
	_run_disaster_scheduler_model_tests()
	_run_resource_budget_model_tests()
	_run_escape_objective_model_tests()
	_run_threat_budget_model_tests()
	_run_spawn_protection_model_tests()
	_run_enemy_perception_model_tests()
	_run_disaster_event_model_tests()
	_run_meta_progression_model_tests()
	_run_run_buff_draft_model_tests()
	_run_crafting_model_tests()
	_run_plan036_recipe_tests()
	_run_campfire_model_tests()
	_run_torch_model_tests()
	_run_processing_station_model_tests()
	_run_building_model_tests()
	_run_night_fog_and_moon_model_tests()
	_run_dynamic_spawn_director_model_tests()
	_run_plan038_model_tests()
	_run_plan039_model_tests()
	_run_plan040_model_tests()
	_run_plan041_model_tests()
	_run_plan042_model_tests()
	_run_plan043_model_tests()
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


func _assert_approx(actual: float, expected: float, message: String, tolerance: float = 0.0001) -> void:
	_assert_true(
		is_equal_approx(actual, expected) or absf(actual - expected) <= tolerance,
		"%s (actual=%s, expected=%s)" % [message, actual, expected]
	)


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
	var invalid_health_snapshot_model = HEALTH_MODEL_SCRIPT.new(100.0)
	_assert_true(
		not invalid_health_snapshot_model.restore_snapshot({
			"max_health": INF,
			"current_health": 0.0,
			"is_dead": true,
		}),
		"health snapshot rejects non-finite values"
	)


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
	_assert_true(not command.use_pressed, "command defaults to no item use")
	_assert_true(not command.vault_pressed and not command.dig_pressed, "command defaults to no traversal actions")

	var populated = PLAYER_COMMAND_SCRIPT.new(Vector2.RIGHT, true, true, -1, 4, true)
	_assert_equal(populated.move_direction, Vector2.RIGHT, "command stores movement intent")
	_assert_true(populated.sprint_requested, "command stores sprint intent")
	_assert_true(populated.attack_pressed, "command stores attack edge")
	_assert_equal(populated.cycle_delta, -1, "command stores previous-slot intent")
	_assert_equal(populated.selected_slot, 4, "command stores direct slot intent")
	_assert_true(populated.drop_pressed, "command stores drop edge")
	var use_command = PLAYER_COMMAND_SCRIPT.new(Vector2.ZERO, false, false, 0, -1, false, true)
	_assert_true(use_command.use_pressed, "command stores item use intent")
	var traversal_command = PLAYER_COMMAND_SCRIPT.new(Vector2.ZERO, false, false, 0, -1, false, false, true, true)
	_assert_true(traversal_command.vault_pressed and traversal_command.dig_pressed, "command stores traversal intents")

	var clamped = PLAYER_COMMAND_SCRIPT.new(Vector2(2.0, 0.0), false, false, 8, -5, false)
	_assert_equal(clamped.move_direction, Vector2.RIGHT, "command clamps movement length")
	_assert_equal(clamped.cycle_delta, 1, "command clamps slot cycling to one step")
	_assert_equal(clamped.selected_slot, -1, "command rejects negative slot selection")


func _run_inventory_model_tests() -> void:
	var catalog: RefCounted = ITEM_CATALOG_SCRIPT.new()
	var model: RefCounted = INVENTORY_MODEL_SCRIPT.new(8, catalog)
	var wood: ItemData = catalog.get_item(&"wood")
	var sword: ItemData = catalog.get_item(&"stone_sword")
	_assert_equal(model.get_slot_count(), 8, "inventory defaults to eight slots")
	_assert_equal(model.get_occupied_slot_count(), 0, "inventory starts with no occupied slots")
	_assert_true(model.add_quantity(wood, 14), "fourteen wood fits as ten plus four")
	_assert_equal(model.get_stacks()[0].get_quantity(), 10, "first stack fills first")
	_assert_equal(model.get_stacks()[1].get_quantity(), 4, "overflow uses next slot")
	_assert_approx(model.get_total_weight(), 7.0, "inventory calculates total weight")
	_assert_true(model.add_item(sword), "legacy add_item accepts a quantity-one sword")
	_assert_equal(model.get_occupied_slot_count(), 3, "inventory counts occupied stacks")
	var shovel: ItemData = catalog.get_item(&"shovel")
	_assert_true(model.add_item(shovel), "inventory accepts a durable shovel")
	_assert_true(model.set_selected_slot(3), "inventory selects the durable shovel slot")
	_assert_equal(model.get_selected_stack().get_durability(), 20, "durable tools start at maximum durability")
	_assert_true(model.damage_selected_durability(3), "inventory can consume tool durability")
	_assert_equal(model.get_selected_stack().get_durability(), 17, "tool durability decreases without changing the slot")
	_assert_true(model.set_selected_slot(0), "inventory returns to the first slot after tool durability checks")
	_assert_equal(model.get_selected_item(), wood, "inventory exposes selected item definition")
	_assert_true(not model.add_quantity(wood, 70), "insufficient space rejects the whole addition")
	_assert_equal(model.get_stacks()[0].get_quantity(), 10, "failed addition does not mutate existing stacks")
	_assert_true(not model.set_selected_slot(-1), "inventory rejects negative slot")
	_assert_true(model.set_selected_slot(7), "inventory selects the eighth slot")
	_assert_true(model.cycle_selected(1), "inventory cycles selected slot")
	_assert_equal(model.get_selected_slot(), 0, "inventory cycle wraps to first slot")
	var dropped: RefCounted = model.drop_selected()
	_assert_equal(dropped.get_quantity(), 10, "drop_selected returns the complete stack")
	_assert_equal(model.drop_selected(), null, "empty selected slot returns null")
	var all_dropped: Array = model.drop_all()
	_assert_equal(all_dropped.size(), 3, "drop_all returns remaining stacks including the durable tool")
	_assert_true(model.get_items().all(func(item: Variant) -> bool: return item == null), "drop_all clears all slots")
	var capacity_model: RefCounted = INVENTORY_MODEL_SCRIPT.new(8, catalog)
	_assert_true(capacity_model.add_quantity(wood, 11), "capacity test fills a second slot before expansion")
	_assert_true(capacity_model.configure_slot_count(10), "inventory can expand without losing items")
	_assert_equal(capacity_model.get_slot_count(), 10, "inventory expansion exposes the new capacity")
	_assert_true(not capacity_model.configure_slot_count(1), "inventory shrink rejects occupied slots")

	var legacy_model: RefCounted = INVENTORY_MODEL_SCRIPT.new(8, catalog)
	_assert_true(legacy_model.restore_snapshot({
		"slot_count": 8,
		"selected_slot": 2,
		"items": [
			{"id": "wood", "display_name": "旧木材", "item_type": 3, "attack_damage": 0.0},
			{}, {}, {}, {}, {}, {}, {},
		]
	}), "inventory restores schema-version-one snapshot")
	_assert_equal(legacy_model.get_stacks()[0].get_quantity(), 1, "legacy item becomes quantity-one stack")
	_assert_equal(legacy_model.get_selected_slot(), 2, "legacy selected slot is preserved")
	var current_snapshot: Dictionary = legacy_model.create_snapshot()
	_assert_equal(current_snapshot.get("format_version"), 2, "inventory snapshot uses version two")
	var restored_model: RefCounted = INVENTORY_MODEL_SCRIPT.new(8, catalog)
	_assert_true(restored_model.restore_snapshot(current_snapshot), "inventory restores current snapshot")
	_assert_equal(restored_model.get_stacks()[0].get_quantity(), 1, "current snapshot keeps stack quantity")
	var before_invalid: Dictionary = restored_model.create_snapshot()
	_assert_true(not restored_model.restore_snapshot({"format_version": 2, "slot_count": 8, "selected_slot": 0, "stacks": [{"format_version": 1, "item_id": "unknown", "quantity": 1, "durability": -1}]}), "unknown item snapshot is rejected")
	_assert_equal(restored_model.create_snapshot(), before_invalid, "invalid restore leaves inventory unchanged")


func _run_item_stack_model_tests() -> void:
	var wood: ItemData = ITEM_DATA_SCRIPT.new()
	wood.id = &"wood"
	wood.display_name = "木材"
	wood.item_type = ItemData.ItemType.MATERIAL
	wood.max_stack = 10
	wood.unit_weight = 0.5
	_assert_true(wood.is_valid(), "wood definition is valid")
	var stack: RefCounted = ITEM_STACK_MODEL_SCRIPT.new()
	_assert_true(stack.setup(wood, 4), "stack accepts a valid quantity")
	_assert_equal(stack.get_quantity(), 4, "stack exposes quantity")
	_assert_approx(stack.get_total_weight(), 2.0, "stack calculates total weight")
	_assert_equal(stack.get_available_capacity(), 6, "stack exposes available capacity")
	_assert_true(not ITEM_STACK_MODEL_SCRIPT.new().setup(wood, 0), "stack rejects zero quantity")
	_assert_true(not ITEM_STACK_MODEL_SCRIPT.new().setup(wood, 11), "stack rejects quantity above max")
	wood.unit_weight = -1.0
	_assert_true(not wood.is_valid(), "item rejects negative weight")
	wood.unit_weight = 0.5
	wood.max_durability = 20
	_assert_true(ITEM_STACK_MODEL_SCRIPT.new().setup(wood, 1, 10), "durable stack accepts in-range durability")
	_assert_true(not ITEM_STACK_MODEL_SCRIPT.new().setup(wood, 2, 10), "durable stack rejects quantity greater than one")
	_assert_true(not ITEM_STACK_MODEL_SCRIPT.new().setup(wood, 1, 21), "stack rejects durability above maximum")
	wood.max_durability = 0
	var snapshot: Dictionary = stack.create_snapshot()
	_assert_equal(snapshot.get("format_version"), 2, "stack snapshot has a format version")
	_assert_equal(snapshot.get("item_id"), "wood", "stack snapshot stores stable item id")
	var catalog = _TestItemCatalog.new(wood)
	var restored: RefCounted = ITEM_STACK_MODEL_SCRIPT.new()
	_assert_true(restored.restore_snapshot(snapshot, catalog), "stack restores from catalog")
	_assert_equal(restored.get_quantity(), 4, "restored stack keeps quantity")
	_assert_true(not ITEM_STACK_MODEL_SCRIPT.new().restore_snapshot(snapshot, _TestItemCatalog.new()), "unknown item id is rejected")
	_assert_true(not ITEM_STACK_MODEL_SCRIPT.new().restore_snapshot({"format_version": 1, "item_id": "wood", "quantity": 1.5, "durability": -1}, catalog), "non-integral quantity is rejected")
	_assert_true(not ITEM_STACK_MODEL_SCRIPT.new().restore_snapshot({"format_version": 1, "item_id": "wood", "quantity": 1, "durability": "bad"}, catalog), "malformed durability is rejected")
	var runtime_catalog: RefCounted = ITEM_CATALOG_SCRIPT.new()
	var container_item: ItemData = runtime_catalog.get_item(&"medium_container")
	var container_stack: RefCounted = ITEM_STACK_MODEL_SCRIPT.new()
	_assert_true(container_stack.setup(container_item, 1), "container stack creates runtime contents")
	_assert_true(container_stack.fill_container(WATER_CONTAINER_MODEL_SCRIPT.Source.RAIN, 2, false), "container stack fills runtime contents")
	_assert_equal(container_stack.get_container_snapshot().get("amount"), 2, "container stack exposes filled amount")
	var container_snapshot: Dictionary = container_stack.create_snapshot()
	var restored_container_stack: RefCounted = ITEM_STACK_MODEL_SCRIPT.new()
	_assert_true(restored_container_stack.restore_snapshot(container_snapshot, runtime_catalog), "container stack restores runtime contents")
	_assert_equal(restored_container_stack.get_container_snapshot().get("amount"), 2, "restored container keeps runtime amount")


class _TestItemCatalog extends RefCounted:
	var _item: ItemData

	func _init(item: ItemData = null) -> void:
		_item = item

	func get_item(item_id: StringName) -> ItemData:
		if _item != null and _item.id == item_id:
			return _item
		return null


func _run_item_catalog_tests() -> void:
	var catalog: RefCounted = ITEM_CATALOG_SCRIPT.new()
	_assert_true(catalog.is_valid(), "default item catalog is valid")
	_assert_equal(catalog.get_all_items().size(), 31, "catalog exposes survival items, weapons, building kits, traversal tools, and equipment")
	for item_id: StringName in [&"stone_sword", &"wood", &"stone", &"wild_food", &"scrap_parts"]:
		_assert_true(catalog.get_item(item_id) != null, "catalog resolves %s" % item_id)
	_assert_true(catalog.get_item(&"handmade_pistol") != null, "catalog resolves the graybox firearm")
	_assert_true(catalog.get_item(&"pistol_ammo") != null, "catalog resolves firearm ammunition")
	_assert_equal(catalog.get_item(&"missing"), null, "unknown item id returns null")
	var duplicate_item: ItemData = ITEM_DATA_SCRIPT.new()
	duplicate_item.id = &"duplicate"
	duplicate_item.display_name = "重复"
	var duplicate_catalog: RefCounted = ITEM_CATALOG_SCRIPT.new([duplicate_item, duplicate_item])
	_assert_true(not duplicate_catalog.is_valid(), "catalog rejects duplicate item ids")
	var invalid_item: ItemData = ITEM_DATA_SCRIPT.new()
	invalid_item.id = &"invalid"
	invalid_item.display_name = "非法"
	invalid_item.max_stack = 2
	invalid_item.max_durability = 10
	var invalid_catalog: RefCounted = ITEM_CATALOG_SCRIPT.new([invalid_item])
	_assert_true(not invalid_catalog.is_valid(), "catalog rejects stackable durable items")


func _run_gatherable_resource_model_tests() -> void:
	var catalog: RefCounted = ITEM_CATALOG_SCRIPT.new()
	var definition: Resource = WORLD_RESOURCE_DEFINITION_SCRIPT.new()
	definition.id = &"test_wood_node"
	definition.display_name = "测试木材"
	definition.output_item = catalog.get_item(&"wood")
	definition.base_units = 5
	definition.gather_amount = 2
	_assert_true(definition.is_valid(), "gatherable resource definition is valid")
	var normal: RefCounted = GATHERABLE_RESOURCE_MODEL_SCRIPT.new(definition, SURVIVAL_TUNING_SCRIPT.Difficulty.NORMAL)
	_assert_equal(normal.get_remaining_units(), 5, "normal resource keeps base units")
	_assert_equal(normal.gather_once(), 2, "gather returns configured amount")
	_assert_equal(normal.get_remaining_units(), 3, "gather decrements remaining units")
	_assert_equal(normal.gather_once(), 2, "second gather returns configured amount")
	_assert_equal(normal.gather_once(), 1, "final gather returns partial amount")
	_assert_true(normal.is_depleted(), "resource becomes depleted at zero")
	_assert_equal(normal.gather_once(), 0, "depleted resource rejects repeated gather")
	var normal_fresh: RefCounted = GATHERABLE_RESOURCE_MODEL_SCRIPT.new(definition, SURVIVAL_TUNING_SCRIPT.Difficulty.NORMAL)
	var hard: RefCounted = GATHERABLE_RESOURCE_MODEL_SCRIPT.new(definition, SURVIVAL_TUNING_SCRIPT.Difficulty.HARD)
	var hell: RefCounted = GATHERABLE_RESOURCE_MODEL_SCRIPT.new(definition, SURVIVAL_TUNING_SCRIPT.Difficulty.HELL)
	_assert_true(normal_fresh.get_remaining_units() >= hard.get_remaining_units(), "hard richness does not exceed normal")
	_assert_true(hard.get_remaining_units() >= hell.get_remaining_units(), "hell richness does not exceed hard")
	var snapshot: Dictionary = hard.create_snapshot()
	var restored: RefCounted = GATHERABLE_RESOURCE_MODEL_SCRIPT.new(definition, SURVIVAL_TUNING_SCRIPT.Difficulty.NORMAL)
	_assert_true(restored.restore_snapshot(snapshot), "resource restores a valid snapshot")
	_assert_equal(restored.get_remaining_units(), hard.get_remaining_units(), "resource snapshot keeps remaining units")
	_assert_true(not restored.restore_snapshot({"entity_id": "wrong", "remaining_units": 1, "depleted": false}), "resource rejects wrong entity id")


func _run_survival_consumption_model_tests() -> void:
	var vitals: RefCounted = SURVIVAL_VITALS_MODEL_SCRIPT.new(10.0, 10.0)
	var model: RefCounted = SURVIVAL_CONSUMPTION_MODEL_SCRIPT.new()
	var raw_meat: ItemData = ITEM_DATA_SCRIPT.new()
	raw_meat.id = &"raw_meat"
	raw_meat.display_name = "生肉"
	raw_meat.item_type = ItemData.ItemType.FOOD
	raw_meat.max_stack = 3
	raw_meat.food_restore = 8.0
	raw_meat.is_raw_food = true
	raw_meat.disease_chance = 1.0
	_assert_true(model.consume_food(raw_meat, vitals, 0.0), "food consumption succeeds")
	_assert_equal(vitals.get_hunger(), 18.0, "food restores hunger")
	_assert_true(model.has_disease(), "raw food can trigger disease")
	var disease_duration: float = model.get_disease_remaining_seconds()
	_assert_true(disease_duration > 0.0, "disease has a finite duration")
	_assert_true(model.consume_food(raw_meat, vitals, 1.0), "repeat food consumption succeeds")
	_assert_true(model.get_disease_remaining_seconds() >= disease_duration, "disease refreshes instead of stacking")
	model.tick(model.get_disease_remaining_seconds())
	_assert_true(not model.has_disease(), "disease naturally expires")
	_assert_true(not model.consume_food(null, vitals, 0.0), "null food is rejected")
	var snapshot: Dictionary = model.create_snapshot()
	var restored: RefCounted = SURVIVAL_CONSUMPTION_MODEL_SCRIPT.new()
	_assert_true(restored.restore_snapshot(snapshot), "disease snapshot restores")
	_assert_true(not restored.restore_snapshot({"disease_kind": "water_source"}), "malformed disease snapshot is rejected")


func _run_water_container_model_tests() -> void:
	var container: RefCounted = WATER_CONTAINER_MODEL_SCRIPT.new(3)
	_assert_equal(container.get_capacity(), 3, "container stores its capacity")
	_assert_true(container.fill(WATER_CONTAINER_MODEL_SCRIPT.Source.RAIN, 2, true), "container fills purified rain water")
	_assert_equal(container.get_amount(), 2, "container tracks water amount")
	_assert_true(not container.fill(WATER_CONTAINER_MODEL_SCRIPT.Source.PUDDLE, 1, false), "container rejects mixed source and purity")
	_assert_true(container.consume(1), "container consumes one water unit")
	_assert_equal(container.get_amount(), 1, "container decrements water amount")
	var snapshot: Dictionary = container.create_snapshot()
	var restored: RefCounted = WATER_CONTAINER_MODEL_SCRIPT.new(1)
	_assert_true(restored.restore_snapshot(snapshot), "container snapshot restores capacity and contents")
	_assert_equal(restored.get_capacity(), 3, "restored container keeps capacity")
	_assert_true(not restored.restore_snapshot({"capacity": 3, "amount": 4, "source": 1, "purified": true}), "container rejects overflow snapshot")
	var inventory_catalog: RefCounted = ITEM_CATALOG_SCRIPT.new()
	var inventory: RefCounted = INVENTORY_MODEL_SCRIPT.new(3, inventory_catalog)
	var empty: ItemData = inventory_catalog.get_item(&"empty_container")
	var medium: ItemData = inventory_catalog.get_item(&"medium_container")
	_assert_true(inventory.add_item(empty), "inventory accepts an empty container")
	_assert_true(inventory.fill_selected_container(WATER_CONTAINER_MODEL_SCRIPT.Source.FLOWING, 1, false), "inventory fills selected container")
	_assert_equal(inventory.get_selected_container_snapshot().get("amount"), 1, "inventory exposes selected water amount")
	_assert_true(inventory.consume_selected_water(), "inventory drinks one selected water unit")
	_assert_equal(inventory.get_selected_container_snapshot().get("amount"), 0, "drinking empties the selected container")
	_assert_true(inventory.add_item(medium), "inventory accepts a second container")
	_assert_true(inventory.set_selected_slot(1), "inventory selects the second container")
	_assert_true(inventory.fill_selected_container(WATER_CONTAINER_MODEL_SCRIPT.Source.RAIN, 2, true), "inventory fills the second container")
	_assert_true(inventory.transfer_water(1, 0, 1), "inventory transfers water between containers")
	_assert_equal(inventory.get_stack_at(0).get_container_snapshot().get("amount"), 1, "target container receives transferred water")


func _run_crafting_model_tests() -> void:
	var catalog: RefCounted = ITEM_CATALOG_SCRIPT.new()
	var ingredient = RECIPE_INGREDIENT_SCRIPT.new()
	ingredient.item = catalog.get_item(&"wood")
	ingredient.quantity = 2
	_assert_true(ingredient.is_valid(), "recipe ingredient validates item and quantity")
	var recipe = RECIPE_DEFINITION_SCRIPT.new()
	recipe.id = &"test_torch"
	recipe.display_name = "测试火把"
	recipe.output_item = catalog.get_item(&"wood")
	recipe.output_quantity = 1
	var ingredients: Array[Resource] = [ingredient]
	recipe.set("ingredients", ingredients)
	recipe.craft_time_seconds = 4.0
	_assert_true(recipe.is_valid(), "recipe definition validates a complete recipe")
	var inventory: RefCounted = INVENTORY_MODEL_SCRIPT.new(3, catalog)
	_assert_true(inventory.add_quantity(catalog.get_item(&"wood"), 2), "crafting test inventory receives ingredients")
	var crafting: RefCounted = CRAFTING_MODEL_SCRIPT.new()
	_assert_true(crafting.begin(recipe, inventory), "crafting starts when ingredients and output space are available")
	_assert_equal(inventory.get_items()[0], null, "crafting locks ingredients at start")
	_assert_true(crafting.advance(1.0, false, false, true), "crafting advances while uninterrupted")
	_assert_true(not crafting.is_complete(), "crafting remains active before its duration")
	_assert_true(not crafting.advance(1.0, true, false, true), "movement interrupts crafting")
	_assert_true(crafting.is_interrupted(), "interrupted crafting enters interrupted state")
	_assert_equal(inventory.get_stacks()[0].get_quantity(), 2, "interrupted crafting refunds locked ingredients")
	_assert_true(crafting.begin(recipe, inventory), "interrupted task can be restarted")
	_assert_true(crafting.advance(4.0, false, false, true), "crafting completes after its duration")
	_assert_true(crafting.is_complete(), "completed crafting enters complete state")
	_assert_equal(inventory.get_stacks()[0].get_quantity(), 1, "completed crafting adds its output")
	_assert_true(not crafting.begin(recipe, inventory), "completed crafting rejects duplicate completion")


func _run_plan036_recipe_tests() -> void:
	for path: String in PLAN036_RECIPE_PATHS:
		var recipe: Resource = load(path) as Resource
		_assert_true(recipe != null and recipe.get_script() == RECIPE_DEFINITION_SCRIPT, "plan036 recipe loads with its typed resource script: %s" % path)
		if recipe != null:
			_assert_true(recipe.is_valid(), "plan036 recipe satisfies the recipe contract: %s" % path)
	var catalog: RefCounted = ITEM_CATALOG_SCRIPT.new()
	var inventory: RefCounted = INVENTORY_MODEL_SCRIPT.new(4, catalog)
	_assert_true(inventory.add_quantity(catalog.get_item(&"wood"), 1), "full crafting flow gathers wood")
	_assert_true(inventory.add_quantity(catalog.get_item(&"scrap_parts"), 1), "full crafting flow gathers scrap")
	var torch_recipe: Resource = load("res://assets/recipes/torch.tres") as Resource
	var crafting: RefCounted = CRAFTING_MODEL_SCRIPT.new()
	_assert_true(crafting.begin(torch_recipe, inventory), "full crafting flow starts a torch recipe")
	_assert_true(crafting.advance(4.0, false, false, true), "full crafting flow completes the torch recipe")
	var has_torch: bool = false
	for stack: RefCounted in inventory.get_stacks():
		if stack != null and stack.get_definition().id == &"torch":
			has_torch = true
	_assert_true(has_torch, "full crafting flow produces the torch output")


func _run_campfire_model_tests() -> void:
	var campfire: RefCounted = CAMPFIRE_MODEL_SCRIPT.new()
	_assert_true(not campfire.is_lit(), "campfire starts unlit")
	_assert_true(campfire.add_fuel(120.0), "campfire accepts positive fuel")
	_assert_true(campfire.ignite(CAMPFIRE_MODEL_SCRIPT.IgnitionMethod.LIGHTER, 1.0), "lighter ignition always succeeds")
	_assert_true(campfire.is_lit(), "successful ignition lights the campfire")
	var fuel_before_rain: float = campfire.get_fuel_seconds()
	_assert_true(campfire.advance(10.0, CAMPFIRE_MODEL_SCRIPT.Weather.RAIN, false), "campfire advances during rain")
	_assert_approx(fuel_before_rain - campfire.get_fuel_seconds(), 15.0, "rain increases fuel burn to one point five times")
	_assert_true(campfire.extinguish(), "lit campfire can be extinguished")
	_assert_true(not campfire.is_lit(), "extinguishing clears lit state")
	_assert_true(not campfire.ignite(CAMPFIRE_MODEL_SCRIPT.IgnitionMethod.STONE, 0.3), "stone ignition fails at the threshold")
	_assert_true(campfire.ignite(CAMPFIRE_MODEL_SCRIPT.IgnitionMethod.STONE, 0.2), "stone ignition succeeds below thirty percent")
	_assert_true(campfire.take_damage(60.0), "campfire stability can be damaged")
	_assert_true(campfire.get_stability() < 1.0, "campfire stability decreases after damage")
	var snapshot: Dictionary = campfire.create_snapshot()
	var restored: RefCounted = CAMPFIRE_MODEL_SCRIPT.new()
	_assert_true(restored.restore_snapshot(snapshot), "campfire snapshot restores fuel and state")
	_assert_equal(restored.is_lit(), campfire.is_lit(), "restored campfire keeps ignition state")


func _run_torch_model_tests() -> void:
	var torch: RefCounted = TORCH_MODEL_SCRIPT.new(30.0)
	_assert_true(not torch.is_lit(), "torch starts unlit")
	_assert_true(torch.ignite_with_lighter(), "torch can be lit by lighter")
	_assert_true(torch.is_lit(), "lit torch reports active state")
	_assert_true(torch.advance(5.0), "torch consumes burn time while lit")
	_assert_approx(torch.get_remaining_seconds(), 25.0, "torch keeps remaining burn time")
	_assert_true(torch.extinguish(), "torch can be extinguished")
	_assert_true(not torch.is_lit(), "extinguishing clears torch state")
	_assert_true(torch.ignite_from_campfire(), "torch can be lit from a campfire")
	var snapshot: Dictionary = torch.create_snapshot()
	var restored: RefCounted = TORCH_MODEL_SCRIPT.new()
	_assert_true(restored.restore_snapshot(snapshot), "torch snapshot restores remaining time")
	_assert_approx(restored.get_remaining_seconds(), torch.get_remaining_seconds(), "restored torch keeps burn time")


func _run_processing_station_model_tests() -> void:
	var catalog: RefCounted = ITEM_CATALOG_SCRIPT.new()
	var inventory: RefCounted = INVENTORY_MODEL_SCRIPT.new(4, catalog)
	_assert_true(inventory.add_item(catalog.get_item(&"medium_container")), "processing inventory receives a water container")
	_assert_true(inventory.fill_selected_container(WATER_CONTAINER_MODEL_SCRIPT.Source.PUDDLE, 1, false), "processing fills a dirty container")
	_assert_true(inventory.add_item(catalog.get_item(&"raw_meat")), "processing inventory receives raw meat")
	var station: RefCounted = PROCESSING_STATION_MODEL_SCRIPT.new()
	_assert_true(station.start_purifying(inventory), "station starts a purification slot")
	_assert_true(inventory.set_selected_slot(1), "processing selects the cooking slot")
	_assert_true(station.start_cooking(inventory), "station starts a cooking slot concurrently")
	_assert_true(not station.start_cooking(inventory), "cooking slot rejects duplicate jobs")
	_assert_true(station.advance(3.0, false, false, true), "both processing slots advance while stable")
	_assert_true(not station.is_cooking_complete(), "cooking remains active before completion")
	_assert_true(station.advance(3.0, false, false, true), "purification reaches its shorter duration")
	_assert_true(station.is_purifying_complete(), "purification completes independently")
	_assert_true(not station.advance(1.0, true, false, true), "movement interrupts cooking")
	_assert_true(station.is_cooking_interrupted(), "interrupted cooking exposes its state")
	_assert_true(inventory.get_selected_item().id == &"raw_meat", "interrupted cooking refunds raw meat")
	_assert_true(station.start_cooking(inventory), "cooking can restart after interruption")
	_assert_true(station.advance(8.0, false, false, true), "cooking completes after its duration")
	_assert_true(inventory.get_selected_item().id == &"cooked_meat", "cooking outputs cooked meat")
	_assert_true(inventory.get_container_snapshot_at(0).get("purified", false), "purification modifies the locked container slot")
	var processing_snapshot: Dictionary = station.create_snapshot()
	var restored_station: RefCounted = PROCESSING_STATION_MODEL_SCRIPT.new()
	_assert_true(restored_station.restore_snapshot(processing_snapshot, inventory), "processing station snapshot restores")


func _run_building_model_tests() -> void:
	var wall: RefCounted = BUILDING_MODEL_SCRIPT.new(BUILDING_MODEL_SCRIPT.Kind.WALL, Vector2(100.0, 100.0))
	_assert_true(wall.is_position_valid(Rect2(0.0, 0.0, 500.0, 500.0), []), "wall placement accepts an in-bounds position")
	_assert_true(not wall.is_position_valid(Rect2(0.0, 0.0, 500.0, 500.0), [Vector2(100.0, 100.0)]), "building placement rejects an occupied route origin")
	var edge_wall: RefCounted = BUILDING_MODEL_SCRIPT.new(BUILDING_MODEL_SCRIPT.Kind.WALL, Vector2(10.0, 10.0))
	_assert_true(not edge_wall.is_position_valid(Rect2(0.0, 0.0, 500.0, 500.0), []), "building placement rejects a footprint outside map bounds")
	_assert_true(not wall.is_position_valid(Rect2(0.0, 0.0, 500.0, 500.0), [Vector2(100.0, 100.0)]), "building placement rejects occupied positions")
	_assert_true(wall.take_damage(25.0), "building health decreases after damage")
	_assert_equal(wall.get_health(), 75.0, "building health tracks damage")
	var snapshot: Dictionary = wall.create_snapshot()
	var restored: RefCounted = BUILDING_MODEL_SCRIPT.new(BUILDING_MODEL_SCRIPT.Kind.WALL, Vector2.ZERO)
	_assert_true(restored.restore_snapshot(snapshot), "building snapshot restores position and health")
	_assert_equal(restored.get_position(), Vector2(100.0, 100.0), "restored building keeps position")


func _run_night_fog_and_moon_model_tests() -> void:
	var fog: RefCounted = NIGHT_FOG_MODEL_SCRIPT.new()
	_assert_equal(fog.get_phase(0.0, false), 0, "day remains in the fixed contamination phase")
	_assert_equal(fog.get_phase(119.9, true), 1, "night starts with the first fog phase")
	_assert_equal(fog.get_phase(120.0, true), 2, "fog expands to phase two after two minutes")
	_assert_equal(fog.get_phase(240.0, true), 3, "fog reaches the final phase after four minutes")
	_assert_true(fog.is_in_fog(95.0, 100.0, 240.0, true), "late-night fog covers the outer map")
	_assert_true(not fog.is_in_fog(20.0, 100.0, 0.0, true), "early-night safe center remains outside fog")
	var moons: RefCounted = MOON_CYCLE_MODEL_SCRIPT.new()
	_assert_equal(moons.get_kind(0), 0, "first two nights are azure moon")
	_assert_equal(moons.get_kind(2), 1, "nights three and four are cold moon")
	_assert_equal(moons.get_kind(4), 2, "nights five and six are crimson moon")
	_assert_true(moons.is_new_moon(6), "seventh night is new moon")
	_assert_approx(moons.get_monster_spawn_multiplier(6), 2.0, "new moon doubles monster refresh")
	_assert_approx(moons.get_special_spawn_ratio(4), 0.5, "crimson moon reserves half of spawns for specials")
	_assert_approx(moons.get_special_spawn_ratio(6), 0.15, "new moon keeps a low special spawn chance")
	_assert_approx(moons.get_enemy_speed_multiplier(2), 0.70, "cold moon slows enemy movement")
	var mark: RefCounted = DARKNESS_MARK_MODEL_SCRIPT.new()
	_assert_true(not mark.register_dark_attack(false, true, 6), "day attack cannot create a darkness mark")
	_assert_true(mark.register_dark_attack(true, true, 6), "full-dark new moon attack creates a mark")
	_assert_true(not mark.register_dark_attack(true, true, 6), "one night creates at most one darkness mark")
	var mark_effect: Dictionary = mark.consume_for_new_moon()
	_assert_approx(float(mark_effect["budget_multiplier"]), 1.5, "marked new moon increases the next budget")
	_assert_true(bool(mark_effect["special_tier_two_warning"]), "marked new moon guarantees a tier-two warning")


func _run_dynamic_spawn_director_model_tests() -> void:
	var point_a: Resource = DYNAMIC_SPAWN_POINT_SCRIPT.new()
	point_a.id = &"fog_a"
	point_a.position = Vector2(200.0, 0.0)
	point_a.weight = 1.0
	var point_b: Resource = DYNAMIC_SPAWN_POINT_SCRIPT.new()
	point_b.id = &"fog_b"
	point_b.position = Vector2(20.0, 0.0)
	point_b.weight = 8.0
	_assert_true(point_a.is_valid() and point_b.is_valid(), "dynamic spawn points validate their static contract")
	var director: RefCounted = DYNAMIC_SPAWN_DIRECTOR_SCRIPT.new(45.0)
	_assert_true(director.set_wave_interval_seconds(30.0), "spawn director accepts a moon-adjusted wave interval")
	_assert_approx(director.get_wave_interval_seconds(), 30.0, "spawn director exposes its effective wave interval")
	_assert_true(director.set_wave_interval_seconds(45.0), "spawn director can restore its base wave interval")
	_assert_true(director.advance(44.0, true), "spawn director advances during night")
	_assert_true(not director.is_wave_ready(), "spawn wave waits for its interval")
	_assert_true(director.advance(1.0, true), "spawn director reaches a wave boundary")
	_assert_true(director.is_wave_ready(), "spawn director reports a ready wave")
	var random_stream: RefCounted = RUN_RANDOM_STREAM_MODEL_SCRIPT.new()
	_assert_true(random_stream.start(24680, 1), "spawn director receives a deterministic random stream")
	var dynamic_points: Array[Resource] = [point_a, point_b]
	var protected_points: Array[Vector2] = []
	var selected: Resource = director.choose_spawn_point(dynamic_points, random_stream, Vector2.ZERO, protected_points, false, true)
	_assert_equal(selected, point_a, "spawn director rejects a point too close to the player")
	_assert_true(director.register_retry(), "spawn director records failed placement retries")
	_assert_equal(director.get_retry_count(), 1, "spawn retry count is observable")
	_assert_true(director.consume_wave(), "spawn director consumes a ready wave")
	_assert_true(not director.is_wave_ready(), "consuming a wave resets its interval")
	var snapshot: Dictionary = director.create_snapshot()
	var restored: RefCounted = DYNAMIC_SPAWN_DIRECTOR_SCRIPT.new()
	_assert_true(restored.restore_snapshot(snapshot), "spawn director snapshot restores timing state")
	_assert_approx(restored.get_wave_interval_seconds(), 45.0, "restored director keeps the effective interval")
	_assert_true(director.choose_spawn_point(dynamic_points, random_stream, Vector2.ZERO, protected_points, false, true, false, 0.5) != null, "special weighting keeps valid fog points selectable")


func _run_plan038_model_tests() -> void:
	var noise_event_model_script: Script = load("res://scripts/combat/noise_event_model.gd") as Script
	var enemy_role_model_script: Script = load("res://scripts/combat/enemy_role_model.gd") as Script
	var ranged_weapon_model_script: Script = load("res://scripts/combat/ranged_weapon_model.gd") as Script
	var drop_budget_model_script: Script = load("res://scripts/items/drop_budget_model.gd") as Script
	var enemy_tier_model_script: Script = load("res://scripts/combat/enemy_tier_model.gd") as Script
	_assert_true(noise_event_model_script != null, "noise event model is available")
	_assert_true(enemy_role_model_script != null, "enemy role model is available")
	_assert_true(ranged_weapon_model_script != null, "ranged weapon model is available")
	_assert_true(drop_budget_model_script != null, "drop budget model is available")
	_assert_true(enemy_tier_model_script != null, "enemy tier model is available")
	if noise_event_model_script == null or enemy_role_model_script == null or ranged_weapon_model_script == null \
		or drop_budget_model_script == null or enemy_tier_model_script == null:
		return
	var noise: RefCounted = noise_event_model_script.new(noise_event_model_script.Kind.MELEE, Vector2.ZERO, 1.0, false)
	_assert_equal(noise.get_radius_steps(), 4.0, "melee noise uses the unified four-step radius")
	_assert_equal(noise.get_strength(), 1.0, "noise exposes its normalized strength")
	_assert_true(noise.affects(Vector2(120.0, 0.0), false, false), "unblocked noise reaches a listener within radius")
	_assert_true(not noise.affects(Vector2(200.0, 0.0), false, false), "noise does not reach listeners outside radius")
	_assert_true(not noise.affects(Vector2(40.0, 0.0), true, false), "walls block a noise event")
	var rain_noise: RefCounted = noise_event_model_script.new(noise_event_model_script.Kind.GATHER, Vector2.ZERO, 1.0, true)
	_assert_true(rain_noise.affects(Vector2(200.0, 0.0), false, false), "rain noise keeps the reduced effective radius")
	var roles: RefCounted = enemy_role_model_script.new()
	_assert_approx(roles.get_sound_radius_steps(0, 6.0), 6.0, "hunter keeps the full sound clue radius")
	_assert_approx(roles.get_sound_radius_steps(1, 6.0), 8.0, "investigator extends its sound clue radius")
	_assert_approx(roles.get_sound_radius_steps(2, 6.0), 4.0, "siege enemy has a shorter sound clue radius")
	_assert_true(roles.should_disengage(0, 40.0, 1.0), "hunter disengages after losing a distant clue")
	_assert_true(not roles.should_disengage(2, 40.0, 1.0), "siege enemy holds its position instead of disengaging")
	var weapon: RefCounted = ranged_weapon_model_script.new(6, 2.0, 0.5)
	_assert_true(weapon.load_magazine(6), "ranged weapon loads a magazine")
	_assert_true(weapon.try_fire(), "loaded ranged weapon can fire")
	_assert_equal(weapon.get_magazine_rounds(), 5, "firing consumes one magazine round")
	_assert_true(not weapon.try_fire(), "fire cooldown blocks an immediate second shot")
	_assert_true(weapon.advance(0.5), "weapon cooldown advances")
	_assert_true(weapon.start_reload(4), "reload starts with available reserve ammunition")
	_assert_true(weapon.interrupt_reload(), "movement or damage interrupts reload")
	_assert_equal(weapon.get_reserve_rounds(), 4, "interrupted reload does not consume reserve ammunition")
	var drops: RefCounted = drop_budget_model_script.new(1, 2, 1)
	_assert_true(not drops.should_force_food(), "food pity does not trigger before three misses")
	drops.register_kill(false)
	drops.register_kill(false)
	drops.register_kill(false)
	_assert_true(drops.should_force_food(), "the fourth eligible kill triggers food pity")
	_assert_true(drops.register_kill(true), "food drop resets the pity counter")
	_assert_true(not drops.should_force_food(), "food pity resets after a successful drop")
	_assert_true(drops.try_spend_material_budget(2), "material budget allows its configured cap")
	_assert_true(not drops.try_spend_material_budget(1), "material budget rejects overflow")
	_assert_true(drops.register_kill(false, false), "ineligible enemy kills do not alter food pity")
	_assert_equal(drops.get_material_remaining(), 0, "material remaining reaches zero at its budget cap")
	_assert_equal(enemy_tier_model_script.get_threat_cost(0), 1, "ordinary enemy uses one threat cost")
	_assert_equal(enemy_tier_model_script.get_threat_cost(3), 4, "tier-two enemy uses the highest threat cost")
	_assert_true(enemy_tier_model_script.can_drop_crystal(2), "elite enemy can qualify for crystal drops")


func _run_plan039_model_tests() -> void:
	var equipment_transaction_script: Script = load("res://scripts/items/equipment_transaction_model.gd") as Script
	_assert_true(equipment_transaction_script != null, "equipment transaction model is available")
	var attributes: RefCounted = CHARACTER_ATTRIBUTES_MODEL_SCRIPT.new()
	_assert_true(attributes.has_method("get_total_points"), "attributes expose the run allocation budget")
	if attributes.has_method("get_total_points"):
		var ranked_attributes: RefCounted = CHARACTER_ATTRIBUTES_MODEL_SCRIPT.new(35)
		_assert_equal(ranked_attributes.get_total_points(), 35, "meta tier bonuses expand the run allocation budget")
		_assert_true(ranked_attributes.allocate(CHARACTER_ATTRIBUTES_MODEL_SCRIPT.Attribute.INTELLIGENCE, 15), "expanded attribute budget can allocate beyond the base ten points")
		_assert_equal(ranked_attributes.get_points_remaining(), 20, "expanded allocation conserves the complete point budget")
	_assert_equal(attributes.get_points_remaining(), 10, "attributes start with ten allocation points")
	_assert_true(attributes.allocate(CHARACTER_ATTRIBUTES_MODEL_SCRIPT.Attribute.INTELLIGENCE, 4), "intelligence accepts an allocation")
	_assert_true(attributes.allocate(CHARACTER_ATTRIBUTES_MODEL_SCRIPT.Attribute.STRENGTH, 3), "strength accepts an allocation")
	_assert_true(attributes.allocate(CHARACTER_ATTRIBUTES_MODEL_SCRIPT.Attribute.VITALITY, 3), "vitality accepts the remaining allocation")
	_assert_equal(attributes.get_points_remaining(), 0, "attribute points are conserved")
	_assert_true(not attributes.allocate(999), "invalid attributes are rejected")
	_assert_true(not attributes.allocate(CHARACTER_ATTRIBUTES_MODEL_SCRIPT.Attribute.VITALITY), "allocation rejects exhausted points")
	_assert_true(attributes.confirm(), "complete attribute allocation can be confirmed")
	_assert_true(not attributes.allocate(CHARACTER_ATTRIBUTES_MODEL_SCRIPT.Attribute.VITALITY), "confirmed attributes are locked")
	_assert_true(not attributes.confirm(), "confirmed attributes cannot be confirmed twice")
	_assert_approx(attributes.get_crafting_speed_multiplier(), 0.88, "intelligence reduces crafting time")
	_assert_approx(attributes.get_crafting_material_discount_limit(), 0.12, "intelligence exposes capped material discount")
	_assert_approx(attributes.get_melee_damage_multiplier(), 1.12, "strength increases melee damage")
	_assert_approx(attributes.get_carry_capacity_bonus(), 6.0, "strength increases carry capacity")
	_assert_approx(attributes.get_max_health_bonus(), 12.0, "vitality increases maximum health")
	_assert_approx(attributes.get_max_stamina_bonus(), 18.0, "vitality increases maximum stamina")
	var attribute_snapshot: Dictionary = attributes.create_snapshot()
	var restored_attributes: RefCounted = CHARACTER_ATTRIBUTES_MODEL_SCRIPT.new()
	_assert_true(restored_attributes.restore_snapshot(attribute_snapshot), "attributes restore a valid snapshot")
	_assert_equal(restored_attributes.get_value(CHARACTER_ATTRIBUTES_MODEL_SCRIPT.Attribute.STRENGTH), 3, "attribute snapshot preserves values")
	_assert_true(not restored_attributes.restore_snapshot({"format_version": 1, "total_points": 10, "values": {"intelligence": 20, "strength": 20, "vitality": 20}, "points_remaining": 0, "confirmed": true}), "attribute snapshot rejects point conservation violations")

	var head: ItemData = _make_equipment_item("test_head", "测试头盔", EQUIPMENT_DEFINITION_SCRIPT.Slot.HEAD, 0, 0.0, 0.95)
	var backpack: ItemData = _make_equipment_item("test_backpack", "测试背包", EQUIPMENT_DEFINITION_SCRIPT.Slot.BACKPACK, 4, 6.0)
	var heavy_backpack: ItemData = _make_equipment_item("test_heavy_backpack", "测试重型背包", EQUIPMENT_DEFINITION_SCRIPT.Slot.BACKPACK, 4, 10.0)
	var catalog: RefCounted = ITEM_CATALOG_SCRIPT.new([head, backpack, heavy_backpack])
	var equipment: RefCounted = EQUIPMENT_MODEL_SCRIPT.new(catalog)
	_assert_true(equipment.equip(head), "head equipment fills the head slot")
	_assert_true(equipment.equip(backpack, 8), "backpack equipment fills the backpack slot")
	_assert_equal(equipment.get_inventory_slot_count(), 12, "backpack expands inventory to twelve slots")
	_assert_true(not equipment.equip(heavy_backpack, 13), "backpack replacement rejects an over-capacity inventory")
	_assert_true(equipment.equip(heavy_backpack, 12), "backpack replacement accepts inventory at the new capacity")
	_assert_true(equipment.equip(head, 0), "same-slot equipment replacement remains valid")
	var equipment_snapshot: Dictionary = equipment.create_snapshot()
	var restored_equipment: RefCounted = EQUIPMENT_MODEL_SCRIPT.new(catalog)
	_assert_true(restored_equipment.restore_snapshot(equipment_snapshot), "equipment restores a valid snapshot")
	_assert_equal(restored_equipment.get_equipped(EQUIPMENT_DEFINITION_SCRIPT.Slot.BACKPACK).id, &"test_heavy_backpack", "equipment snapshot preserves the selected item")
	_assert_true(restored_equipment.unequip(EQUIPMENT_DEFINITION_SCRIPT.Slot.BACKPACK, 12) == null, "backpack removal rejects an over-capacity inventory")
	_assert_true(restored_equipment.unequip(EQUIPMENT_DEFINITION_SCRIPT.Slot.BACKPACK, 8) != null, "backpack can be unequipped after inventory is reduced")
	_assert_true(restored_equipment.get_equipped(EQUIPMENT_DEFINITION_SCRIPT.Slot.BACKPACK) == null, "unequip clears the slot")

	var encumbrance: RefCounted = ENCUMBRANCE_MODEL_SCRIPT.new(20.0)
	_assert_true(encumbrance.set_bonus_capacity(4.0), "encumbrance accepts attribute and equipment capacity")
	_assert_approx(encumbrance.get_max_capacity(), 24.0, "encumbrance exposes maximum capacity")
	_assert_true(encumbrance.set_current_weight(24.0), "encumbrance accepts normal capacity weight")
	_assert_approx(encumbrance.get_speed_multiplier(), 1.0, "at capacity movement is unpenalized")
	_assert_true(encumbrance.set_current_weight(25.2), "encumbrance enters the first overload tier")
	_assert_approx(encumbrance.get_speed_multiplier(), 0.9, "first overload tier reduces speed")
	_assert_true(encumbrance.set_current_weight(30.0), "encumbrance crosses the twenty-five percent threshold")
	_assert_approx(encumbrance.get_stamina_cost_multiplier(), 1.25, "second overload tier increases stamina cost")
	_assert_true(encumbrance.can_run(), "running remains allowed at the second overload tier")
	_assert_true(encumbrance.set_current_weight(34.0), "encumbrance crosses the forty percent threshold")
	_assert_true(not encumbrance.can_run(), "third overload tier forbids running")
	_assert_true(encumbrance.set_current_weight(40.0), "encumbrance crosses the extreme threshold")
	_assert_true(not encumbrance.can_vault() and not encumbrance.can_swim(), "extreme overload forbids high intensity traversal")
	var encumbrance_snapshot: Dictionary = encumbrance.create_snapshot()
	var restored_encumbrance: RefCounted = ENCUMBRANCE_MODEL_SCRIPT.new()
	_assert_true(restored_encumbrance.restore_snapshot(encumbrance_snapshot), "encumbrance restores a valid snapshot")
	_assert_approx(restored_encumbrance.get_current_weight(), 40.0, "encumbrance snapshot preserves weight")

	var buffs: RefCounted = RUN_BUILD_MODEL_SCRIPT.new()
	_assert_true(buffs.apply_effect(UPGRADE_DEFINITION_SCRIPT.EffectType.DAMAGE_MULTIPLIER, 0.1, &"test_damage"), "build test applies a buff")
	var build: RefCounted = CHARACTER_BUILD_MODEL_SCRIPT.new(attributes, equipment, buffs, encumbrance)
	_assert_true(build.refresh_weight(24.0), "character build refreshes weight from composed bonuses")
	_assert_approx(build.get_melee_damage(100.0), 123.2, "attributes, equipment and buff resolve in a predictable order")
	_assert_approx(build.get_max_health(100.0), 112.0, "vitality contributes to resolved health")
	_assert_approx(build.get_move_speed_multiplier(), 0.95, "weight and head equipment combine into movement")
	var combat_focused_attributes: RefCounted = CHARACTER_ATTRIBUTES_MODEL_SCRIPT.new()
	_assert_true(combat_focused_attributes.allocate(CHARACTER_ATTRIBUTES_MODEL_SCRIPT.Attribute.STRENGTH, 10), "combat-focused build allocates its full strength package")
	var combat_focused_build: RefCounted = CHARACTER_BUILD_MODEL_SCRIPT.new(combat_focused_attributes, EQUIPMENT_MODEL_SCRIPT.new(catalog), null, ENCUMBRANCE_MODEL_SCRIPT.new())
	_assert_true(combat_focused_build.refresh_weight(0.0), "combat-focused build resolves its weight")
	_assert_true(combat_focused_build.get_melee_damage(100.0) > build.get_melee_damage(100.0), "different attribute builds produce different melee outcomes")
	_assert_true(combat_focused_build.get_max_health(100.0) < build.get_max_health(100.0), "different attribute builds produce different survival outcomes")
	var build_snapshot: Dictionary = build.create_snapshot()
	var restored_build: RefCounted = CHARACTER_BUILD_MODEL_SCRIPT.new(null, null, buffs, null)
	_assert_true(restored_build.restore_snapshot(build_snapshot, catalog), "character build restores attributes, equipment, and weight")
	_assert_equal(restored_build.get_inventory_slot_count(), 12, "restored build keeps the equipped backpack capacity")
	var interaction: RefCounted = EQUIPMENT_INTERACTION_MODEL_SCRIPT.new()
	_assert_true(interaction.start(3, &"frame_pack"), "equipment interaction starts for a valid slot and item")
	_assert_true(not interaction.advance(1.5, false, false), "equipment interaction keeps partial standing progress")
	_assert_approx(interaction.get_remaining_seconds(), 0.5, "equipment interaction exposes remaining time")
	_assert_true(not interaction.advance(0.1, true, false), "moving interrupts equipment interaction")
	_assert_equal(interaction.get_state(), EQUIPMENT_INTERACTION_MODEL_SCRIPT.State.IDLE, "movement interruption returns equipment interaction to idle")
	_assert_true(interaction.start(3, &"frame_pack"), "equipment interaction can restart after interruption")
	_assert_true(not interaction.advance(0.5, false, true), "being hit interrupts equipment interaction")
	_assert_true(interaction.start(3, &"frame_pack"), "equipment interaction can restart after damage")
	_assert_true(interaction.advance(2.0, false, false), "standing for two seconds completes equipment interaction")
	var completed_request: Dictionary = interaction.consume_completed()
	_assert_equal(completed_request.get("operation"), EQUIPMENT_INTERACTION_MODEL_SCRIPT.Operation.EQUIP, "completed equipment interaction identifies an equip operation")
	_assert_equal(completed_request.get("item_id"), "frame_pack", "completed interaction exposes its equipment request")
	_assert_equal(interaction.get_state(), EQUIPMENT_INTERACTION_MODEL_SCRIPT.State.IDLE, "consuming a completed request returns to idle")
	_assert_true(interaction.start_unequip(3, &"frame_pack"), "equipment interaction starts an unequip operation")
	_assert_true(interaction.advance(2.0, false, false), "standing for two seconds completes unequip interaction")
	var completed_unequip: Dictionary = interaction.consume_completed()
	_assert_equal(completed_unequip.get("operation"), EQUIPMENT_INTERACTION_MODEL_SCRIPT.Operation.UNEQUIP, "completed unequip interaction preserves its operation")
	if equipment_transaction_script != null:
		var transaction: RefCounted = equipment_transaction_script.new()
		var transaction_catalog: RefCounted = ITEM_CATALOG_SCRIPT.new()
		var transaction_inventory: RefCounted = INVENTORY_MODEL_SCRIPT.new(8, transaction_catalog)
		var transaction_build: RefCounted = CHARACTER_BUILD_MODEL_SCRIPT.new(null, EQUIPMENT_MODEL_SCRIPT.new(transaction_catalog), null, null)
		var field_pack_item: ItemData = transaction_catalog.get_item(&"field_pack")
		var frame_pack_item: ItemData = transaction_catalog.get_item(&"frame_pack")
		_assert_true(transaction_inventory.add_item(field_pack_item), "equipment transaction starts with a backpack in inventory")
		_assert_true(transaction.equip_selected(transaction_inventory, transaction_build, transaction_catalog), "equipment transaction equips the selected backpack")
		_assert_equal(transaction_build.get_equipped_item_id(EQUIPMENT_DEFINITION_SCRIPT.Slot.BACKPACK), &"field_pack", "equipment transaction updates the backpack slot")
		_assert_equal(transaction_inventory.get_slot_count(), 10, "equipping a field pack expands inventory to ten slots")
		_assert_true(transaction_inventory.add_item(frame_pack_item), "equipment transaction accepts a replacement backpack")
		_assert_true(not transaction_inventory.set_selected_slot(0), "equipment transaction replacement remains in the selected first slot")
		_assert_true(transaction.equip_selected(transaction_inventory, transaction_build, transaction_catalog), "equipment transaction atomically replaces a backpack")
		_assert_equal(transaction_build.get_equipped_item_id(EQUIPMENT_DEFINITION_SCRIPT.Slot.BACKPACK), &"frame_pack", "replacement equips the new backpack")
		_assert_equal(transaction_inventory.get_slot_count(), 12, "replacement backpack expands inventory to twelve slots")
		_assert_true(transaction_inventory.get_items().any(func(item: ItemData) -> bool: return item != null and item.id == &"field_pack"), "replacement returns the previous backpack to inventory")
		var rollback_inventory: RefCounted = INVENTORY_MODEL_SCRIPT.new(12, transaction_catalog)
		var rollback_build: RefCounted = CHARACTER_BUILD_MODEL_SCRIPT.new(null, EQUIPMENT_MODEL_SCRIPT.new(transaction_catalog), null, null)
		_assert_true(rollback_build.equip_item(frame_pack_item), "rollback test equips the large backpack")
		for _index: int in 11:
			_assert_true(rollback_inventory.add_item(transaction_catalog.get_item(&"stone_sword")), "rollback test fills inventory slots")
		_assert_true(rollback_inventory.add_item(field_pack_item), "rollback test places the smaller backpack in the final slot")
		_assert_true(rollback_inventory.set_selected_slot(11), "rollback test selects the smaller backpack")
		_assert_true(not transaction.equip_selected(rollback_inventory, rollback_build, transaction_catalog), "equipment transaction rejects unsafe backpack shrink")
		_assert_equal(rollback_build.get_equipped_item_id(EQUIPMENT_DEFINITION_SCRIPT.Slot.BACKPACK), &"frame_pack", "failed backpack replacement restores the previous equipment")
		_assert_equal(rollback_inventory.get_slot_count(), 12, "failed backpack replacement restores inventory capacity")


func _make_equipment_item(item_id: String, display_name: String, slot: int, slot_bonus: int, carry_bonus: float, speed_multiplier: float = 1.0) -> ItemData:
	var item: ItemData = ITEM_DATA_SCRIPT.new() as ItemData
	item.id = StringName(item_id)
	item.display_name = display_name
	item.item_type = ITEM_DATA_SCRIPT.ItemType.EQUIPMENT
	item.max_stack = 1
	var definition: Resource = EQUIPMENT_DEFINITION_SCRIPT.new()
	definition.id = StringName(item_id)
	definition.slot = slot
	definition.inventory_slot_bonus = slot_bonus
	definition.carry_capacity_bonus = carry_bonus
	definition.move_speed_multiplier = speed_multiplier
	item.equipment_definition = definition
	return item


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
	var firearm: ItemData = ITEM_DATA_SCRIPT.new() as ItemData
	firearm.id = &"test_firearm"
	firearm.display_name = "测试枪械"
	firearm.item_type = ITEM_DATA_SCRIPT.ItemType.FIREARM
	firearm.max_stack = 1
	firearm.ranged_damage = 24.0
	firearm.magazine_capacity = 6
	firearm.ammo_item_id = &"pistol_ammo"
	_assert_true(firearm.is_valid(), "firearm item validates its ranged configuration")
	var invalid_firearm: ItemData = ITEM_DATA_SCRIPT.new() as ItemData
	invalid_firearm.id = &"invalid_firearm"
	invalid_firearm.display_name = "无弹匣枪械"
	invalid_firearm.item_type = ITEM_DATA_SCRIPT.ItemType.FIREARM
	_assert_true(not invalid_firearm.is_valid(), "firearm without ranged configuration is rejected")
	var stamina: RefCounted = STAMINA_MODEL_SCRIPT.new(100.0, 30.0, 15.0)
	_assert_true(stamina.try_spend(6.0), "melee stamina cost can be paid")
	_assert_approx(stamina.get_stamina(), 94.0, "melee stamina cost removes six percent from a full bar")
	_assert_true(not stamina.try_spend(95.0), "melee attack is rejected when stamina is insufficient")


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
	_assert_true(model.configure_difficulty(SURVIVAL_TUNING_SCRIPT.Difficulty.HARD), "idle session accepts a difficulty choice")
	_assert_equal(model.get_difficulty(), SURVIVAL_TUNING_SCRIPT.Difficulty.HARD, "session stores the selected difficulty")
	_assert_true(not model.is_difficulty_locked(), "difficulty remains editable before the run starts")
	_assert_true(not model.prepare_floor(), "idle session rejects preparing a floor")
	_assert_true(model.start_run(), "idle session starts a run")
	_assert_equal(model.get_state(), RUN_STATE_PREPARING_FLOOR, "starting a run prepares the first floor")
	_assert_equal(model.get_floor_number(), 1, "starting a run selects floor one")
	_assert_equal(model.get_total_floors(), 6, "a standard run contains six floors")
	_assert_true(model.is_difficulty_locked(), "starting a run locks its difficulty")
	_assert_true(not model.configure_difficulty(SURVIVAL_TUNING_SCRIPT.Difficulty.NORMAL), "active session rejects difficulty changes")
	_assert_equal(model.get_difficulty(), SURVIVAL_TUNING_SCRIPT.Difficulty.HARD, "rejected difficulty changes preserve the run configuration")
	_assert_true(not model.start_run(), "preparing session rejects duplicate start")
	_assert_true(model.prepare_floor(), "preparing session enters exploration")
	_assert_equal(model.get_state(), RUN_STATE_EXPLORING, "prepared floor is explorable")
	_assert_true(model.pause(), "active exploration can pause")
	_assert_equal(model.get_state(), RUN_STATE_PAUSED, "paused run exposes a dedicated state")
	_assert_true(not model.pause(), "paused run rejects duplicate pause")
	_assert_true(model.is_run_active(), "paused run remains an active run")
	_assert_true(not model.mark_dead(), "paused run rejects death while simulation is frozen")
	_assert_true(model.resume(), "paused exploration can resume")
	_assert_equal(model.get_state(), RUN_STATE_EXPLORING, "resume restores the state from before pause")
	_assert_true(not model.resume(), "active exploration rejects duplicate resume")
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
	_assert_true(not model.is_difficulty_locked(), "reset unlocks difficulty for the next run")
	_assert_equal(model.get_difficulty(), SURVIVAL_TUNING_SCRIPT.Difficulty.NORMAL, "reset restores normal difficulty")

	var final_floor_model = RUN_SESSION_MODEL_SCRIPT.new()
	_assert_true(final_floor_model.start_run(SURVIVAL_TUNING_SCRIPT.Difficulty.HELL, 6), "run can start with an explicit difficulty and floor count")
	for floor_index in range(1, 6):
		_assert_true(final_floor_model.prepare_floor(), "floor %d can enter exploration" % floor_index)
		_assert_true(final_floor_model.complete_objective(), "floor %d objective can complete" % floor_index)
		_assert_true(final_floor_model.clear_floor(), "floor %d can clear" % floor_index)
		_assert_true(final_floor_model.start_next_floor(), "floor %d can advance before the final floor" % floor_index)
	_assert_equal(final_floor_model.get_floor_number(), 6, "advancing five times reaches the final floor")
	_assert_true(final_floor_model.is_final_floor(), "the sixth floor is recognized as final")
	_assert_true(final_floor_model.prepare_floor(), "final floor can enter exploration")
	_assert_true(final_floor_model.complete_objective(), "final floor objective can complete")
	_assert_true(final_floor_model.clear_floor(), "final floor can clear")
	_assert_true(not final_floor_model.start_next_floor(), "final floor cannot advance to a seventh floor")
	_assert_true(final_floor_model.complete_run(), "cleared final floor can complete the run")
	_assert_true(not final_floor_model.complete_run(), "completed run rejects duplicate completion")

	var restored_model = RUN_SESSION_MODEL_SCRIPT.new()
	_assert_true(restored_model.restore_snapshot(final_floor_model.create_snapshot()), "session restores a valid snapshot")
	_assert_equal(restored_model.get_floor_number(), 6, "restored session keeps its floor number")
	_assert_equal(restored_model.get_difficulty(), SURVIVAL_TUNING_SCRIPT.Difficulty.HELL, "restored session keeps its difficulty")
	_assert_true(restored_model.is_difficulty_locked(), "restored active history keeps difficulty locked")
	_assert_true(not restored_model.restore_snapshot({}), "session rejects an empty snapshot")
	var unlocked_active_snapshot: Dictionary = final_floor_model.create_snapshot()
	unlocked_active_snapshot["difficulty_locked"] = false
	_assert_true(not restored_model.restore_snapshot(unlocked_active_snapshot), "active session snapshots cannot unlock difficulty")
	var completed_model = RUN_SESSION_MODEL_SCRIPT.new()
	completed_model.start_run()
	completed_model.prepare_floor()
	completed_model.complete_objective()
	_assert_true(completed_model.mark_dead(), "completed objective can enter death state")
	_assert_true(completed_model.revive(), "completed objective can be restored after death")
	_assert_equal(completed_model.get_state(), RUN_STATE_OBJECTIVE_COMPLETE, "revive restores the pre-death state")
	_assert_true(completed_model.pause(), "completed objective state can pause")
	_assert_true(completed_model.resume(), "completed objective state can resume")
	_assert_equal(completed_model.get_state(), RUN_STATE_OBJECTIVE_COMPLETE, "pause resume preserves objective completion")


func _run_random_stream_model_tests() -> void:
	var first = RUN_RANDOM_STREAM_MODEL_SCRIPT.new()
	var second = RUN_RANDOM_STREAM_MODEL_SCRIPT.new()
	_assert_true(first.start(424242, 1), "random streams start from a run seed")
	_assert_true(second.start(424242, 1), "a second stream set accepts the same run seed")
	_assert_equal(first.get_run_seed(), 424242, "random stream model exposes the run seed")
	_assert_equal(first.get_map_seed(), second.get_map_seed(), "same run seed and floor derive the same map seed")
	_assert_equal(
		first.randi_range(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_RESOURCES, 0, 100000),
		second.randi_range(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_RESOURCES, 0, 100000),
		"same named stream produces reproducible values"
	)
	_assert_equal(
		first.get_event_index(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_RESOURCES),
		1,
		"each random draw advances its stream event index"
	)

	var isolated = RUN_RANDOM_STREAM_MODEL_SCRIPT.new()
	var untouched = RUN_RANDOM_STREAM_MODEL_SCRIPT.new()
	isolated.start(8181, 2)
	untouched.start(8181, 2)
	for draw_index in range(5):
		isolated.randi_range(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_TERRAIN, 0, 1000)
	_assert_equal(
		isolated.randi_range(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_DROPS, 0, 100000),
		untouched.randi_range(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_DROPS, 0, 100000),
		"terrain draws do not change the drop stream"
	)

	var floor_one_seed: int = first.get_map_seed()
	_assert_true(first.begin_floor(2), "random streams can begin a later floor")
	_assert_true(first.get_map_seed() != floor_one_seed, "later floors derive a different map seed")
	var same_floor = RUN_RANDOM_STREAM_MODEL_SCRIPT.new()
	same_floor.start(424242, 2)
	_assert_equal(first.get_map_seed(), same_floor.get_map_seed(), "map seed derivation is reproducible per floor")
	_assert_true(not first.begin_floor(0), "random streams reject invalid floor numbers")

	first.randi_range(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_WEATHER, 0, 1000)
	first.randf(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_WEATHER)
	var restored = RUN_RANDOM_STREAM_MODEL_SCRIPT.new()
	_assert_true(restored.restore_snapshot(first.create_snapshot()), "random streams restore a valid snapshot")
	_assert_equal(
		restored.get_event_index(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_WEATHER),
		2,
		"restored random stream keeps its event position"
	)
	_assert_equal(
		first.randi_range(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_WEATHER, 0, 100000),
		restored.randi_range(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_WEATHER, 0, 100000),
		"restored random stream continues with the same next value"
	)
	_assert_true(not restored.restore_snapshot({}), "random streams reject an empty snapshot")


func _run_boss_progress_model_tests() -> void:
	var combat = BOSS_PROGRESS_MODEL_SCRIPT.new()
	_assert_equal(combat.get_phase(), BOSS_PROGRESS_MODEL_SCRIPT.Phase.FIRST, "boss starts in the first combat phase")
	_assert_equal(combat.get_health(), 300.0, "boss starts with three hundred health")
	_assert_true(combat.apply_combat_damage(150.0), "boss accepts combat damage")
	_assert_equal(combat.get_health(), 200.0, "damage clamps at the first phase boundary")
	_assert_equal(combat.get_phase(), BOSS_PROGRESS_MODEL_SCRIPT.Phase.FIRST, "phase does not skip before acknowledgement")
	_assert_true(combat.is_phase_transition_pending(), "crossing a phase boundary exposes a pending transition")
	_assert_true(not combat.apply_combat_damage(1.0), "pending phase transition rejects more damage")
	_assert_true(combat.acknowledge_phase_transition(), "phase transition can be acknowledged")
	_assert_equal(combat.get_phase(), BOSS_PROGRESS_MODEL_SCRIPT.Phase.SECOND, "acknowledgement enters the second phase")
	_assert_true(combat.apply_combat_damage(100.0), "second phase accepts damage")
	_assert_true(combat.acknowledge_phase_transition(), "second phase transition can be acknowledged")
	_assert_equal(combat.get_phase(), BOSS_PROGRESS_MODEL_SCRIPT.Phase.THIRD, "acknowledgement enters the third phase")
	_assert_true(combat.apply_combat_damage(999.0), "third phase accepts lethal damage")
	_assert_equal(combat.get_health(), 0.0, "lethal damage clamps boss health to zero")
	_assert_equal(combat.get_completion_route(), BOSS_PROGRESS_MODEL_SCRIPT.CompletionRoute.COMBAT, "lethal damage completes the combat route")
	_assert_true(not combat.apply_combat_damage(1.0), "completed boss rejects additional combat damage")
	_assert_equal(combat.claim_completion_route(), BOSS_PROGRESS_MODEL_SCRIPT.CompletionRoute.COMBAT, "combat completion can be claimed once")
	_assert_equal(combat.claim_completion_route(), BOSS_PROGRESS_MODEL_SCRIPT.CompletionRoute.NONE, "combat reward cannot be claimed twice")

	var environment = BOSS_PROGRESS_MODEL_SCRIPT.new()
	_assert_true(environment.collect_suppression_component(2), "environment route accepts a valid component")
	_assert_true(not environment.activate_environment_device(0), "device cannot activate before its component is collected")
	_assert_true(environment.collect_suppression_component(0), "environment route accepts components in any collection order")
	_assert_true(environment.collect_suppression_component(1), "environment route accepts the final component")
	_assert_true(environment.activate_environment_device(0), "first environment device activates in sequence")
	_assert_true(not environment.activate_environment_device(2), "environment devices cannot skip sequence positions")
	_assert_true(environment.activate_environment_device(1), "second environment device activates in sequence")
	_assert_true(environment.activate_environment_device(2), "third environment device completes the environment route")
	_assert_equal(environment.get_completion_route(), BOSS_PROGRESS_MODEL_SCRIPT.CompletionRoute.ENVIRONMENT, "three devices complete the environment route")
	_assert_true(not environment.apply_combat_damage(10.0), "environment completion blocks the combat route")
	_assert_equal(environment.claim_completion_route(), BOSS_PROGRESS_MODEL_SCRIPT.CompletionRoute.ENVIRONMENT, "environment completion can be claimed once")
	_assert_equal(environment.claim_completion_route(), BOSS_PROGRESS_MODEL_SCRIPT.CompletionRoute.NONE, "environment reward cannot be claimed twice")

	var mixed = BOSS_PROGRESS_MODEL_SCRIPT.new()
	_assert_true(mixed.collect_suppression_component(0), "mixed route can collect an environmental component")
	_assert_true(mixed.apply_combat_damage(100.0), "mixed route can damage the boss before committing")
	_assert_true(mixed.acknowledge_phase_transition(), "mixed route can acknowledge a combat boundary")
	_assert_true(mixed.collect_suppression_component(1), "mixed route can continue collecting components")
	_assert_true(mixed.collect_suppression_component(2), "mixed route can collect all components")
	_assert_true(mixed.activate_environment_device(0), "mixed route can activate the first device")
	_assert_true(mixed.activate_environment_device(1), "mixed route can activate the second device")
	_assert_true(mixed.activate_environment_device(2), "mixed route can commit to environment completion")
	_assert_true(not mixed.apply_combat_damage(10.0), "committed environment route rejects combat completion")

	var restored = BOSS_PROGRESS_MODEL_SCRIPT.new()
	_assert_true(restored.restore_snapshot(mixed.create_snapshot()), "boss restores a valid snapshot")
	_assert_equal(restored.get_completion_route(), BOSS_PROGRESS_MODEL_SCRIPT.CompletionRoute.ENVIRONMENT, "boss snapshot preserves its completion route")
	_assert_true(not restored.restore_snapshot({}), "boss rejects an empty snapshot")


func _run_run_save_model_tests() -> void:
	var save_model = RUN_SAVE_MODEL_SCRIPT.new("user://afterglow_plan019_test")
	save_model.clear_files()
	_assert_true(not save_model.has_valid_run(), "empty save storage has no valid run")

	var snapshot = RUN_SNAPSHOT_DATA_SCRIPT.new()
	snapshot.run_session_state = {"floor_number": 3, "difficulty": SURVIVAL_TUNING_SCRIPT.Difficulty.HARD}
	snapshot.random_stream_state = {"run_seed": 777, "map_seed": 888}
	snapshot.boss_state = {"phase": 1}
	_assert_true(save_model.save_floor_boundary(snapshot), "valid floor boundary snapshot can be written")
	_assert_true(save_model.save_safe_exit(snapshot), "valid safe-exit snapshot can be written")
	_assert_true(save_model.has_valid_run(), "written safe-exit snapshot is recoverable")
	var loaded = save_model.load_latest()
	_assert_true(loaded != null, "latest save returns a typed snapshot")
	if loaded != null:
		_assert_equal(loaded.run_session_state["floor_number"], 3, "loaded snapshot preserves session state")
		_assert_equal(loaded.random_stream_state["run_seed"], 777, "loaded snapshot preserves random state")
		var legacy_data: Dictionary = snapshot.to_dictionary()
		legacy_data["schema_version"] = 1
		var legacy_loaded: RefCounted = RUN_SNAPSHOT_DATA_SCRIPT.new()
		_assert_true(legacy_loaded.from_dictionary(legacy_data), "version-one run snapshot remains readable")
		_assert_equal(legacy_loaded.schema_version, 2, "version-one snapshot normalizes to the current schema")

	_assert_true(save_model.corrupt_safe_exit_for_test(), "test helper can simulate a corrupt main snapshot")
	var fallback = save_model.load_latest()
	_assert_true(fallback != null, "corrupt main snapshot falls back to floor boundary")
	if fallback != null:
		_assert_equal(fallback.run_session_state["difficulty"], SURVIVAL_TUNING_SCRIPT.Difficulty.HARD, "boundary fallback preserves the last safe state")

	var invalid_version = RUN_SNAPSHOT_DATA_SCRIPT.new()
	invalid_version.schema_version = 999
	_assert_true(not save_model.save_safe_exit(invalid_version), "incompatible snapshot versions are rejected")
	_assert_true(save_model.invalidate_run("settlement-019"), "final settlement writes an invalidation marker")
	_assert_true(not save_model.has_valid_run(), "invalidated run cannot be restored")
	_assert_equal(save_model.load_latest(), null, "invalidated run returns no recoverable snapshot")
	_assert_true(not save_model.save_safe_exit(snapshot), "invalidated storage rejects a new safe-exit snapshot")
	_assert_true(save_model.clear_files(), "save storage can be cleared for the next run")


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
	var restored = RUN_REWARD_MODEL_SCRIPT.new()
	_assert_true(restored.restore_snapshot(model.create_snapshot()), "run reward restores a valid snapshot")
	_assert_equal(restored.get_level(), 4, "run reward snapshot preserves level")
	_assert_equal(restored.get_xp(), 0, "run reward snapshot preserves xp")
	_assert_equal(restored.get_xp_to_next_level(), 100, "run reward snapshot preserves its threshold")
	_assert_true(not restored.restore_snapshot({}), "run reward rejects an empty snapshot")
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
	var infinite_quality_upgrade = UPGRADE_DEFINITION_SCRIPT.new()
	infinite_quality_upgrade.id = &"infinite_quality"
	infinite_quality_upgrade.display_name = "非法品质"
	infinite_quality_upgrade.effect_type = UPGRADE_DEFINITION_SCRIPT.EffectType.DAMAGE_MULTIPLIER
	infinite_quality_upgrade.amount = 0.2
	infinite_quality_upgrade.quality_multiplier = INF
	_assert_true(not infinite_quality_upgrade.is_valid(), "upgrade definition rejects a non-finite quality multiplier")


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
	var vitality_upgrade = UPGRADE_DEFINITION_SCRIPT.new()
	vitality_upgrade.id = &"vitality_test"
	vitality_upgrade.display_name = "活力"
	vitality_upgrade.effect_type = UPGRADE_DEFINITION_SCRIPT.EffectType.MAX_STAMINA_MULTIPLIER
	vitality_upgrade.amount = 0.1
	_assert_true(model.apply_upgrade(vitality_upgrade), "run build accepts a stamina buff")
	_assert_equal(model.get_max_stamina_multiplier(), 1.1, "stamina buff changes max stamina multiplier")
	var luck_upgrade = UPGRADE_DEFINITION_SCRIPT.new()
	luck_upgrade.id = &"luck_test"
	luck_upgrade.display_name = "幸运"
	luck_upgrade.effect_type = UPGRADE_DEFINITION_SCRIPT.EffectType.LUCK
	luck_upgrade.amount = 0.1
	_assert_true(model.apply_upgrade(luck_upgrade), "run build accepts a luck buff")
	_assert_equal(model.get_luck(), 0.1, "luck buff changes run luck")
	var survival_upgrade = UPGRADE_DEFINITION_SCRIPT.new()
	survival_upgrade.id = &"survival_test"
	survival_upgrade.display_name = "节制"
	survival_upgrade.effect_type = UPGRADE_DEFINITION_SCRIPT.EffectType.SURVIVAL_CONSUMPTION_MULTIPLIER
	survival_upgrade.amount = 0.1
	_assert_true(model.apply_upgrade(survival_upgrade), "run build accepts a survival efficiency buff")
	_assert_equal(model.get_survival_consumption_multiplier(), 0.9, "survival buff reduces consumption multiplier")
	var luck_before: float = model.get_luck()
	_assert_true(model.apply_effect(UPGRADE_DEFINITION_SCRIPT.EffectType.LUCK, 0.2, &"luck_quality_test", 1, UPGRADE_DEFINITION_SCRIPT.Quality.EPIC), "run build accepts a quality-scaled luck effect")
	_assert_equal(model.get_luck(), luck_before + 0.2, "quality-scaled luck effect uses the supplied amount")
	luck_upgrade.quality = UPGRADE_DEFINITION_SCRIPT.Quality.EPIC
	_assert_true(model.apply_upgrade(luck_upgrade), "run build accepts a repeated quality buff")
	_assert_equal(model.get_upgrade_quality(&"luck_test"), UPGRADE_DEFINITION_SCRIPT.Quality.EPIC, "run build stores the highest selected quality")
	_assert_equal(model.get_buff_summary().size(), 6, "run build exposes a summary for selected buffs")
	var legacy_snapshot: Dictionary = {"damage_multiplier": 1.2, "move_speed_multiplier": 1.1, "upgrade_stacks": {"legacy": 1}}
	var legacy_model = RUN_BUILD_MODEL_SCRIPT.new()
	_assert_true(legacy_model.restore_snapshot(legacy_snapshot), "run build restores a legacy snapshot")
	_assert_equal(legacy_model.get_max_stamina_multiplier(), 1.0, "legacy snapshot defaults new stamina buff fields")
	_assert_equal(legacy_model.get_upgrade_quality(&"legacy"), UPGRADE_DEFINITION_SCRIPT.Quality.COMMON, "legacy snapshot defaults buff quality")
	var before_invalid_effect: float = model.get_damage_multiplier()
	_assert_true(not model.apply_effect(999, 0.1, &"invalid_effect"), "run build rejects an unknown effect without mutation")
	_assert_equal(model.get_damage_multiplier(), before_invalid_effect, "unknown effect leaves damage unchanged")
	var invalid_snapshot_model = RUN_BUILD_MODEL_SCRIPT.new()
	_assert_true(not invalid_snapshot_model.restore_snapshot({"damage_multiplier": 1.0, "move_speed_multiplier": 1.0, "upgrade_stacks": []}), "run build rejects a snapshot with invalid stack type")
	var guarded_build = RUN_BUILD_MODEL_SCRIPT.new()
	_assert_true(guarded_build.apply_effect(UPGRADE_DEFINITION_SCRIPT.EffectType.DAMAGE_MULTIPLIER, 0.2, &"guard"), "guarded build accepts a baseline effect")
	var guarded_damage: float = guarded_build.get_damage_multiplier()
	_assert_true(
		not guarded_build.restore_snapshot({
			"damage_multiplier": 1.0,
			"move_speed_multiplier": 1.0,
			"max_health_multiplier": INF,
			"upgrade_stacks": {"guard": 1},
		}),
		"run build rejects non-finite extended fields"
	)
	_assert_equal(guarded_build.get_damage_multiplier(), guarded_damage, "invalid build restore keeps prior state")
	_assert_true(
		not guarded_build.restore_snapshot({
			"damage_multiplier": 1.0,
			"move_speed_multiplier": 1.0,
			"upgrade_stacks": {"guard": -1},
		}),
		"run build rejects invalid stack values"
	)
	_assert_true(
		not guarded_build.restore_snapshot({
			"damage_multiplier": 1.0,
			"move_speed_multiplier": 1.0,
			"upgrade_stacks": {"": 1},
		}),
		"run build rejects empty stack ids"
	)
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
	var invalid_cost_spawn: Resource = ENCOUNTER_SPAWN_DEFINITION_SCRIPT.new()
	invalid_cost_spawn.entity_scene = load("res://scenes/objects/chaser_enemy/chaser_enemy.tscn")
	invalid_cost_spawn.threat_cost = 9
	_assert_true(not invalid_cost_spawn.is_valid(), "spawn definition rejects a threat cost above the elite ceiling")
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


func _run_survival_tuning_tests() -> void:
	_assert_approx(
		SURVIVAL_TUNING_SCRIPT.difficulty_resource_richness(SURVIVAL_TUNING_SCRIPT.Difficulty.NORMAL),
		1.0,
		"normal difficulty keeps the full resource budget"
	)
	_assert_approx(
		SURVIVAL_TUNING_SCRIPT.difficulty_resource_richness(SURVIVAL_TUNING_SCRIPT.Difficulty.HARD),
		0.95,
		"hard difficulty slightly reduces resources"
	)
	_assert_approx(
		SURVIVAL_TUNING_SCRIPT.difficulty_consumption_multiplier(SURVIVAL_TUNING_SCRIPT.Difficulty.HELL),
		1.1,
		"hell difficulty raises survival consumption"
	)
	_assert_equal(
		SURVIVAL_TUNING_SCRIPT.disaster_slot_limit(SURVIVAL_TUNING_SCRIPT.Difficulty.NORMAL),
		1,
		"normal difficulty allows one active disaster"
	)
	_assert_equal(
		SURVIVAL_TUNING_SCRIPT.disaster_slot_limit(SURVIVAL_TUNING_SCRIPT.Difficulty.HARD),
		2,
		"hard difficulty allows two active disasters"
	)
	_assert_equal(
		SURVIVAL_TUNING_SCRIPT.disaster_slot_limit(SURVIVAL_TUNING_SCRIPT.Difficulty.HELL),
		-1,
		"hell difficulty has no disaster slot limit"
	)
	_assert_approx(SURVIVAL_TUNING_SCRIPT.disaster_base_probability(1), 0.05, "day one starts at five percent")
	_assert_approx(SURVIVAL_TUNING_SCRIPT.disaster_base_probability(2), 0.10, "day two starts at ten percent")
	_assert_approx(SURVIVAL_TUNING_SCRIPT.disaster_base_probability(8), 0.15, "later days cap at fifteen percent base probability")
	_assert_approx(SURVIVAL_TUNING_SCRIPT.overtime_probability_bonus(0), 0.0, "normal stay has no overtime bonus")
	_assert_approx(SURVIVAL_TUNING_SCRIPT.overtime_probability_bonus(1), 0.05, "first overtime stage adds five percent")
	_assert_approx(SURVIVAL_TUNING_SCRIPT.overtime_probability_bonus(2), 0.10, "second overtime stage adds another five percent")
	_assert_approx(SURVIVAL_TUNING_SCRIPT.overtime_probability_bonus(3), 0.13, "later overtime growth slows to three percent")
	_assert_approx(
		SURVIVAL_TUNING_SCRIPT.difficulty_resource_richness(999),
		1.0,
		"invalid difficulty safely falls back to normal"
	)


func _run_survival_vitals_model_tests() -> void:
	var model = SURVIVAL_VITALS_MODEL_SCRIPT.new()
	_assert_approx(model.get_hunger(), 30.0, "survival hunger starts at the configured low value")
	_assert_approx(model.get_water(), 50.0, "survival water starts at the configured value")
	_assert_approx(model.tick(36.0), 0.0, "ordinary consumption does not immediately deal damage")
	_assert_approx(model.get_hunger(), 29.0, "hunger loses one point every thirty-six seconds")
	_assert_approx(model.get_water(), 50.0 - 36.0 / 27.0, "water continuously consumes fractional points")
	var hunger_before_invalid_tick: float = model.get_hunger()
	_assert_approx(model.tick(-1.0), 0.0, "negative survival delta is rejected")
	_assert_approx(model.get_hunger(), hunger_before_invalid_tick, "negative survival delta preserves state")
	_assert_true(model.consume_food(1000.0), "food can be consumed even when overflow is wasted")
	_assert_approx(model.get_hunger(), 100.0, "food is clamped at the state maximum")
	_assert_true(not model.consume_food(0.0), "zero food is rejected")
	_assert_true(not model.consume_water(-1.0), "negative water is rejected")
	_assert_true(model.consume_water(1000.0), "water overflow follows the same waste rule as food")
	_assert_approx(model.get_water(), 100.0, "water is clamped at the state maximum")

	var depleted = SURVIVAL_VITALS_MODEL_SCRIPT.new(0.0, 0.0)
	_assert_true(depleted.is_critical(), "zero hunger or water is critical")
	_assert_approx(depleted.tick(4.0), 0.0, "the first four zero-state seconds only warn")
	_assert_approx(depleted.tick(1.0), 0.0, "the fifth zero-state second completes the warning")
	_assert_approx(depleted.tick(2.0), 0.02, "environment damage is capped at one percent per second")
	_assert_true(depleted.consume_food(10.0), "food can recover from zero")
	_assert_approx(depleted.tick(1.0), 0.01, "water remaining at zero keeps the shared damage timer active")
	_assert_true(depleted.consume_water(10.0), "water can recover from zero")
	_assert_approx(depleted.tick(1.0), 0.0, "recovering both values clears zero-state damage")

	var crossing_zero = SURVIVAL_VITALS_MODEL_SCRIPT.new(0.1, 100.0)
	_assert_approx(crossing_zero.tick(3.6), 0.0, "time before hunger reaches zero does not count as warning time")
	_assert_approx(crossing_zero.tick(5.0), 0.0, "warning begins when hunger actually reaches zero")
	_assert_approx(crossing_zero.tick(1.0), 0.01, "damage begins after five real seconds at zero")
	var threshold_model: RefCounted = SURVIVAL_VITALS_MODEL_SCRIPT.new(19.0, 19.0)
	_assert_approx(threshold_model.get_stamina_recovery_multiplier(), 0.80, "low hunger reduces stamina recovery")
	_assert_approx(threshold_model.get_healing_multiplier(), 0.70, "low hunger reduces healing")
	_assert_approx(threshold_model.get_stamina_cost_multiplier(), 1.20, "low water increases stamina cost")
	_assert_approx(threshold_model.get_move_speed_multiplier(), 0.95, "low water reduces movement speed")
	threshold_model = SURVIVAL_VITALS_MODEL_SCRIPT.new(4.0, 4.0)
	_assert_approx(threshold_model.get_stamina_recovery_multiplier(), 0.50, "critical hunger heavily reduces stamina recovery")
	_assert_approx(threshold_model.get_healing_multiplier(), 0.0, "critical hunger blocks healing")
	_assert_approx(threshold_model.get_stamina_cost_multiplier(), 1.50, "critical water sharply increases stamina cost")
	_assert_approx(threshold_model.get_move_speed_multiplier(), 0.85, "critical water sharply reduces movement speed")


func _run_survival_clock_model_tests() -> void:
	var model = SURVIVAL_CLOCK_MODEL_SCRIPT.new()
	_assert_equal(model.get_day_index(), 1, "survival clock starts on day one")
	_assert_true(not model.is_night(), "survival clock starts in daytime")
	_assert_true(model.advance(719.0), "positive time advances the clock")
	_assert_true(not model.is_night(), "the final second before night remains daytime")
	_assert_true(model.advance(1.0), "the day boundary can be reached exactly")
	_assert_true(model.is_night(), "twelve minutes enters night")
	_assert_true(model.advance(360.0), "the night duration advances into a new cycle")
	_assert_equal(model.get_day_index(), 2, "a complete cycle advances the day index")
	_assert_true(not model.is_night(), "a new cycle returns to daytime")
	_assert_true(model.advance(2160.0), "large deltas can cross multiple cycles")
	_assert_approx(model.get_elapsed_seconds(), 3240.0, "three cycles equal the normal stay window")
	_assert_equal(model.get_overtime_stage(), 0, "the exact normal stay boundary is not overtime")
	_assert_true(model.advance(0.1), "time beyond the normal window advances")
	_assert_equal(model.get_overtime_stage(), 1, "any time beyond the normal window enters overtime stage one")
	_assert_approx(model.get_overtime_probability_bonus(), 0.05, "overtime stage one exposes its disaster bonus")
	var elapsed_before_invalid_tick: float = model.get_elapsed_seconds()
	_assert_true(not model.advance(-10.0), "negative time is rejected")
	_assert_approx(model.get_elapsed_seconds(), elapsed_before_invalid_tick, "negative time preserves the clock")


func _run_disaster_scheduler_model_tests() -> void:
	var normal_model = DISASTER_SCHEDULER_MODEL_SCRIPT.new(SURVIVAL_TUNING_SCRIPT.Difficulty.NORMAL)
	_assert_true(not normal_model.should_check(59.0), "disaster scheduler waits for the full check interval")
	_assert_true(normal_model.should_check(1.0), "disaster scheduler checks every sixty seconds")
	_assert_true(not normal_model.should_check(0.0), "a consumed interval does not check twice")
	_assert_approx(normal_model.get_trigger_probability(0.0), 0.05, "normal day one disaster probability starts at five percent")
	normal_model.register_miss()
	normal_model.register_miss()
	_assert_approx(normal_model.get_trigger_probability(0.0), 0.15, "missed checks add five percent each")
	_assert_true(
		normal_model.register_trigger(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.RAINSTORM, 120.0),
		"a new disaster kind can be registered"
	)
	_assert_approx(normal_model.get_trigger_probability(0.0), 0.05, "a successful trigger resets the miss bonus")
	_assert_true(
		not normal_model.can_trigger_kind(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.RAINSTORM, 719.0),
		"same disaster remains blocked before both cooldown conditions"
	)
	_assert_true(
		normal_model.register_trigger(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.HEATWAVE, 300.0),
		"a different disaster advances the event sequence"
	)
	_assert_true(
		normal_model.register_trigger(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.DENSE_FOG, 500.0),
		"a second different disaster satisfies the event-count cooldown"
	)
	_assert_true(
		normal_model.can_trigger_kind(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.RAINSTORM, 720.0),
		"same disaster unlocks after ten minutes and two other events"
	)

	var full_slot_rng := RandomNumberGenerator.new()
	full_slot_rng.seed = 7
	_assert_true(
		not normal_model.roll_trigger(full_slot_rng, 1000.0, 1),
		"normal difficulty skips rolls while its disaster slot is full"
	)
	var first_day_rng := RandomNumberGenerator.new()
	first_day_rng.seed = 11
	var first_day_kind: int = normal_model.roll_disaster_kind(first_day_rng, 100.0, false)
	_assert_true(
		first_day_kind >= DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.RAINSTORM \
		and first_day_kind <= DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.SPAWN_MIGRATION,
		"day one only selects a normal disaster"
	)

	var deterministic_a = DISASTER_SCHEDULER_MODEL_SCRIPT.new(SURVIVAL_TUNING_SCRIPT.Difficulty.HARD)
	var deterministic_b = DISASTER_SCHEDULER_MODEL_SCRIPT.new(SURVIVAL_TUNING_SCRIPT.Difficulty.HARD)
	var rng_a := RandomNumberGenerator.new()
	var rng_b := RandomNumberGenerator.new()
	rng_a.seed = 20260827
	rng_b.seed = 20260827
	_assert_equal(
		deterministic_a.roll_disaster_kind(rng_a, 2000.0, true),
		deterministic_b.roll_disaster_kind(rng_b, 2000.0, true),
		"injected random generators make disaster selection reproducible"
	)


func _run_resource_budget_model_tests() -> void:
	var normal = RESOURCE_BUDGET_MODEL_SCRIPT.new(SURVIVAL_TUNING_SCRIPT.Difficulty.NORMAL)
	_assert_equal(normal.get_guaranteed_food(), 9, "normal map guarantees nine food units")
	_assert_equal(normal.get_guaranteed_water(), 12, "normal map guarantees twelve water units")
	_assert_equal(normal.get_emergency_food(), 2, "normal map adds a twenty percent emergency food reserve")
	_assert_equal(normal.get_emergency_water(), 3, "normal map adds a twenty percent emergency water reserve")
	_assert_equal(normal.get_total_food(), 11, "normal total food includes the emergency reserve")
	_assert_equal(normal.get_total_water(), 15, "normal total water includes the emergency reserve")
	var hard = RESOURCE_BUDGET_MODEL_SCRIPT.new(SURVIVAL_TUNING_SCRIPT.Difficulty.HARD)
	_assert_equal(hard.get_guaranteed_food(), 9, "hard food guarantee rounds without dropping below baseline")
	_assert_equal(hard.get_guaranteed_water(), 11, "hard water guarantee applies resource richness")
	var hell = RESOURCE_BUDGET_MODEL_SCRIPT.new(SURVIVAL_TUNING_SCRIPT.Difficulty.HELL)
	_assert_equal(hell.get_guaranteed_food(), 8, "hell food guarantee reflects the harshest richness")
	_assert_equal(hell.get_guaranteed_water(), 11, "hell water guarantee keeps at least eleven units")
	var invalid = RESOURCE_BUDGET_MODEL_SCRIPT.new(999)
	_assert_equal(invalid.get_guaranteed_food(), 9, "invalid difficulty falls back to normal resource richness")


func _run_escape_objective_model_tests() -> void:
	var model = ESCAPE_OBJECTIVE_MODEL_SCRIPT.new()
	_assert_equal(model.get_required_amount(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MaterialType.PARTS), 2, "escape objective requires two parts")
	_assert_equal(model.get_required_amount(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MaterialType.FUEL), 2, "escape objective requires two fuel units")
	_assert_equal(model.get_required_amount(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MaterialType.CLOTH), 2, "escape objective requires two cloth units")
	_assert_equal(model.get_required_amount(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MaterialType.KEY), 1, "escape objective requires one key")
	_assert_true(not model.has_all_materials(), "escape objective starts incomplete")
	_assert_true(model.collect_material(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MaterialType.PARTS), "objective accepts a valid material pickup")
	_assert_equal(model.get_collected_amount(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MaterialType.PARTS), 1, "objective tracks collected material")
	_assert_true(model.collect_material(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MaterialType.PARTS, 9), "objective accepts an overflowing pickup")
	_assert_equal(model.get_collected_amount(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MaterialType.PARTS), 2, "material pickup clamps to its requirement")
	_assert_true(not model.collect_material(999), "objective rejects an invalid material type")
	_assert_true(not model.advance_exit_startup(1.0, false, false, false), "exit cannot start before materials are complete")
	_assert_true(model.collect_material(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MaterialType.FUEL, 2), "fuel requirement can be completed")
	_assert_true(model.collect_material(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MaterialType.CLOTH, 2), "cloth requirement can be completed")
	_assert_true(model.collect_material(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MaterialType.KEY), "key requirement can be completed")
	_assert_true(model.has_all_materials(), "all escape materials can be completed")
	_assert_true(not model.advance_exit_startup(2.0, true, false, false), "movement interrupts exit startup")
	_assert_approx(model.get_exit_startup_seconds(), 0.0, "interrupted startup keeps zero progress")
	_assert_true(not model.advance_exit_startup(4.0, false, true, false), "being hit interrupts exit startup")
	_assert_true(model.advance_exit_startup(4.0, false, false, false) == false, "partial exit startup remains incomplete")
	_assert_approx(model.get_exit_startup_seconds(), 4.0, "exit startup retains partial progress")
	_assert_true(not model.advance_exit_startup(1.0, false, false, true), "nearby enemies interrupt exit startup")
	_assert_approx(model.get_exit_startup_seconds(), 4.0, "enemy interruption retains partial progress")
	_assert_true(model.advance_exit_startup(6.0, false, false, false), "ten seconds completes exit startup")
	_assert_true(model.is_exit_started(), "completed startup exposes started state")
	_assert_true(model.consume_for_departure(), "completed exit can consume current map materials")
	_assert_true(not model.has_all_materials(), "departure clears current map material progress")
	_assert_true(not model.is_exit_started(), "departure clears startup state")
	_assert_true(not model.consume_for_departure(), "departure cannot consume materials twice")


func _run_threat_budget_model_tests() -> void:
	var model = THREAT_BUDGET_MODEL_SCRIPT.new(1, 0)
	_assert_equal(model.get_base_budget(1, 0), 12, "day one threat budget starts at twelve")
	_assert_equal(model.get_base_budget(2, 0), 15, "day two threat budget rises to fifteen")
	_assert_equal(model.get_base_budget(3, 0), 18, "day three threat budget rises to eighteen")
	var first_overtime_budget: int = model.get_base_budget(3, 1)
	var later_overtime_budget: int = model.get_base_budget(3, 4)
	_assert_true(first_overtime_budget > 18, "overtime increases the threat budget")
	_assert_true(
		later_overtime_budget - first_overtime_budget < first_overtime_budget - 18 + 3,
		"later overtime budget growth has diminishing marginal gains"
	)
	_assert_equal(model.get_active_budget(), 12, "active budget uses the current time context")
	_assert_equal(model.get_active_budget(0.5), 18, "monster surge adds fifty percent temporary budget")
	_assert_true(model.set_disaster_bonus_ratio(0.5), "disaster bonus can be stored as runtime context")
	_assert_equal(model.get_active_budget(), 18, "stored disaster bonus affects the active budget")
	_assert_true(model.set_disaster_bonus_ratio(0.0), "disaster bonus can return to baseline")
	_assert_true(model.register_spawn(8), "an elite-cost spawn can reserve budget")
	_assert_true(model.register_spawn(4), "a special-cost spawn can fill the remaining budget")
	_assert_true(not model.register_spawn(1), "spawns cannot exceed the active threat budget")
	_assert_true(not model.register_spawn(0), "zero-cost spawns are rejected")
	_assert_true(not model.register_spawn(9), "costs above the first-version elite ceiling are rejected")
	_assert_equal(model.get_used_budget(), 12, "rejected spawns do not change used budget")
	_assert_true(model.release_spawn(4), "despawned enemies release their reserved budget")
	_assert_true(not model.release_spawn(9), "release cannot exceed used budget")
	_assert_equal(model.get_used_budget(), 8, "invalid release preserves used budget")
	_assert_true(model.set_time_context(3, 0), "time context can advance without losing reservations")
	_assert_equal(model.get_active_budget(), 18, "updated time context exposes the later-day budget")


func _run_spawn_protection_model_tests() -> void:
	var model = SPAWN_PROTECTION_MODEL_SCRIPT.new()
	var player_position := Vector2.ZERO
	var protected_points: Array[Vector2] = [Vector2(20.0, 0.0)]
	var no_protected_points: Array[Vector2] = []
	_assert_true(
		model.is_protected(Vector2(7.99, 0.0), player_position, no_protected_points, false, true),
		"spawn points closer than eight steps to the player are protected"
	)
	_assert_true(
		model.is_valid_spawn(Vector2(8.0, 0.0), player_position, no_protected_points, false, true),
		"a hidden fog point exactly eight steps away is valid"
	)
	_assert_true(
		model.is_protected(Vector2(20.0, 0.0), player_position, protected_points, false, true),
		"entrance, exit, campfire, objective and respawn points share a protection radius"
	)
	_assert_true(
		model.is_protected(Vector2(12.0, 0.0), player_position, no_protected_points, true, true),
		"visible points are protected from spawning"
	)
	_assert_true(
		model.is_protected(Vector2(12.0, 0.0), player_position, no_protected_points, false, false),
		"points outside fog are protected from spawning"
	)


func _run_enemy_perception_model_tests() -> void:
	var model = ENEMY_PERCEPTION_MODEL_SCRIPT.new()
	_assert_equal(model.get_state(), ENEMY_PERCEPTION_MODEL_SCRIPT.State.SEARCHING, "enemy perception starts searching")
	_assert_true(
		not model.observe_visual(Vector2(4.0, 0.0), false, 1.0, 0.5),
		"blocked vision cannot acquire the player"
	)
	_assert_true(
		not model.observe_visual(Vector2(4.0, 0.0), true, 0.25, 0.5),
		"targets below the brightness threshold are not acquired"
	)
	_assert_true(
		model.observe_visual(Vector2(4.0, 0.0), true, 0.5, 0.5),
		"visible targets at the threshold are acquired"
	)
	_assert_equal(model.get_state(), ENEMY_PERCEPTION_MODEL_SCRIPT.State.TRACKING, "visual acquisition enters tracking")
	_assert_equal(model.get_last_known_position(), Vector2(4.0, 0.0), "visual acquisition stores the observed position")
	_assert_true(not model.advance(8.0), "tracking remains certain for the first eight seconds without a clue")
	_assert_approx(model.get_confidence(), 1.0, "confidence starts falling only after eight seconds")
	_assert_true(not model.advance(3.5), "partial confidence decay keeps the enemy tracking")
	_assert_true(model.get_confidence() < 1.0, "confidence decays after the grace period")
	_assert_true(model.advance(3.5), "fifteen seconds without a clue transitions to searching")
	_assert_equal(model.get_state(), ENEMY_PERCEPTION_MODEL_SCRIPT.State.SEARCHING, "ordinary enemies stop permanent tracking")
	_assert_true(model.hear_sound(Vector2(6.0, 2.0), 8.0, 1.0), "a valid sound creates an investigation clue")
	_assert_equal(model.get_state(), ENEMY_PERCEPTION_MODEL_SCRIPT.State.INVESTIGATING, "sound enters investigating state")
	_assert_equal(model.get_last_known_position(), Vector2(6.0, 2.0), "sound stores only its occurrence position")
	_assert_true(not model.hear_sound(Vector2.ZERO, 0.0, 1.0), "zero-radius sounds are rejected")
	var weak_sound = ENEMY_PERCEPTION_MODEL_SCRIPT.new()
	weak_sound.hear_sound(Vector2.ONE, 4.0, 0.25)
	var weak_confidence: float = weak_sound.get_confidence()
	weak_sound.advance(9.0)
	_assert_true(weak_sound.get_confidence() <= weak_confidence, "weak sound confidence never rises while its clue ages")


func _run_disaster_event_model_tests() -> void:
	var normal = DISASTER_EVENT_MODEL_SCRIPT.new()
	_assert_true(
		normal.start_warning(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.RAINSTORM, 120.0),
		"an idle event can enter warning"
	)
	_assert_equal(normal.get_phase(), DISASTER_EVENT_MODEL_SCRIPT.Phase.WARNING, "disaster starts in warning phase")
	_assert_approx(normal.get_remaining_seconds(), 10.0, "warning exposes a ten-second countdown")
	_assert_true(
		not normal.start_warning(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.RAINSTORM, 121.0),
		"an active event instance rejects duplicate starts"
	)
	_assert_true(normal.advance(10.0), "ten seconds advances warning into the active phase")
	_assert_equal(normal.get_phase(), DISASTER_EVENT_MODEL_SCRIPT.Phase.ACTIVE, "warning completion activates the disaster")
	_assert_true(normal.get_remaining_seconds() >= 120.0, "normal disaster duration is at least two minutes")
	_assert_true(normal.get_remaining_seconds() <= 240.0, "normal disaster duration is at most four minutes")
	_assert_true(not normal.complete_countermeasure(), "normal disasters are not resolved by the unique hard-disaster facility")
	var overshoot = DISASTER_EVENT_MODEL_SCRIPT.new()
	overshoot.start_warning(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.RAINSTORM, 120.0)
	_assert_true(overshoot.advance(11.0), "a large tick crosses warning and enters the active phase")
	_assert_approx(overshoot.get_remaining_seconds(), 239.0, "warning overshoot consumes one second of active disaster time")

	var hard = DISASTER_EVENT_MODEL_SCRIPT.new()
	_assert_true(
		hard.start_warning(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.HUNTER, 240.0),
		"a hard disaster can enter warning"
	)
	hard.advance(10.0)
	_assert_true(hard.get_remaining_seconds() >= 240.0, "hard disaster duration is at least four minutes")
	_assert_true(hard.get_remaining_seconds() <= 360.0, "hard disaster duration is at most six minutes")
	_assert_true(hard.advance_countermeasure(4.0), "hard disaster accepts partial facility progress")
	_assert_approx(hard.get_countermeasure_progress(), 4.0, "facility progress is recorded by the event model")
	_assert_true(hard.interrupt_countermeasure(), "facility interaction can be interrupted")
	_assert_approx(hard.get_countermeasure_progress(), 4.0, "interruption preserves facility progress")
	_assert_true(hard.advance_countermeasure(6.0), "the remaining facility progress resolves the hard disaster")
	_assert_true(hard.is_resolved(), "completed primary countermeasure marks the event resolved")
	_assert_true(not hard.is_active(), "resolved disasters no longer occupy an active slot")
	var failed_hard = DISASTER_EVENT_MODEL_SCRIPT.new()
	failed_hard.start_warning(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.HUNTER, 240.0)
	failed_hard.advance(10.0)
	_assert_true(failed_hard.advance(360.0), "a hard disaster eventually leaves its active phase")
	_assert_true(not failed_hard.is_resolved(), "hard disaster expiry is not treated as successful countermeasure resolution")
	_assert_true(failed_hard.has_failed(), "hard disaster expiry records a failed outcome")


func _run_meta_progression_model_tests() -> void:
	var model = META_PROGRESSION_MODEL_SCRIPT.new()
	_assert_true(model.has_method("get_crystal_tier"), "meta progression exposes cumulative crystal tier")
	_assert_true(model.has_method("get_attribute_point_bonus"), "meta progression exposes tier attribute point rewards")
	if model.has_method("get_crystal_tier") and model.has_method("get_attribute_point_bonus"):
		var ranked_meta: RefCounted = META_PROGRESSION_MODEL_SCRIPT.new()
		_assert_true(ranked_meta.add_crystals(160), "ranked meta accepts cumulative crystals")
		_assert_equal(ranked_meta.get_crystal_tier(), 5, "one hundred sixty cumulative crystals reaches tier five")
		_assert_equal(ranked_meta.get_attribute_point_bonus(), 25, "tier five grants twenty-five additional run allocation points")
		_assert_true(ranked_meta.purchase_initial_buff(&"damage", 100), "ranked meta can spend wallet crystals")
		_assert_equal(ranked_meta.get_crystal_tier(), 5, "spending wallet crystals does not lower cumulative tier")
		var ranked_snapshot: Dictionary = ranked_meta.create_snapshot()
		var restored_ranked_meta: RefCounted = META_PROGRESSION_MODEL_SCRIPT.new()
		_assert_true(restored_ranked_meta.restore_snapshot(ranked_snapshot), "ranked meta snapshot restores cumulative crystals")
		_assert_equal(restored_ranked_meta.get_attribute_point_bonus(), 25, "ranked meta snapshot preserves tier rewards")
	_assert_equal(model.get_crystals(), 0, "meta progression starts with zero crystals")
	_assert_true(model.add_crystals(20), "meta progression accepts positive crystals")
	_assert_true(not model.add_crystals(0), "meta progression rejects zero crystals")
	_assert_true(model.purchase_initial_buff(&"damage", 10), "meta progression purchases an initial buff")
	_assert_equal(model.get_initial_buff_level(&"damage"), 1, "initial buff level is stored permanently")
	_assert_equal(model.get_crystals(), 10, "initial buff purchase consumes crystals")
	_assert_true(model.equip_initial_buff(&"damage"), "one initial buff can be equipped")
	_assert_equal(model.get_equipped_initial_buff(), &"damage", "equipped initial buff is queryable")
	_assert_true(model.purchase_reroll_level(5), "meta progression purchases reroll capacity")
	_assert_equal(model.get_reroll_level(), 1, "reroll level is stored permanently")
	_assert_equal(model.get_run_reroll_charges(), 1, "reroll level grants one run charge")
	var snapshot: Dictionary = model.create_snapshot()
	var restored = META_PROGRESSION_MODEL_SCRIPT.new()
	_assert_true(restored.restore_snapshot(snapshot), "meta progression restores a valid snapshot")
	_assert_equal(restored.get_equipped_initial_buff(), &"damage", "meta snapshot preserves equipped buff")
	var legacy = META_PROGRESSION_MODEL_SCRIPT.new()
	_assert_true(legacy.restore_snapshot({"meta_crystals": 7}), "legacy meta snapshot restores with defaults")
	_assert_equal(legacy.get_crystals(), 7, "legacy meta snapshot preserves crystals")
	var guarded_meta = META_PROGRESSION_MODEL_SCRIPT.new()
	_assert_true(guarded_meta.add_crystals(20), "guarded meta accepts baseline crystals")
	_assert_true(guarded_meta.purchase_initial_buff(&"damage", 10), "guarded meta accepts baseline upgrade")
	var guarded_meta_crystals: int = guarded_meta.get_crystals()
	_assert_true(not guarded_meta.restore_snapshot({"meta_crystals": "invalid"}), "meta snapshot rejects invalid crystal type")
	_assert_equal(guarded_meta.get_crystals(), guarded_meta_crystals, "invalid meta restore keeps prior state")
	_assert_true(
		not guarded_meta.restore_snapshot({"meta_crystals": 10, "initial_buff_levels": {"damage": -1}}),
		"meta snapshot rejects invalid upgrade levels"
	)
	_assert_equal(guarded_meta.get_initial_buff_level(&"damage"), 1, "invalid meta level restore keeps prior upgrade")
	var alias_meta = META_PROGRESSION_MODEL_SCRIPT.new()
	_assert_true(alias_meta.add_crystals(10), "alias meta accepts crystals")
	_assert_true(alias_meta.purchase_initial_buff(&"speed", 10), "legacy speed alias can be purchased")
	_assert_equal(alias_meta.get_initial_buff_level(&"move_speed"), 1, "speed alias is stored under canonical move speed id")


func _run_run_buff_draft_model_tests() -> void:
	var model = RUN_BUFF_DRAFT_MODEL_SCRIPT.new(1234)
	_assert_equal(model.get_luck(), 0.0, "run buff draft starts with zero luck")
	_assert_true(model.add_reroll_charges(2), "run buff draft accepts run reroll charges")
	_assert_equal(model.get_reroll_charges(), 2, "run reroll charges are queryable")
	var candidates: Array = model.generate_candidates([&"damage", &"speed", &"luck", &"vitality"], 4)
	_assert_equal(candidates.size(), 4, "draft generates four candidates")
	_assert_equal(candidates.size(), (candidates as Array).duplicate().size(), "candidate collection is stable")
	_assert_true(model.consume_reroll(), "draft consumes a reroll charge")
	_assert_equal(model.get_reroll_charges(), 1, "reroll charge decrements")
	_assert_true(model.apply_candidate(&"luck"), "luck candidate can be selected")
	_assert_true(model.get_luck() > 0.0, "luck candidate increases current luck")
	_assert_true(model.apply_candidate(&"damage"), "ordinary candidate can be selected")
	_assert_equal(model.get_buff_stack(&"damage"), 1, "duplicate-aware stack count starts at one")
	_assert_true(model.apply_candidate(&"damage"), "duplicate candidate can be selected again")
	_assert_equal(model.get_buff_stack(&"damage"), 2, "duplicate candidate increments stack count")
	var draft_snapshot: Dictionary = model.create_snapshot()
	var restored = RUN_BUFF_DRAFT_MODEL_SCRIPT.new(1)
	_assert_true(restored.restore_snapshot(draft_snapshot), "draft restores a valid snapshot")
	_assert_equal(restored.get_buff_stack(&"damage"), 2, "draft snapshot preserves duplicate stacks")
	var guarded_draft = RUN_BUFF_DRAFT_MODEL_SCRIPT.new(9)
	_assert_true(guarded_draft.add_luck(0.3), "guarded draft accepts baseline luck")
	_assert_true(guarded_draft.add_reroll_charges(1), "guarded draft accepts baseline reroll")
	_assert_true(guarded_draft.apply_candidate(&"damage"), "guarded draft accepts baseline stack")
	var guarded_draft_luck: float = guarded_draft.get_luck()
	_assert_true(
		not guarded_draft.restore_snapshot({"luck": INF, "reroll_charges": 0, "stacks": {"damage": 1}}),
		"draft snapshot rejects non-finite luck"
	)
	_assert_equal(guarded_draft.get_luck(), guarded_draft_luck, "invalid draft restore keeps prior luck")
	_assert_true(
		not guarded_draft.restore_snapshot({"luck": 0.0, "reroll_charges": 0, "stacks": {"damage": -1}}),
		"draft snapshot rejects invalid stack values"
	)
	_assert_true(
		not guarded_draft.restore_snapshot({"luck": 0.0, "reroll_charges": 0, "stacks": {"": 1}}),
		"draft snapshot rejects empty stack ids"
	)


func _run_plan040_model_tests() -> void:
	_assert_equal(STEP_TERRAIN_MODEL_SCRIPT.pixels_to_steps(40.0), 1, "forty pixels equal one step")
	_assert_equal(STEP_TERRAIN_MODEL_SCRIPT.pixels_to_steps(-120.0), 3, "step conversion uses absolute distance")
	_assert_approx(STEP_TERRAIN_MODEL_SCRIPT.steps_to_pixels(3), 120.0, "three steps convert to one hundred twenty pixels")
	_assert_true(STEP_TERRAIN_MODEL_SCRIPT.can_vault(2, false, 1.2), "regular vault accepts two steps")
	_assert_true(not STEP_TERRAIN_MODEL_SCRIPT.can_vault(3, false, 1.2), "high vault is required for three steps")
	_assert_true(STEP_TERRAIN_MODEL_SCRIPT.can_vault(3, true, 1.2), "high vault accepts three steps")
	_assert_true(not STEP_TERRAIN_MODEL_SCRIPT.can_vault(4, true, 1.2), "four steps cannot be vaulted")

	var vault = VAULT_ACTION_MODEL_SCRIPT.new(2.0, 1.0)
	_assert_true(vault.try_start(2, false, 2.0), "vault starts when height and stamina are valid")
	_assert_equal(vault.get_state(), 1, "vault enters active state")
	_assert_true(not vault.try_start(2, false, 1.0), "active vault rejects duplicate start")
	vault.advance(2.0)
	_assert_equal(vault.get_state(), 0, "vault completes after its duration")
	_assert_true(vault.try_start(3, true, 2.0), "high vault starts with the ability")
	vault.cancel()
	_assert_equal(vault.get_state(), 0, "vault cancellation returns to idle")
	_assert_true(not vault.try_start(2, false, 0.5), "vault rejects insufficient stamina")

	var digging = DIGGING_MODEL_SCRIPT.new(2.0, 3.0)
	_assert_true(digging.try_start(1, 1, 2), "dirt can be dug within depth and durability")
	_assert_equal(digging.get_state(), 1, "digging enters active state")
	_assert_true(digging.advance(2.0), "digging completes after configured time")
	_assert_equal(digging.get_terrain_depth(), 0, "completed digging lowers terrain depth")
	_assert_equal(digging.get_shovel_durability(), 1, "digging consumes one shovel durability")
	_assert_true(not digging.try_start(5, 1, 1), "stone is not diggable")
	_assert_true(not digging.try_start(1, 4, 1), "digging rejects more than three downward steps")
	_assert_true(digging.try_start(1, 1, 1), "digging can be restarted on a remaining layer")
	_assert_true(digging.cancel(), "digging cancellation is explicit")

	var water = WATER_TRAVERSAL_MODEL_SCRIPT.new(10.0, 2.0)
	_assert_approx(water.get_speed_multiplier(0), 1.0, "shallow water keeps normal speed")
	_assert_approx(water.get_speed_multiplier(2), 0.55, "deep water slows movement")
	_assert_true(water.can_enter(2, 1.3), "swimming is allowed below the encumbrance limit")
	_assert_true(not water.can_enter(2, 1.5), "overloaded player cannot start swimming")
	water.start(2)
	water.tick(1.0, true)
	_assert_equal(water.get_state(), 1, "water traversal enters swimming state")
	water.tick(5.0, true)
	_assert_true(water.is_drowning(), "zero stamina in deep water starts drowning buffer")
	_assert_true(water.get_drowning_buffer() < 3.0, "drowning buffer decreases while exhausted")
	var water_snapshot: Dictionary = water.create_snapshot()
	var restored_water = WATER_TRAVERSAL_MODEL_SCRIPT.new()
	_assert_true(restored_water.restore_snapshot(water_snapshot), "water traversal restores a valid snapshot")
	_assert_equal(restored_water.get_depth_steps(), 2, "water snapshot preserves depth")
	_assert_true(not restored_water.restore_snapshot({"format_version": 1, "state": 99}), "water snapshot rejects invalid state")

	var routes = ROUTE_VALIDATION_MODEL_SCRIPT.new()
	_assert_true(routes.validate(&"start", &"exit", [routes.edge(&"start", &"exit", 0)]).is_empty(), "base route reaches exit")
	_assert_true(not routes.validate(&"start", &"exit", [routes.edge(&"start", &"cliff", 4), routes.edge(&"cliff", &"exit", 0)]).is_empty(), "tool-only route is rejected")
	_assert_true(not routes.validate(&"start", &"exit", [routes.edge(&"start", &"dead", 0)]).is_empty(), "missing exit route is rejected")


func _run_plan041_model_tests() -> void:
	var resolver = ENVIRONMENT_EFFECT_RESOLVER_SCRIPT.new()
	var rain: Dictionary = resolver.resolve(&"rain", [], 2, false)
	_assert_equal(int(rain.get("water_level_delta", 0)), 1, "rain raises the local water level by one step")
	_assert_approx(float(rain.get("campfire_burn_multiplier", 0.0)), 1.5, "rain accelerates exposed campfire burn")
	var combined: Dictionary = resolver.resolve(&"heatwave", [0, 4], 3, false)
	_assert_true(float(combined.get("stamina_drain_multiplier", 0.0)) <= 2.0, "combined effects use a finite stamina cap")
	_assert_true(float(combined.get("monster_spawn_multiplier", 0.0)) >= 1.0, "monster surge increases spawn pressure")
	_assert_true(float(combined.get("water_level_delta", 0.0)) <= 0.0, "heatwave lowers water level")
	var sheltered: Dictionary = resolver.resolve(&"rain", [0], 1, true)
	_assert_approx(float(sheltered.get("campfire_burn_multiplier", 0.0)), 1.0, "shelter removes exposed rain burn penalty")
	_assert_true(float(sheltered.get("hazard_damage_per_second", 0.0)) >= 0.0, "environment damage is explicit and bounded")

	var countermeasures = DISASTER_COUNTERMEASURE_MODEL_SCRIPT.new()
	_assert_true(countermeasures.get_options(0).size() >= 2, "ordinary disaster exposes at least two countermeasure options")
	_assert_true(countermeasures.can_resolve(0, &"shelter"), "ordinary disaster accepts a shelter response")
	_assert_true(countermeasures.can_resolve(0, &"evacuate"), "ordinary disaster accepts an evacuation response")
	_assert_true(countermeasures.get_options(6).size() == 1, "hard disaster exposes one primary countermeasure")
	_assert_true(countermeasures.can_resolve(6, countermeasures.get_options(6)[0]), "hard disaster accepts its primary facility")
	_assert_true(not countermeasures.can_resolve(6, &"shelter"), "hard disaster shelter only delays the threat")


func _run_plan042_model_tests() -> void:
	var profile = REGION_PROFILE_MODEL_SCRIPT.new()
	_assert_true(profile.get_profile(&"flooded_settlement").has("water_depth_bias"), "flooded settlement profile exposes water pressure")
	_assert_true(profile.get_profile(&"abandoned_industry").has("digging_bias"), "industrial profile exposes digging pressure")
	_assert_true(profile.get_profile(&"polluted_forest").has("fog_bias"), "polluted forest profile exposes fog pressure")
	var route_model = REGION_ROUTE_MODEL_SCRIPT.new()
	var generated: Dictionary = route_model.generate(3, 12345)
	_assert_equal(generated.get("region_id"), &"flooded_settlement", "floor three route generation selects the flooded settlement")
	_assert_true((generated.get("routes", []) as Array).size() >= 2, "generated region exposes base and ability routes")
	_assert_true(route_model.validate_generated(generated).is_empty(), "generated route profile passes deterministic validation")
	var repeat: Dictionary = route_model.generate(3, 12345)
	_assert_equal(generated, repeat, "same floor seed generates the same route profile")


func _run_plan043_model_tests() -> void:
	var readiness = RELEASE_READINESS_MODEL_SCRIPT.new()
	_assert_true(readiness.validate_difficulty_profiles().is_empty(), "difficulty profiles stay within release bounds")
	_assert_true(readiness.validate_snapshot_size({"small": "state"}).is_empty(), "small snapshots pass the release size check")
	_assert_true(not readiness.validate_snapshot_size({"state": "x".repeat(2000000)}).is_empty(), "oversized snapshots are rejected")
	_assert_true(readiness.run_long_tick_simulation(6, 120.0), "long-run simulation completes all six floor ticks")
	var accessibility = ACCESSIBILITY_SETTINGS_MODEL_SCRIPT.new()
	_assert_true(accessibility.set_text_scale(1.25), "accessibility text scale accepts a readable value")
	_assert_true(accessibility.set_color_redundancy(true), "accessibility keeps redundant non-color cues enabled")
	_assert_true(accessibility.set_flash_intensity(0.0), "accessibility can disable flashing")
	_assert_true(not accessibility.set_text_scale(0.2), "accessibility rejects unreadable text scale")
	var accessibility_snapshot: Dictionary = accessibility.create_snapshot()
	var restored_accessibility = ACCESSIBILITY_SETTINGS_MODEL_SCRIPT.new()
	_assert_true(restored_accessibility.restore_snapshot(accessibility_snapshot), "accessibility settings restore")
	var telemetry = LOCAL_TELEMETRY_MODEL_SCRIPT.new()
	_assert_true(telemetry.record_death(&"dehydration"), "local telemetry records a death reason")
	_assert_true(telemetry.record_floor_departure(184.0, 3), "local telemetry records a floor departure")
	var telemetry_snapshot: Dictionary = telemetry.create_snapshot()
	_assert_true(telemetry_snapshot.has("death_reasons"), "local telemetry snapshot exposes aggregate counters")
	_assert_true(telemetry.clear(), "local telemetry can be cleared")
	_assert_equal(telemetry.create_snapshot().get("death_reasons", {}).size(), 0, "clearing telemetry removes local counters")
