extends Node

const BASEMENT_SCENE: PackedScene = preload("res://scenes/world/basement/basement.tscn")
const CIHANG_SCENE: PackedScene = preload("res://scenes/world/cihang_outskirts/cihang_outskirts.tscn")
const FINAL_CORE_SCENE: PackedScene = preload("res://scenes/world/final_core/final_core.tscn")
const START_SCREEN_SCENE: PackedScene = preload("res://scenes/flow/start_screen.tscn")
const PICKUP_OVERLAP_SCENE: PackedScene = preload("res://tests/pickup_overlap_test.tscn")
const CONTENT_VALIDATION_MODEL_SCRIPT: Script = preload("res://scripts/data/content_validation_model.gd")
const HEALTH_COMPONENT_SCRIPT: Script = preload("res://scripts/components/health_component.gd")
const RECORDING_PRESENTER_SCRIPT: Script = preload("res://tests/recording_actor_presenter.gd")
const WOOD_ITEM: ItemData = preload("res://assets/items/wood.tres")
const RATION_ITEM: ItemData = preload("res://assets/items/ration.tres")
const PISTOL_ITEM: ItemData = preload("res://assets/items/handmade_pistol.tres")
const PISTOL_AMMO_ITEM: ItemData = preload("res://assets/items/pistol_ammo.tres")
const FIELD_PACK_ITEM: ItemData = preload("res://assets/items/field_pack.tres")
const PLAYER_COMMAND_SCRIPT: Script = preload("res://scripts/player/player_command.gd")

var _failures: int = 0


func _init() -> void:
	call_deferred("_run_scene_tests")


func _run_scene_tests() -> void:
	_assert_equal(
		ProjectSettings.get_setting("application/run/main_scene"),
		"res://scenes/flow/start_screen.tscn",
		"project launches through the start screen"
	)
	var start_screen: Node = START_SCREEN_SCENE.instantiate()
	add_child(start_screen)
	await get_tree().process_frame
	_assert_true(start_screen.get_node_or_null("Menu/StartButton") != null, "start screen exposes a start button")
	_assert_true(start_screen.get_node_or_null("Menu/ContinueButton") != null, "start screen exposes a continue button")
	_assert_true(start_screen.get_node_or_null("Menu/GrowthButton") != null, "start screen exposes a growth button")
	_assert_true(start_screen.get_node_or_null("Menu/CharacterButton") != null, "start screen exposes a character configuration button")
	_assert_true(start_screen.get_node_or_null("Menu/GuideLabel") != null, "start screen exposes first-run controls guidance")
	if start_screen.get_node_or_null("Menu/GuideLabel") != null:
		_assert_true((start_screen.get_node("Menu/GuideLabel") as Label).text.contains("空格"), "first-run guidance names the vault control")
	_assert_true(start_screen.get_node_or_null("CharacterPanel/AttributeLabel") != null, "start screen exposes attribute allocation state")
	start_screen.call("_show_character")
	_assert_true((start_screen.get_node("CharacterPanel/AttributeLabel") as Label).text.contains("结晶阶级"), "character configuration shows the permanent crystal tier")
	start_screen.call("_hide_character")
	_assert_true(GameManager.has_method("get_meta_crystal_tier"), "GameManager exposes the permanent crystal tier")
	_assert_true(GameManager.has_method("get_meta_attribute_point_bonus"), "GameManager exposes the permanent attribute point bonus")
	_assert_true(GameManager.has_method("get_character_attribute_total_points"), "GameManager exposes the current character point budget")
	if GameManager.has_method("get_character_attribute_total_points") and GameManager.has_method("get_meta_attribute_point_bonus"):
		_assert_equal(
			GameManager.get_character_attribute_total_points(),
			10 + GameManager.get_meta_attribute_point_bonus(),
			"character configuration includes the permanent crystal-tier point bonus"
		)
	_assert_true(GameManager.is_run_idle(), "cold start menu does not automatically begin a run")
	start_screen.queue_free()
	await get_tree().process_frame
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
	_assert_true(basement.get_node_or_null("FieldPack") != null, "basement exposes a world pickup for a first backpack")
	_assert_true(basement.get_node_or_null("ClothCap") != null, "basement exposes a world pickup for head equipment")
	_assert_true(basement.get_node_or_null("CanvasJacket") != null, "basement exposes a world pickup for chest equipment")
	_assert_true(basement.get_node_or_null("TrailPants") != null, "basement exposes a world pickup for leg equipment")
	var camera: Camera2D = basement.get_node_or_null("Player/Camera2D") as Camera2D
	var viewport_size := Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width")),
		float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	)
	_assert_true(camera != null and camera.enabled, "player camera is enabled")
	_assert_true(camera != null and camera.is_current(), "player camera is the current camera")
	_assert_true(camera != null and not camera.position_smoothing_enabled, "player camera follows without visible lag")
	if camera != null:
		_assert_true(
			camera.limit_right - camera.limit_left > viewport_size.x,
			"basement camera limits leave horizontal room for following"
		)
		_assert_true(
			camera.limit_bottom - camera.limit_top > viewport_size.y,
			"basement camera limits leave vertical room for following"
		)
		var basement_player: Node2D = basement.get_node("Player") as Node2D
		var camera_test_position := Vector2(1280.0, 720.0)
		basement_player.global_position = camera_test_position
		await get_tree().process_frame
		await get_tree().physics_frame
		_assert_true(
			camera.get_screen_center_position().distance_to(camera_test_position) <= 0.5,
			"camera screen center follows the player position"
		)
		basement_player.global_position = basement.get_node("PlayerSpawn").global_position
	var health_component: Node = HEALTH_COMPONENT_SCRIPT.new()
	health_component.set("max_health", 100.0)
	add_child(health_component)
	await get_tree().process_frame
	health_component.call("take_damage", 1000.0)
	_assert_true(bool(health_component.call("is_dead")), "health component enters the dead state")
	_assert_true(bool(health_component.call("apply_max_health_multiplier", 2.0)), "dead health component accepts max health scaling")
	_assert_true(bool(health_component.call("is_dead")), "max health scaling preserves the dead state")
	_assert_equal(float(health_component.call("get_health")), 0.0, "dead max health scaling keeps zero health")
	health_component.queue_free()
	_assert_true(basement.get_node_or_null("BasementArt") != null, "basement instantiates the formal 2D art layer")
	var debug_controller: Node = basement.get_node_or_null("DebugController")
	_assert_true(debug_controller != null, "basement instantiates the debug controller")
	if debug_controller != null:
		_assert_true(not bool(debug_controller.get_node("DebugPanel").visible), "debug controller starts hidden")
	if basement.get_node_or_null("BasementArt") != null:
		_assert_true(basement.get_node("BasementArt/Floor") is Polygon2D, "basement art provides a floor plane")
		_assert_true(basement.get_node("BasementArt/BackWall") is Polygon2D, "basement art provides a back wall")
		_assert_true(basement.get_node("BasementArt/PipeTop") is Line2D, "basement art provides overhead pipe detail")
	var environment_presenter: Node = basement.get_node_or_null("WorldEnvironmentPresenter")
	_assert_true(environment_presenter != null, "basement instantiates the world environment presenter")
	if environment_presenter != null:
		_assert_true(environment_presenter.get_node_or_null("EnvironmentCanvas/MoonSprite") != null, "environment presenter owns the moon sprite")
		_assert_true(environment_presenter.get_node_or_null("EnvironmentCanvas/WeatherTint") != null, "environment presenter owns the weather tint")
		_assert_true(environment_presenter.get_node_or_null("EnvironmentCanvas/FogLayer") != null, "environment presenter owns the fog layer")
		_assert_true(environment_presenter.get_node_or_null("EnvironmentCanvas/ParticleLayer") != null, "environment presenter owns the particle layer")
	_assert_true(GameManager.has_signal("escape_objective_changed"), "GameManager exposes escape objective state changes")
	_assert_true(GameManager.has_method("collect_escape_material"), "GameManager exposes an escape material command")
	_assert_true(GameManager.has_method("advance_escape_exit"), "GameManager exposes an exit startup command")
	_assert_true(GameManager.has_method("depart_floor"), "GameManager exposes an atomic floor departure command")
	_assert_true(GameManager.has_method("get_total_food_budget"), "GameManager exposes the current floor food budget")
	_assert_true(GameManager.has_method("get_total_water_budget"), "GameManager exposes the current floor water budget")
	_assert_true(GameManager.has_method("get_night_fog_phase"), "GameManager exposes the current night fog phase")
	_assert_true(GameManager.has_method("get_moon_kind"), "GameManager exposes the current moon kind")
	_assert_true(GameManager.has_method("get_monster_spawn_multiplier"), "GameManager exposes moon spawn pressure")
	_assert_true(GameManager.has_method("get_special_spawn_ratio"), "GameManager exposes moon special weighting")
	_assert_true(GameManager.has_method("get_enemy_speed_multiplier"), "GameManager exposes moon movement pressure")
	_assert_true(GameManager.has_method("get_night_elapsed_seconds"), "GameManager exposes elapsed night time")
	_assert_true(GameManager.has_method("register_darkness_attack"), "GameManager exposes the darkness mark command")
	_assert_true(GameManager.has_signal("disaster_changed"), "GameManager exposes disaster state changes")
	_assert_true(GameManager.has_method("start_disaster"), "GameManager exposes a disaster lifecycle command")
	_assert_true(GameManager.has_method("advance_disasters"), "GameManager exposes disaster simulation advancement")
	_assert_true(GameManager.has_method("get_active_disaster_count"), "GameManager exposes active disaster count")
	_assert_true(GameManager.has_method("get_threat_budget_bonus_ratio"), "GameManager exposes active disaster threat budget modifiers")
	_assert_true(GameManager.has_method("get_primary_disaster_phase"), "GameManager exposes primary disaster phase")
	_assert_true(GameManager.has_method("get_environment_effects"), "GameManager exposes aggregated environment effects")
	_assert_true(GameManager.has_signal("boss_progress_changed"), "GameManager exposes boss progress changes")
	_assert_true(GameManager.has_method("get_run_seed"), "GameManager exposes the current run seed")
	_assert_true(GameManager.has_method("get_map_seed"), "GameManager exposes the current map seed")
	_assert_true(GameManager.has_method("get_random_event_index"), "GameManager exposes random stream positions")
	_assert_true(GameManager.has_method("apply_boss_damage"), "GameManager exposes the boss combat command")
	_assert_true(GameManager.has_method("collect_boss_component"), "GameManager exposes the boss environment collection command")
	_assert_true(GameManager.has_method("activate_boss_device"), "GameManager exposes the boss environment device command")
	_assert_true(GameManager.has_method("save_safe_exit"), "GameManager exposes safe-exit saving")
	_assert_true(GameManager.has_method("restore_safe_exit"), "GameManager exposes safe-exit restoring")
	_assert_true(GameManager.has_method("finalize_run_failure"), "GameManager exposes final failure settlement")
	_assert_true(GameManager.has_method("add_meta_crystals"), "GameManager exposes meta crystal accumulation")
	_assert_true(GameManager.has_method("configure_floor_disaster_kinds"), "world scenes can constrain disasters to available countermeasures")
	_assert_true(GameManager.call("start_disaster", 0), "a normal disaster can enter the world lifecycle")
	var environment_effects: Dictionary = GameManager.call("get_environment_effects")
	_assert_true(float(environment_effects.get("water_level_delta", 0.0)) >= 1.0, "rain disaster exposes a water level effect")
	_assert_equal(GameManager.call("get_active_disaster_count"), 1, "warning disasters occupy an active slot")
	if environment_presenter != null:
		_assert_equal(environment_presenter.call("get_weather_mode"), &"rainstorm", "disaster signals select the rainstorm presentation")
		_assert_equal(environment_presenter.call("get_weather_strength"), 0.35, "warning signals apply the low weather strength")
	_assert_true(not GameManager.call("start_disaster", 0), "the same disaster cannot be started twice")
	_assert_true(not GameManager.call("start_disaster", 1), "normal difficulty blocks a second concurrent disaster")
	GameManager.tick_survival(5.0)
	_assert_equal(GameManager.call("get_primary_disaster_remaining_seconds"), 5.0, "ordinary survival ticks advance disaster warning time")
	GameManager.tick_survival(5.0)
	_assert_equal(GameManager.call("get_primary_disaster_phase"), 2, "advanced disaster exposes the active phase")
	if environment_presenter != null:
		_assert_equal(environment_presenter.call("get_weather_strength"), 1.0, "active disaster signals apply the full weather strength")
	_assert_true(GameManager.call("advance_disasters", 240.0), "a normal disaster resolves after its duration")
	_assert_equal(GameManager.call("get_active_disaster_count"), 0, "resolved disasters leave the active slot")
	if environment_presenter != null:
		_assert_equal(environment_presenter.call("get_weather_mode"), &"clear", "resolved disaster signals restore the clear presentation")
		_assert_equal(environment_presenter.call("get_weather_strength"), 0.0, "resolved disaster signals clear the weather strength")
	_assert_true(GameManager.call("start_disaster", 4), "monster surge can enter warning")
	_assert_true(GameManager.call("advance_disasters", 10.0), "monster surge warning can activate")
	_assert_equal(GameManager.call("get_threat_budget_bonus_ratio"), 0.5, "active monster surge exposes a fifty-percent budget bonus")
	_assert_equal(GameManager.call("get_current_threat_budget"), 18, "day-one monster surge raises the runtime threat budget from twelve to eighteen")
	_assert_true(GameManager.call("advance_disasters", 240.0), "monster surge eventually resolves")
	_assert_equal(GameManager.call("get_threat_budget_bonus_ratio"), 0.0, "resolved monster surge removes its threat budget bonus")
	if GameManager.has_method("configure_floor_disaster_kinds"):
		_assert_true(not GameManager.call("start_disaster", 6), "basement rejects hard disasters without their primary countermeasure facility")
	_assert_true(GameManager.call("start_disaster", 9), "a hard disaster can be surfaced for the primary countermeasure")
	var disaster_label: Label = basement.get_node_or_null("ObjectiveHUD/ObjectiveStack/DisasterLabel") as Label
	_assert_true(disaster_label != null, "basement displays a dedicated disaster HUD")
	if disaster_label != null:
		_assert_true(disaster_label.text.contains("猎杀者"), "disaster HUD names the active hard disaster")
		_assert_true(disaster_label.text.contains("信号抑制器"), "hard disaster HUD names its unique primary countermeasure")
		_assert_true(disaster_label.text.contains("东侧维护区"), "hard disaster HUD exposes the countermeasure location")
	var signal_suppressor: Node = basement.get_node_or_null("SignalSuppressor")
	_assert_true(signal_suppressor != null, "basement creates the hard-disaster signal suppressor")
	if signal_suppressor != null:
		_assert_true(signal_suppressor.has_method("interact"), "signal suppressor exposes its primary interaction")
		_assert_true(GameManager.call("advance_disasters", 10.0), "hard disaster warning can activate before facility use")
		_assert_true(signal_suppressor.call("interact", 4.0), "signal suppressor records partial countermeasure progress")
		_assert_equal(GameManager.call("get_primary_disaster_countermeasure_progress"), 4.0, "disaster HUD state retains partial countermeasure progress")
		_assert_true(signal_suppressor.has_method("interrupt"), "signal suppressor exposes interruption without discarding progress")
		if signal_suppressor.has_method("interrupt"):
			_assert_true(signal_suppressor.call("interrupt"), "signal suppressor forwards an interrupted interaction")
			_assert_equal(GameManager.call("get_primary_disaster_countermeasure_progress"), 4.0, "facility interruption preserves completed progress")
		_assert_true(signal_suppressor.call("interact", 6.0), "signal suppressor completes the countermeasure")
		_assert_equal(GameManager.call("get_active_disaster_count"), 0, "completed countermeasure removes the hard disaster")
	if GameManager.has_method("get_total_food_budget"):
		_assert_equal(GameManager.call("get_total_food_budget"), 11, "normal basement includes guaranteed and emergency food")
		_assert_equal(GameManager.call("get_total_water_budget"), 15, "normal basement includes guaranteed and emergency water")
	_assert_true(Inventory.get_items().all(func(item: Variant) -> bool: return item == null), "a new run starts without fixed inventory supplies")
	_assert_equal(Inventory.get_slot_count(), 8, "new runs expose eight inventory slots")
	var resource_nodes: Array[Node] = []
	for resource_node: Node in get_tree().get_nodes_in_group("persistent_resource"):
		if basement.is_ancestor_of(resource_node):
			resource_nodes.append(resource_node)
	_assert_equal(resource_nodes.size(), 3, "basement places three finite resource nodes")
	var resource_ids: Dictionary = {}
	for resource_node: Node in resource_nodes:
		resource_ids[String(resource_node.get("entity_id"))] = true
	_assert_true(resource_ids.has("basement_wood_01"), "basement places a wood resource node")
	_assert_true(resource_ids.has("basement_stone_01"), "basement places a stone resource node")
	_assert_true(resource_ids.has("basement_ration_01"), "basement places a reachable food resource node")
	var wood_node: Node = basement.get_node("ResourceWoodBasement01")
	_assert_true(wood_node.has_method("_try_gather"), "wood resource exposes gathering interaction")
	if wood_node.has_method("_try_gather"):
		_assert_true(wood_node.call("_try_gather"), "gathering a resource adds output to inventory")
		var wood_stack: RefCounted = Inventory.get_stacks()[0]
		_assert_true(wood_stack != null and wood_stack.get_quantity() == 2, "gathering adds the configured quantity")
		for _gather_index in range(4):
			wood_node.call("_try_gather")
		_assert_true(bool(wood_node.call("create_snapshot").get("depleted", false)), "resource node becomes depleted after its finite supply is gathered")
		_assert_true(not bool(wood_node.call("_try_gather")), "depleted resource rejects repeated interaction")
	var campfire: Node = basement.get_node_or_null("CampfireBasement01")
	var basement_player_for_processing: Node2D = basement.get_node("Player") as Node2D
	_assert_true(campfire != null, "basement places a campfire interaction")
	if campfire != null:
		_assert_true(campfire.has_method("add_fuel_from_inventory"), "campfire exposes fuel interaction")
		_assert_true(bool(campfire.call("add_fuel_from_inventory")), "campfire consumes wood for fuel")
		_assert_true(bool(campfire.call("ignite_with_lighter")), "campfire can be lit with a lighter")
		_assert_true(bool(campfire.call("is_lit")), "lit campfire reports its active state")
		_assert_true(float(campfire.call("get_light_radius")) > 0.0, "lit campfire exposes a light radius")
		_assert_true(bool(campfire.call("advance_burning", 10.0, 0, false)), "campfire advances its fuel in the live scene")
		basement_player_for_processing.global_position = (campfire as Node2D).global_position
		await get_tree().physics_frame
		Inventory.reset_for_new_run()
		var raw_meat: ItemData = preload("res://assets/items/raw_meat.tres")
		var processing_container: ItemData = preload("res://assets/items/medium_container.tres")
		_assert_true(Inventory.add_item(raw_meat), "campfire processing receives raw meat")
		_assert_true(Inventory.add_item(processing_container), "campfire processing receives a container")
		Inventory.set_selected_slot(1)
		_assert_equal(Inventory.get_selected_slot(), 1, "campfire selects the processing container")
		_assert_true(Inventory.fill_selected_container(3, 1, false), "campfire processing receives dirty water")
		_assert_true(bool(campfire.call("start_purifying")), "lit campfire starts purification in range")
		Inventory.set_selected_slot(0)
		_assert_equal(Inventory.get_selected_slot(), 0, "campfire selects the cooking slot")
		_assert_true(bool(campfire.call("start_cooking")), "lit campfire starts cooking in range")
		_assert_true(bool(campfire.call("advance_processing", 8.0, false, false, true)), "campfire advances both processing slots")
		_assert_true(bool(campfire.call("is_cooking_complete")), "campfire cooking completes")
		_assert_true(bool(campfire.call("is_purifying_complete")), "campfire purification completes")
		_assert_true(bool(Inventory.get_container_snapshot_at(1).get("purified", false)), "campfire purification keeps the locked container result")
	var torch: Node = basement.get_node_or_null("TorchBasement01")
	_assert_true(torch != null and torch is Area2D, "basement places a torch interaction area")
	if torch != null:
		_assert_true(torch.has_method("ignite_with_lighter"), "torch exposes lighter ignition")
		_assert_true(torch.has_method("ignite_from_campfire"), "torch exposes campfire ignition")
		_assert_true(bool(torch.call("ignite_from_campfire")), "torch can be lit from a campfire")
		_assert_true(float(torch.call("get_light_radius")) > 0.0, "lit torch exposes a local light radius")
		var torch_snapshot: Dictionary = torch.call("create_snapshot")
		_assert_true(bool(torch.call("extinguish")), "torch can be extinguished")
		_assert_true(bool(torch.call("restore_snapshot", torch_snapshot)), "torch restores its runtime snapshot")
	var shelter: Node = basement.get_node_or_null("RainShelterBasement01")
	var wall: Node = basement.get_node_or_null("WoodWallBasement01")
	_assert_true(shelter != null and shelter is StaticBody2D, "basement places a collidable rain shelter")
	_assert_true(wall != null and wall is StaticBody2D, "basement places a collidable wooden wall")
	if shelter != null:
		_assert_true(float(shelter.call("get_health")) == 160.0, "rain shelter starts with its configured health")
		_assert_true(bool(shelter.call("take_damage", 20.0)), "rain shelter accepts damage")
		_assert_true(float(shelter.call("get_health")) == 140.0, "rain shelter health decreases after damage")
		var shelter_snapshot: Dictionary = shelter.call("create_snapshot")
		_assert_true(bool(shelter.call("restore_snapshot", shelter_snapshot)), "rain shelter restores its health and position")
	if wall != null:
		_assert_true(float(wall.call("get_health")) == 100.0, "wood wall starts with its configured health")
		basement_player_for_processing.global_position = basement.get_node("PlayerSpawn").global_position
		await get_tree().physics_frame
	Inventory.reset_for_new_run()
	var water_source: Node = basement.get_node_or_null("WaterSourceBasement01")
	_assert_true(water_source != null, "basement exposes a reusable water source")
	_assert_true(GameManager.has_method("fill_selected_container_from_source"), "GameManager exposes selected-container filling")
	if water_source != null:
		_assert_true(absf(float(water_source.call("get_disease_chance_for_difficulty", 0)) - 0.35) <= 0.0001, "puddle source uses the normal disease rate")
		_assert_true(absf(float(water_source.call("get_disease_chance_for_difficulty", 2)) - 0.45) <= 0.0001, "puddle source scales disease rate on hell")
		var empty_container: ItemData = preload("res://assets/items/empty_container.tres")
		_assert_true(Inventory.add_item(empty_container), "inventory accepts the starting empty container")
		_assert_true(water_source.call("fill_selected_container"), "water source fills the selected container")
		_assert_equal(int(Inventory.get_selected_container_snapshot().get("amount", 0)), 1, "filled container stores one water unit")
		var water_before_drink: float = GameManager.get_water()
		_assert_true(GameManager.use_selected_item(), "filled container can be consumed")
		_assert_true(GameManager.get_water() > water_before_drink, "drinking updates water")
		_assert_equal(int(Inventory.get_selected_container_snapshot().get("amount", 0)), 0, "drinking returns the container to empty")
	Inventory.reset_for_new_run()
	var hunger_before_food: float = GameManager.get_hunger()
	_assert_true(Inventory.add_item(RATION_ITEM), "inventory accepts a usable food item")
	_assert_true(GameManager.use_selected_item(), "selected food item can be consumed in a live run")
	_assert_true(GameManager.get_hunger() > hunger_before_food, "food consumption updates hunger")
	_assert_true(Inventory.get_selected_item() == null, "consumed food is removed atomically")
	Inventory.reset_for_new_run()
	var inventory_bar: Control = basement.get_node_or_null("Player/HUD/InventoryBar") as Control
	_assert_true(inventory_bar != null, "player HUD contains the inventory bar")
	var equipment_bar: Node = basement.get_node_or_null("Player/HUD/EquipmentBar")
	_assert_true(equipment_bar != null, "player HUD contains an actionable equipment bar")
	if equipment_bar != null:
		_assert_equal(equipment_bar.get_node("Slots").get_child_count(), 4, "equipment bar exposes head, chest, legs, and backpack slots")
		_assert_true(equipment_bar.has_signal("unequip_requested"), "equipment bar emits a semantic unequip command")
	if inventory_bar != null:
		var inventory_slots: HBoxContainer = inventory_bar.get_node_or_null("Slots") as HBoxContainer
		_assert_true(inventory_slots != null, "inventory bar contains a slots container")
		if inventory_slots != null:
			_assert_equal(inventory_slots.get_child_count(), 8, "inventory bar builds eight stable slots")
		_assert_true(inventory_bar.get_node_or_null("Weight") is Label, "inventory bar displays weight")
	_assert_true(GameManager.has_method("start_equipping_selected_item"), "GameManager exposes a timed selected-equipment command")
	_assert_true(GameManager.has_method("advance_character_equipment_interaction"), "GameManager exposes equipment interaction advancement")
	_assert_true(GameManager.has_method("start_unequipping_character_slot"), "GameManager exposes a timed unequip command")
	_assert_true(Inventory.add_item(FIELD_PACK_ITEM), "live inventory accepts a field pack")
	if GameManager.has_method("start_equipping_selected_item") and GameManager.has_method("advance_character_equipment_interaction"):
		_assert_true(GameManager.start_equipping_selected_item(), "selected field pack begins a timed equipment interaction")
		_assert_true(not GameManager.advance_character_equipment_interaction(1.0, false, false), "equipment is not committed before two standing seconds")
		_assert_true(GameManager.get_character_build_model().get_equipped_item_id(3).is_empty(), "partial equipment interaction leaves the slot unchanged")
		_assert_true(not GameManager.advance_character_equipment_interaction(0.1, true, false), "movement interrupts a pending equipment interaction")
		_assert_true(GameManager.get_character_build_model().get_equipped_item_id(3).is_empty(), "movement interruption keeps the backpack unequipped")
		_assert_true(GameManager.start_equipping_selected_item(), "interrupted equipment interaction can restart")
		basement.get_node("Player").call("_physics_process", 2.0)
		_assert_equal(GameManager.get_character_build_model().get_equipped_item_id(3), &"field_pack", "timed equipment interaction equips the field pack")
		_assert_equal(Inventory.get_slot_count(), 10, "equipped field pack expands the live inventory")
		if inventory_bar != null:
			_assert_equal(inventory_bar.get_node("Slots").get_child_count(), 10, "inventory bar rebuilds to the expanded capacity")
		if equipment_bar != null:
			equipment_bar.get_node("Slots").get_child(3).emit_signal("pressed")
		_assert_true(GameManager.get_character_equipment_interaction_remaining_seconds() > 0.0, "clicking the backpack slot begins a timed unequip interaction")
		_assert_true(GameManager.advance_character_equipment_interaction(2.0, false, false), "standing for two seconds commits backpack removal")
		_assert_true(GameManager.get_character_build_model().get_equipped_item_id(3).is_empty(), "timed unequip clears the backpack slot")
		_assert_equal(Inventory.get_slot_count(), 8, "unequipping the field pack restores base inventory capacity")
		_assert_true(Inventory.get_items().any(func(item: ItemData) -> bool: return item != null and item.id == &"field_pack"), "unequipping returns the field pack to inventory")
	Inventory.reset_for_new_run()
	_assert_equal(GameManager.get_run_difficulty(), 0, "a run started without an explicit choice uses normal difficulty")
	_assert_true(not GameManager.set_run_difficulty(1), "difficulty is locked after the run starts")
	var hunger_at_entry: float = GameManager.get_hunger()
	var water_at_entry: float = GameManager.get_water()
	_assert_true(GameManager.tick_survival(36.0) >= 0.0, "active exploration advances survival simulation")
	_assert_true(GameManager.get_hunger() < hunger_at_entry, "survival tick consumes hunger")
	_assert_true(GameManager.get_water() < water_at_entry, "survival tick consumes water")
	_assert_true(GameManager.get_floor_elapsed_seconds() >= 36.0, "survival tick advances the floor clock")
	var hunger_before_pause: float = GameManager.get_hunger()
	var elapsed_before_pause: float = GameManager.get_floor_elapsed_seconds()
	_assert_true(GameManager.pause_run(), "an active run can pause through GameManager")
	_assert_true(get_tree().paused, "pausing the run freezes the scene tree")
	_assert_equal(GameManager.tick_survival(36.0), 0.0, "paused simulation rejects survival advancement")
	_assert_equal(GameManager.get_hunger(), hunger_before_pause, "paused survival keeps hunger unchanged")
	_assert_equal(GameManager.get_floor_elapsed_seconds(), elapsed_before_pause, "paused survival keeps time unchanged")
	_assert_true(GameManager.resume_run(), "a paused run can resume through GameManager")
	_assert_true(not get_tree().paused, "resuming the run unfreezes the scene tree")
	_assert_true(GameManager.tick_survival(1.0) >= 0.0, "resumed simulation advances again")
	var survival_status: Label = basement.get_node("Player/HUD/StatusStack/SurvivalStatus") as Label
	_assert_true(survival_status.text.contains("饥饿"), "player HUD displays hunger")
	_assert_true(survival_status.text.contains("水分"), "player HUD displays water")
	_assert_true(survival_status.text.contains("白天"), "player HUD displays the current day phase")
	var encounter_controller: Node = basement.get_node("EncounterController")
	_assert_true(encounter_controller != null, "basement instantiates an encounter controller")
	_assert_true(encounter_controller.has_method("get_used_threat_budget"), "encounter exposes its reserved threat budget")
	_assert_true(encounter_controller.has_method("get_protected_point_count"), "encounter exposes its configured spawn protection points")
	_assert_true(encounter_controller.call("get_protected_point_count") >= 6, "basement configures entry, exit, spawn and objective protection points")
	_assert_equal(int(encounter_controller.call("get_target_count")), 2, "configured encounter has two generated targets")
	_assert_equal(encounter_controller.call("get_used_threat_budget"), 2, "configured encounter reserves one point per ordinary enemy")
	var dummy: Node2D = basement.get_node_or_null("ContentRoot/EncounterEntity0") as Node2D
	_assert_true(dummy != null, "encounter generates the first entity")
	_assert_true(basement.get_node_or_null("ContentRoot/EncounterEntity1") != null, "encounter generates the second entity")
	if dummy != null:
		_assert_true(dummy.get_node_or_null("Presenter") != null, "training dummy exposes a replaceable presenter boundary")
	var first_enemy_for_art: Node = basement.get_node_or_null("ContentRoot/EncounterEntity1")
	if first_enemy_for_art != null:
		_assert_true(first_enemy_for_art.get_node_or_null("Presenter/RiftSprite") != null, "chaser enemy uses the rift animal presentation")
	var objective_label: Label = basement.get_node("ObjectiveHUD/ObjectiveStack/ObjectiveLabel") as Label
	_assert_true(objective_label.text.contains("0/2"), "basement starts with two incomplete objectives")
	var objective_stack: VBoxContainer = basement.get_node_or_null("ObjectiveHUD/ObjectiveStack") as VBoxContainer
	_assert_true(objective_stack != null, "basement objective HUD uses a vertical stack for multiline status")
	var escape_label: Label = basement.get_node_or_null("ObjectiveHUD/ObjectiveStack/EscapeLabel") as Label
	_assert_true(escape_label != null, "basement displays a dedicated escape objective HUD")
	if objective_stack != null and escape_label != null:
		_assert_true(
			objective_label.get_global_rect().end.y <= escape_label.get_global_rect().position.y,
			"basement objective and escape labels are vertically separated"
		)
	var basement_buff_status: Label = basement.get_node_or_null("Player/HUD/StatusStack/BuffStatus") as Label
	_assert_true(basement_buff_status != null, "basement player HUD exposes the buff status")
	if basement_buff_status != null and objective_label != null and escape_label != null and disaster_label != null:
		_assert_true(
			_not_rects_intersect(basement_buff_status.get_global_rect(), objective_label.get_global_rect()),
			"basement buff HUD does not overlap the area objective HUD"
		)
		_assert_true(
			_not_rects_intersect(basement_buff_status.get_global_rect(), escape_label.get_global_rect()),
			"basement buff HUD does not overlap the escape HUD"
		)
		_assert_true(
			_not_rects_intersect(basement_buff_status.get_global_rect(), disaster_label.get_global_rect()),
			"basement buff HUD does not overlap the disaster HUD"
		)
	var status_stack: VBoxContainer = basement.get_node_or_null("Player/HUD/StatusStack") as VBoxContainer
	_assert_true(status_stack != null, "player HUD uses a responsive status stack")
	if objective_stack != null and status_stack != null and objective_label != null and escape_label != null and disaster_label != null:
		var original_viewport_size: Vector2i = get_viewport().size
		get_viewport().size = Vector2i(366, 186)
		await get_tree().process_frame
		var narrow_visible_size: Vector2 = get_viewport().get_visible_rect().size
		_assert_true(objective_stack.get_global_rect().end.x <= narrow_visible_size.x, "narrow basement objective column stays inside the viewport")
		_assert_true(status_stack.get_global_rect().position.x >= 0.0, "narrow player status column stays inside the viewport")
		_assert_true(status_stack.get_global_rect().end.x <= narrow_visible_size.x, "narrow player status column ends inside the viewport")
		_assert_true(not _rects_intersect(objective_stack.get_global_rect(), status_stack.get_global_rect()), "narrow basement HUD columns do not overlap")
		_assert_true(not _rects_intersect(objective_label.get_global_rect(), escape_label.get_global_rect()), "narrow objective and escape text do not overlap")
		_assert_true(not _rects_intersect(escape_label.get_global_rect(), disaster_label.get_global_rect()), "narrow escape and disaster text do not overlap")
		get_viewport().size = original_viewport_size
		await get_tree().process_frame
	if escape_label != null:
		_assert_true(escape_label.text.contains("零件 0/2"), "escape HUD publicly shows the parts requirement")
		_assert_true(escape_label.text.contains("钥匙 0/1"), "escape HUD publicly shows the key requirement")
	var escape_material_counts := PackedInt32Array([0, 0, 0, 0])
	for escape_material: Node in get_tree().get_nodes_in_group("snapshot_escape_material"):
		if basement.is_ancestor_of(escape_material):
			var material_type: int = int(escape_material.get("material_type"))
			if material_type >= 0 and material_type < escape_material_counts.size():
				escape_material_counts[material_type] += 1
	_assert_equal(escape_material_counts[0], 2, "basement places two parts pickups for the escape requirement")
	_assert_equal(escape_material_counts[1], 2, "basement places two fuel pickups for the escape requirement")
	_assert_equal(escape_material_counts[2], 2, "basement places two cloth pickups for the escape requirement")
	_assert_equal(escape_material_counts[3], 1, "basement places one key pickup for the escape requirement")
	var transition_zone: Node = basement.get_node("TransitionZone")
	_assert_true(bool(transition_zone.get("requires_objective_complete")), "basement exit requires objective completion")
	_assert_true(transition_zone.get("requires_escape_startup") == true, "basement exit requires escape startup completion")
	_assert_true(transition_zone.has_method("resolve_next_floor_scene"), "floor exits resolve the next scene through the world catalog")
	_assert_equal(transition_zone.get("final_floor_scene"), "res://scenes/world/final_core/final_core.tscn", "the fifth-floor exit routes the final floor to the final core scene")
	_assert_equal((transition_zone as Area2D).collision_mask, 3, "escape exit monitors both player and enemy collision layers")
	var escape_part: Node = basement.get_node_or_null("EscapeParts0")
	_assert_true(escape_part != null, "basement places escape materials away from the player spawn")
	if escape_part != null and GameManager.has_method("get_escape_material_collected"):
		_assert_true((escape_part as Node2D).position.distance_to(Vector2(200.0, 360.0)) >= 200.0, "escape materials are not fixed spawn supplies")
		escape_part.call("_try_pickup")
		await get_tree().process_frame
		_assert_true(not is_instance_valid(escape_part), "collecting a task material removes its world pickup")
		_assert_equal(GameManager.call("get_escape_material_collected", 0), 1, "task pickup advances escape progress")
		_assert_true(Inventory.get_items().all(func(item: Variant) -> bool: return item == null), "task materials do not occupy inventory slots")
		_assert_true(escape_label.text.contains("零件 1/2"), "escape HUD updates after a task pickup")
		_assert_true(not GameManager.call("advance_escape_exit", 1.0, false, false, false), "exit startup is locked before materials are complete")
		GameManager.call("collect_escape_material", 0, 1)
		GameManager.call("collect_escape_material", 1, 2)
		GameManager.call("collect_escape_material", 2, 2)
		GameManager.call("collect_escape_material", 3, 1)
		_assert_true(GameManager.call("has_all_escape_materials"), "all map escape materials can be collected")
		_assert_true(not GameManager.call("advance_escape_exit", 4.0, false, false, false), "partial exit startup remains incomplete")
		_assert_equal(GameManager.call("get_escape_startup_seconds"), 4.0, "partial exit startup is retained")
		_assert_true(not GameManager.call("advance_escape_exit", 1.0, true, false, false), "movement interrupts exit startup")
		_assert_equal(GameManager.call("get_escape_startup_seconds"), 4.0, "movement interruption preserves exit progress")
		_assert_true(GameManager.call("advance_escape_exit", 6.0, false, false, false), "ten seconds completes exit startup")
		_assert_true(GameManager.call("is_escape_exit_started"), "completed startup unlocks departure")
	var player: Node2D = basement.get_node("Player") as Node2D
	var player_presenter: Node = player.get_node_or_null("Presenter")
	_assert_true(player_presenter is Node2D, "player presenter inherits the player transform")
	_assert_true(player_presenter != null, "player exposes a replaceable presenter boundary")
	var player_animation_player: AnimationPlayer = player.get_node_or_null("Presenter/AnimationPlayer") as AnimationPlayer
	var player_animation_tree: AnimationTree = player.get_node_or_null("Presenter/AnimationTree") as AnimationTree
	var player_visual: AnimatedSprite2D = player.get_node_or_null("Presenter/AnimatedSprite2D") as AnimatedSprite2D
	_assert_true(player_animation_player != null, "player presentation owns an AnimationPlayer")
	_assert_true(player_animation_tree != null and player_animation_tree.active, "player presentation owns an active AnimationTree")
	_assert_true(player_visual != null, "player presentation owns the animated sprite visual")
	if player_visual != null:
		_assert_true(player_visual.visible, "player visual is visible after scene initialization")
		_assert_true(player_visual.sprite_frames != null, "player visual has sprite frames after scene initialization")
		_assert_true(player_visual.sprite_frames.get_frame_texture(player_visual.animation, player_visual.frame) != null, "player visual resolves an initial animation frame")
		for _visual_frame in range(30):
			await get_tree().process_frame
		_assert_true(player_visual.visible, "player visual remains visible after animation tree settles")
	if player_presenter != null and player_animation_tree != null and player_visual != null:
		var animation_playback: AnimationNodeStateMachinePlayback = \
			player_animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
		_assert_true(animation_playback != null, "player AnimationTree exposes state-machine playback")
		if animation_playback != null:
			_assert_equal(animation_playback.get_current_node(), &"Idle", "player animation starts idle")
			_assert_equal(player_visual.animation, &"down", "player animation starts facing down")
			player_presenter.call("set_movement", Vector2.RIGHT)
			await _wait_for_animation_state(animation_playback, &"Move")
			_assert_equal(animation_playback.get_current_node(), &"Move", "movement enters the locomotion animation state")
			_assert_equal(player_visual.animation, &"right", "rightward movement selects the right sprite direction")
			player_presenter.call("set_movement", Vector2.ZERO)
			await _wait_for_animation_state(animation_playback, &"Idle")
			_assert_equal(animation_playback.get_current_node(), &"Idle", "stopping returns to the idle animation state")
			_assert_equal(player_visual.animation, &"right", "stopping keeps the latest facing direction")
			player_presenter.call("play_attack", Vector2.RIGHT)
			await _wait_for_animation_state(animation_playback, &"Attack")
			_assert_equal(animation_playback.get_current_node(), &"Attack", "attack enters a transient animation state")
			await get_tree().create_timer(0.2).timeout
			await _wait_for_animation_state(animation_playback, &"Idle")
			_assert_equal(animation_playback.get_current_node(), &"Idle", "attack completion restores the locomotion state")
			player_presenter.call("play_hit")
			await _wait_for_animation_state(animation_playback, &"Hit")
			_assert_equal(animation_playback.get_current_node(), &"Hit", "damage feedback enters a transient animation state")
			await get_tree().create_timer(0.16).timeout
			await _wait_for_animation_state(animation_playback, &"Idle")
			_assert_equal(animation_playback.get_current_node(), &"Idle", "hit completion restores the locomotion state")
			player_presenter.call("set_dead", true)
			await _wait_for_animation_state(animation_playback, &"Dead")
			_assert_equal(animation_playback.get_current_node(), &"Dead", "death enters the highest-priority animation state")
			player_presenter.call("set_movement", Vector2.LEFT)
			player_presenter.call("play_attack", Vector2.LEFT)
			_assert_equal(animation_playback.get_current_node(), &"Dead", "movement and attack cannot replace the death state")
			_assert_true(not player_visual.visible, "death animation hides the visual")
			player_presenter.call("set_dead", false)
			await _wait_for_animation_state(animation_playback, &"Idle")
			_assert_equal(animation_playback.get_current_node(), &"Idle", "revive returns to the idle animation state")
			_assert_equal(player_visual.animation, &"right", "revive returns to the retained facing direction")
			_assert_true(player_visual.visible, "revive restores the visual")
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
	_assert_true(Inventory.add_quantity(WOOD_ITEM, 4), "inventory accepts a four-item material stack")
	Inventory.set_selected_slot(1)
	Input.action_press(&"drop")
	await get_tree().physics_frame
	Input.action_release(&"drop")
	await get_tree().physics_frame
	var dropped_stack: Node = get_node_or_null("ItemWorld")
	_assert_true(dropped_stack != null and dropped_stack.has_method("get_stack"), "dropping a stack creates a stack-aware world item")
	if dropped_stack != null and dropped_stack.has_method("get_stack"):
		var world_stack: RefCounted = dropped_stack.call("get_stack")
		_assert_true(world_stack != null and world_stack.get_quantity() == 4, "world item preserves the full dropped quantity")
	await _press_interact_key(dropped_stack)
	_assert_true(not is_instance_valid(dropped_stack), "stack world item can be picked up")
	_assert_equal(Inventory.get_stacks()[1].get_quantity(), 4, "re-pickup restores the full stack quantity")
	Inventory.set_selected_slot(0)
	var player_health: Node = player.get_node("HealthComponent")
	var health_before_environment: float = float(player_health.call("get_health"))
	GameManager.survival_environment_damage.emit(0.01)
	await get_tree().process_frame
	_assert_equal(
		float(player_health.call("get_health")),
		health_before_environment - 1.0,
		"survival environment damage is applied through the player health component"
	)
	var dummy_presenter_node: Node = dummy.get_node("Presenter")
	dummy_presenter_node.free()
	var dummy_presenter: Node = RECORDING_PRESENTER_SCRIPT.new()
	dummy_presenter.name = "Presenter"
	dummy.add_child(dummy_presenter)
	var dummy_has_presenter_property: bool = dummy.get_property_list().any(
		func(property: Dictionary) -> bool: return property.get("name") == "presenter"
	)
	_assert_true(dummy_has_presenter_property, "training dummy script exposes its presenter dependency")
	if dummy_has_presenter_property:
		dummy.set("presenter", dummy_presenter)
	var dummy_health: Node = dummy.get_node("HealthComponent")
	dummy_health.call("take_damage", 1.0)
	_assert_equal(dummy_presenter.get("hit_count"), 1, "training dummy damage forwards a hit event")
	var expected_shot_direction: Vector2 = (player.global_position - dummy.global_position).normalized()
	var scene_root: Node = get_tree().current_scene
	var child_count_before_shot: int = scene_root.get_child_count()
	dummy.call("_shoot_at", player.global_position)
	var dummy_attack_calls: Array[Vector2] = dummy_presenter.get("attack_calls")
	_assert_equal(dummy_attack_calls.size(), 1, "training dummy bullet spawn forwards one attack event")
	if not dummy_attack_calls.is_empty():
		_assert_true(dummy_attack_calls[-1].is_equal_approx(expected_shot_direction), "training dummy forwards its shot direction")
	if scene_root.get_child_count() > child_count_before_shot:
		scene_root.get_child(scene_root.get_child_count() - 1).free()
	dummy_health.call("take_damage", 1000.0)
	_assert_true((dummy_presenter.get("dead_values") as Array[bool]).has(true), "training dummy death forwards the dead state")
	_assert_true((dummy.get_node("Visual") as CanvasItem).visible, "training dummy gameplay leaves death visibility to its presenter")
	(dummy.get_node("RespawnTimer") as Timer).stop()
	dummy.call("_on_respawn_timeout")
	var dummy_dead_values: Array[bool] = dummy_presenter.get("dead_values")
	_assert_true(dummy_dead_values.size() >= 2 and dummy_dead_values[-1] == false, "training dummy respawn clears the dead state")
	var enemy: Node2D = basement.get_node("ContentRoot/EncounterEntity1") as Node2D
	_assert_true(enemy.get_node_or_null("Presenter") != null, "enemy exposes a replaceable presenter boundary")
	_assert_true(enemy.get_node_or_null("Presenter/RiftSprite") != null, "enemy presentation owns the rift sprite")
	if enemy.get_node_or_null("Presenter/RiftSprite") != null:
		_assert_true((enemy.get_node("Presenter/RiftSprite") as Sprite2D).visible, "rift sprite is visible after enemy initialization")
		_assert_true((enemy.get_node("Presenter/RiftSprite") as Sprite2D).texture != null, "rift sprite resolves its texture")
	_assert_true(enemy.is_in_group("enemy"), "active enemies are discoverable by escape exit interruption checks")
	var enemy_presenter_node: Node = enemy.get_node("Presenter")
	enemy_presenter_node.free()
	var enemy_presenter: Node = RECORDING_PRESENTER_SCRIPT.new()
	enemy_presenter.name = "Presenter"
	enemy.add_child(enemy_presenter)
	enemy.set("presenter", enemy_presenter)
	_assert_true(enemy.has_method("set_visual_contact"), "chaser exposes an explicit visual perception input")
	_assert_true(enemy.has_method("hear_sound"), "chaser exposes a sound investigation input")
	var enemy_health: Node = basement.get_node("ContentRoot/EncounterEntity1/HealthComponent")
	enemy.global_position = player.global_position + Vector2(240.0, 0.0)
	enemy.call("_physics_process", 0.0)
	_assert_true(enemy_presenter.get("movement_calls").size() > 0, "chaser forwards movement direction to its presenter")
	var movement_calls: Array[Vector2] = enemy_presenter.get("movement_calls")
	if not movement_calls.is_empty():
		_assert_true(movement_calls[-1].is_equal_approx(Vector2.LEFT), "chaser forwards its normalized pursuit direction")
	enemy.call("set_visual_contact", false)
	enemy.global_position = player.global_position + Vector2(400.0, 0.0)
	_assert_true(not enemy.call("hear_sound", player.global_position, 8.0, 1.0), "sound outside its step radius cannot create a global player lock")
	enemy.global_position = player.global_position + Vector2(240.0, 0.0)
	_assert_true(enemy.call("hear_sound", player.global_position, 8.0, 1.0), "chaser accepts a sound clue without receiving a live player lock")
	enemy.call("_physics_process", 8.0)
	enemy.call("_physics_process", 7.1)
	_assert_equal(enemy.get("velocity"), Vector2.ZERO, "chaser stops permanent pursuit after fifteen seconds without clues")
	enemy.global_position = player.global_position + Vector2(400.0, 0.0)
	enemy.call("clear_visual_contact_override")
	enemy.call("_physics_process", 0.0)
	_assert_equal(enemy.get("velocity"), Vector2.ZERO, "default perception does not acquire a player beyond visual range")
	enemy.global_position = player.global_position + Vector2(240.0, 0.0)
	enemy.call("_physics_process", 0.0)
	_assert_true((enemy.get("velocity") as Vector2).length() > 0.0, "entering visual range restores direct pursuit")
	var player_health_before_contact: float = float(player_health.call("get_health"))
	enemy.global_position = player.global_position + Vector2(42.0, 0.0)
	enemy.call("_try_attack", player)
	_assert_true(float(player_health.call("get_health")) < player_health_before_contact, "chaser contact attack still damages the player")
	enemy.call("_physics_process", 0.0)
	movement_calls = enemy_presenter.get("movement_calls")
	_assert_true(movement_calls.size() >= 2, "chaser forwards a stop event inside attack range")
	if movement_calls.size() >= 2:
		_assert_true(movement_calls[-1].is_equal_approx(Vector2.ZERO), "chaser stops movement presentation inside attack range")
	var attack_calls: Array[Vector2] = enemy_presenter.get("attack_calls")
	_assert_equal(attack_calls.size(), 1, "successful contact damage forwards one attack event")
	if not attack_calls.is_empty():
		_assert_true(attack_calls[-1].is_equal_approx(Vector2.LEFT), "contact attack forwards the direction toward the player")
	var original_contact_damage: float = float(enemy.get("contact_damage"))
	enemy.set("contact_damage", 0.0)
	enemy.set("_attack_cooldown_remaining", 0.0)
	var health_before_zero_damage: float = float(player_health.call("get_health"))
	enemy.call("_try_attack", player)
	_assert_equal(float(player_health.call("get_health")), health_before_zero_damage, "zero contact damage leaves player health unchanged")
	attack_calls = enemy_presenter.get("attack_calls")
	_assert_equal(attack_calls.size(), 1, "contact attempts without damage do not forward attack presentation")
	enemy.set("contact_damage", original_contact_damage)
	enemy_health.call("take_damage", 1.0)
	_assert_equal(enemy_presenter.get("hit_count"), 1, "enemy damage forwards a hit event")
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
	dummy_health.call("take_damage", 1000.0)
	enemy_health.call("take_damage", 1000.0)
	_assert_true((enemy_presenter.get("dead_values") as Array[bool]).has(true), "enemy death forwards the dead state")
	_assert_true((enemy.get_node("Visual") as CanvasItem).visible, "enemy gameplay leaves death visibility to its presenter")
	await get_tree().process_frame
	_assert_true(GameManager.is_objective_complete(), "defeating both enemies completes the objective")
	_assert_true(objective_label.text.contains("2/2"), "objective HUD shows both enemies defeated")
	_assert_true(objective_label.text.contains("选择强化"), "completed objective asks for a reward before exit")
	var reward_selection: Node = basement.get_node("RewardSelection")
	_assert_true(bool(reward_selection.get("visible")), "objective completion opens reward selection")
	_assert_true(reward_selection.get_node_or_null("Panel/Candidate0") != null, "reward selection exposes the first candidate")
	_assert_true(reward_selection.get_node_or_null("Panel/Candidate3") != null, "reward selection exposes four candidates")
	_assert_true(reward_selection.get_node_or_null("Panel/RerollButton") != null, "reward selection exposes a reroll button")
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
	_assert_true(GameManager.depart_floor(), "cleared area with a started exit can depart atomically")
	_assert_equal(GameManager.get_floor_elapsed_seconds(), 0.0, "starting the next floor resets its local survival clock")
	_assert_true(GameManager.get_hunger() < hunger_at_entry, "starting the next floor preserves current hunger")
	if GameManager.has_method("get_escape_material_collected"):
		_assert_equal(GameManager.call("get_escape_material_collected", 0), 0, "starting the next floor creates a fresh escape objective")
		_assert_equal(GameManager.call("get_escape_startup_seconds"), 0.0, "starting the next floor clears prior exit startup")
	_assert_true(GameManager.prepare_floor(), "next area can enter exploration")
	_assert_true(GameManager.complete_objective(), "next area objective can complete")
	var move_upgrade: Resource = reward_selection.get("move_speed_upgrade") as Resource
	_assert_true(GameManager.apply_run_upgrade(move_upgrade), "next area accepts a new reward choice")
	_assert_equal(GameManager.get_run_damage_multiplier(), 1.2, "previous area damage upgrade persists")
	_assert_equal(GameManager.get_run_move_speed_multiplier(), 1.15, "next area movement upgrade is applied")
	_assert_equal(GameManager.get_run_xp(), 0, "xp threshold is consumed by the level-up")
	_assert_equal(GameManager.get_run_level(), 2, "enemy defeats grant a level")
	GameManager.add_run_xp(30)
	var firearm_player: Node = basement.get_node_or_null("Player")
	if firearm_player != null:
		Inventory.reset_for_new_run()
		_assert_true(Inventory.add_item(PISTOL_ITEM), "scene can equip the graybox firearm")
		_assert_true(Inventory.add_quantity(PISTOL_AMMO_ITEM, 2), "scene can carry firearm ammunition")
		Inventory.set_selected_slot(0)
		firearm_player.call("_handle_attack_input", PLAYER_COMMAND_SCRIPT.new(Vector2.ZERO, false, true))
		var weapon: RefCounted = firearm_player.get("_ranged_weapon") as RefCounted
		_assert_true(weapon != null and weapon.is_reloading(), "empty firearm begins a timed reload")
		firearm_player.call("_advance_ranged_weapon", 0.2, Vector2.RIGHT)
		_assert_true(weapon != null and not weapon.is_reloading(), "movement interrupts firearm reload")
		firearm_player.call("_handle_attack_input", PLAYER_COMMAND_SCRIPT.new(Vector2.ZERO, false, true))
		firearm_player.call("_advance_ranged_weapon", 2.1, Vector2.ZERO)
		_assert_true(weapon != null and weapon.get_magazine_rounds() > 0, "stationary player completes firearm reload")
		var stamina_before_fire: float = float((firearm_player.get("_stamina_model") as RefCounted).get_stamina())
		firearm_player.call("_handle_attack_input", PLAYER_COMMAND_SCRIPT.new(Vector2.ZERO, false, true))
		var stamina_after_fire: float = float((firearm_player.get("_stamina_model") as RefCounted).get_stamina())
		_assert_true(stamina_after_fire >= stamina_before_fire, "firearm shooting does not consume stamina")
	Inventory.reset_for_new_run()
	basement.queue_free()
	await get_tree().process_frame
	var cihang: Node = CIHANG_SCENE.instantiate()
	add_child(cihang)
	await get_tree().process_frame
	var cihang_camera: Camera2D = cihang.get_node_or_null("Player/Camera2D") as Camera2D
	_assert_true(cihang_camera != null and cihang_camera.enabled, "cihang camera is enabled")
	if cihang_camera != null:
		_assert_equal(cihang_camera.limit_right - cihang_camera.limit_left, 5680, "cihang camera horizontal limits match the expanded map")
		_assert_equal(cihang_camera.limit_bottom - cihang_camera.limit_top, 3160, "cihang camera vertical limits match the expanded map")
		_assert_true(
			cihang_camera.limit_right - cihang_camera.limit_left > viewport_size.x,
			"cihang camera limits remain larger than the viewport"
		)
		_assert_true(
			cihang_camera.limit_bottom - cihang_camera.limit_top > viewport_size.y,
			"cihang vertical limits remain larger than the viewport"
		)
	_assert_true(cihang.get_node_or_null("CihangTerrainArt") != null, "cihang exposes the continuous terrain art layer")
	_assert_true(cihang.get_node_or_null("CihangTerrainArt/Grassland") is Polygon2D, "terrain art exposes the grassland region")
	_assert_true(cihang.get_node_or_null("CihangTerrainArt/DeadForest") is Polygon2D, "terrain art exposes the dead forest region")
	_assert_true(cihang.get_node_or_null("CihangTerrainArt/DesertRuins") is Polygon2D, "terrain art exposes the desert ruins region")
	_assert_true(cihang.get_node_or_null("CihangTerrainArt/NorthRoute") is Polygon2D, "terrain art exposes the north route")
	_assert_true(cihang.get_node_or_null("CihangTerrainArt/SouthRoute") is Polygon2D, "terrain art exposes the south route")
	_assert_true(cihang.get_node_or_null("VaultObstacleCihang01") is Area2D, "cihang exposes a vault context zone")
	_assert_true(cihang.get_node_or_null("DeepWaterCihang01") is Area2D, "cihang exposes a deep-water context zone")
	_assert_true(cihang.get_node_or_null("DiggableCollapseCihang01") is Area2D, "cihang exposes a diggable collapse context zone")
	var catalog_for_regions: RefCounted = preload("res://scripts/world/world_scene_catalog.gd").new()
	_assert_true(catalog_for_regions.get_scene_path(3).ends_with("flooded_settlement.tscn"), "floor three has an independent flooded settlement scene path")
	_assert_true(catalog_for_regions.get_scene_path(4).ends_with("abandoned_industry.tscn"), "floor four has an independent industrial scene path")
	_assert_true(catalog_for_regions.get_scene_path(5).ends_with("polluted_forest.tscn"), "floor five has an independent polluted forest scene path")
	for region_path: String in [catalog_for_regions.get_scene_path(3), catalog_for_regions.get_scene_path(4), catalog_for_regions.get_scene_path(5)]:
		var region_scene: PackedScene = load(region_path) as PackedScene
		_assert_true(region_scene != null, "region scene loads from its independent path: %s" % region_path)
		if region_scene != null:
			var region_instance: Node = region_scene.instantiate()
			add_child(region_instance)
			await get_tree().process_frame
			_assert_true(region_instance.get_node_or_null("RegionProfile") != null, "region scene exposes its profile node: %s" % region_path)
			region_instance.queue_free()
			await get_tree().process_frame
	var traversal_player: CharacterBody2D = cihang.get_node("Player") as CharacterBody2D
	_assert_true(traversal_player.has_method("set_traversal_context"), "player exposes the typed traversal context injection")
	if traversal_player.has_method("set_traversal_context"):
		traversal_player.call("set_traversal_context", 2, 6, 0, 2, false)
		_assert_equal(int(traversal_player.call("create_snapshot").get("traversal", {}).get("water_depth_steps", -1)), 2, "player snapshot includes the injected water depth")
	var cihang_objective_label: Label = cihang.get_node_or_null("ObjectiveHUD/ObjectiveLabel") as Label
	_assert_true(cihang_objective_label != null, "cihang outskirts exposes a dedicated objective HUD")
	if cihang_objective_label != null:
		_assert_true(cihang_objective_label.text.contains("慈航郊外"), "cihang objective HUD names the current area")
		_assert_true(
			cihang_objective_label.text.contains("探索") or cihang_objective_label.text.contains("生存"),
			"cihang objective HUD communicates an exploration or survival goal"
		)
	var cihang_resource_ids: Dictionary = {}
	for resource_node: Node in get_tree().get_nodes_in_group("persistent_resource"):
		if cihang.is_ancestor_of(resource_node):
			cihang_resource_ids[String(resource_node.get("entity_id"))] = true
	_assert_true(cihang_resource_ids.has("cihang_wild_food_01"), "cihang places a wild food resource node")
	_assert_true(cihang_resource_ids.has("cihang_scrap_01"), "cihang places a scrap resource node")
	var cihang_background: Polygon2D = cihang.get_node("Background") as Polygon2D
	var cihang_terrain_art: Node2D = cihang.get_node("CihangTerrainArt") as Node2D
	_assert_true(
		cihang_terrain_art.z_index > cihang_background.z_index,
		"cihang terrain art renders above the background plane"
	)
	var north_route: Polygon2D = cihang.get_node("CihangTerrainArt/NorthRoute") as Polygon2D
	var south_route: Polygon2D = cihang.get_node("CihangTerrainArt/SouthRoute") as Polygon2D
	_assert_true(_get_polygon_axis_span(north_route.polygon, false) >= 160.0, "north route keeps the minimum traversable width")
	_assert_true(_get_polygon_axis_span(south_route.polygon, false) >= 160.0, "south route keeps the minimum traversable width")
	var cihang_obstacles: Array[Node] = []
	for obstacle_name: String in ["WildernessTree0", "WildernessRock0", "WildernessWreck0"]:
		var obstacle: Node = cihang.get_node_or_null(obstacle_name)
		if obstacle != null:
			cihang_obstacles.append(obstacle)
		_assert_true(obstacle is StaticBody2D, "%s is a blocking StaticBody2D" % obstacle_name)
		var obstacle_shape: CollisionShape2D = obstacle.get_node_or_null("CollisionShape2D") as CollisionShape2D if obstacle != null else null
		_assert_true(obstacle_shape != null and obstacle_shape.shape != null, "%s owns a valid collision shape" % obstacle_name)
		if obstacle != null:
			_assert_equal((obstacle as StaticBody2D).collision_layer, 1, "%s blocks the environment collision layer" % obstacle_name)
	var cihang_required_clearance_points: Array[NodePath] = [
		NodePath("PlayerSpawn"),
		NodePath("FromBasementSpawn"),
		NodePath("TransitionZone"),
		NodePath("ParasiticFlowerScarlet"),
		NodePath("ParasiticFlowerAshen"),
		NodePath("ParasiticFlowerViolet"),
	]
	for point_path: NodePath in cihang_required_clearance_points:
		var clearance_point: Node2D = cihang.get_node_or_null(point_path) as Node2D
		_assert_true(clearance_point != null, "%s remains available for clearance validation" % point_path)
		if clearance_point != null:
			for obstacle: Node in cihang_obstacles:
				_assert_true(
					clearance_point.global_position.distance_to((obstacle as Node2D).global_position) >= 160.0,
					"%s keeps 160px clearance from %s" % [point_path, obstacle.name]
				)
	var cihang_player_for_blocking: CharacterBody2D = cihang.get_node("Player") as CharacterBody2D
	var tree_for_blocking: StaticBody2D = cihang.get_node("WildernessTree0") as StaticBody2D
	cihang_player_for_blocking.global_position = tree_for_blocking.global_position + Vector2(-120.0, 0.0)
	cihang_player_for_blocking.velocity = Vector2(300.0, 0.0)
	cihang_player_for_blocking.move_and_slide()
	_assert_true(cihang_player_for_blocking.global_position.x < tree_for_blocking.global_position.x - 20.0, "player cannot move through a wilderness tree")
	cihang_player_for_blocking.global_position = cihang.get_node("FromBasementSpawn").global_position
	cihang_player_for_blocking.global_position = Vector2(5680.0, 1620.0)
	cihang_player_for_blocking.velocity = Vector2(300.0, 0.0)
	cihang_player_for_blocking.move_and_slide()
	_assert_true(cihang_player_for_blocking.global_position.x <= 5688.0, "player cannot cross the expanded right boundary wall")
	cihang_player_for_blocking.global_position = cihang.get_node("FromBasementSpawn").global_position
	var cihang_safe_points: Array[NodePath] = [NodePath("PlayerSpawn"), NodePath("FromBasementSpawn"), NodePath("TransitionZone")]
	for point_path: NodePath in cihang_safe_points:
		var point: Node2D = cihang.get_node_or_null(point_path) as Node2D
		_assert_true(point != null, "%s remains present after map expansion" % point_path)
		if point != null:
			_assert_true(point.global_position.x >= 160.0 and point.global_position.x <= 5600.0, "%s stays inside the expanded map buffer" % point_path)
			_assert_true(point.global_position.y >= 160.0 and point.global_position.y <= 3080.0, "%s stays inside the expanded map buffer" % point_path)
	_assert_equal(GameManager.get_run_xp(), 30, "run xp persists after changing world scenes")
	_assert_equal(GameManager.get_run_level(), 2, "run level persists after changing world scenes")
	var cihang_environment_presenter: Node = cihang.get_node_or_null("WorldEnvironmentPresenter")
	_assert_true(cihang_environment_presenter != null, "cihang outskirts instantiates the world environment presenter")
	if cihang_environment_presenter != null:
		_assert_true(cihang_environment_presenter.get_node_or_null("EnvironmentCanvas/MoonSprite") != null, "cihang presenter owns the moon sprite")
		_assert_true(cihang_environment_presenter.get_node_or_null("EnvironmentCanvas/WeatherTint") != null, "cihang presenter owns the weather tint")
		_assert_true(cihang_environment_presenter.get_node_or_null("EnvironmentCanvas/FogLayer") != null, "cihang presenter owns the fog layer")
		_assert_true(cihang_environment_presenter.get_node_or_null("EnvironmentCanvas/ParticleLayer") != null, "cihang presenter owns the particle layer")
		var cihang_silhouette: CanvasItem = cihang_environment_presenter.get_node_or_null("SkyCanvas/WastelandSilhouette") as CanvasItem
		_assert_true(cihang_silhouette != null and not cihang_silhouette.visible, "cihang disables the screen-fixed wasteland silhouette")
	_assert_true(cihang.get_node_or_null("ParasiticFlowerScarlet") != null, "cihang outskirts includes a scarlet parasitic flower variant")
	var dynamic_director: Node = cihang.get_node_or_null("DynamicSpawnDirector")
	_assert_true(dynamic_director != null, "cihang outskirts instantiates the dynamic spawn director")
	if dynamic_director != null:
		_assert_equal((dynamic_director.get("spawn_points") as Array).size(), 2, "cihang configures two tagged fog spawn points")
		_assert_true(dynamic_director.has_method("get_dynamic_enemy_count"), "dynamic spawn director exposes non-objective enemy count")
		var fixed_enemy_count_before: int = 0
		for fixed_candidate: Node in get_tree().get_nodes_in_group("enemy"):
			if cihang.is_ancestor_of(fixed_candidate) and not fixed_candidate.is_in_group("dynamic_enemy"):
				fixed_enemy_count_before += 1
		_assert_true(GameManager.start_next_floor(), "dynamic spawn validation can advance from the prior cleared floor")
		_assert_true(GameManager.prepare_floor(), "dynamic spawn validation enters an exploring state")
		_assert_true(GameManager.tick_survival(720.0) >= 0.0, "survival clock can enter the first night for dynamic spawn validation")
		dynamic_director.call("_process", 100.0)
		await get_tree().process_frame
		_assert_equal(dynamic_director.call("get_dynamic_enemy_count"), 1, "night fog director spawns one independent dynamic enemy wave")
		var fixed_enemy_count_after: int = 0
		for fixed_candidate_after: Node in get_tree().get_nodes_in_group("enemy"):
			if cihang.is_ancestor_of(fixed_candidate_after) and not fixed_candidate_after.is_in_group("dynamic_enemy"):
				fixed_enemy_count_after += 1
		_assert_equal(fixed_enemy_count_after, fixed_enemy_count_before, "dynamic enemies do not change fixed encounter target membership")
		var dynamic_snapshot: Dictionary = dynamic_director.call("create_snapshot")
		_assert_true(dynamic_snapshot.has("threat_budget"), "dynamic director snapshots its independent threat budget")
		_assert_true(dynamic_director.call("restore_snapshot", dynamic_snapshot), "dynamic director restores active enemies atomically")
		_assert_equal(dynamic_director.call("get_dynamic_enemy_count"), 1, "restored dynamic director rebuilds active entity count")
		var restored_dynamic_enemy: Node = (get_tree().get_nodes_in_group("dynamic_enemy")[0] as Node)
		var restored_dynamic_health: Node = restored_dynamic_enemy.get_node_or_null("HealthComponent")
		if restored_dynamic_health != null:
			restored_dynamic_health.call("take_damage", 1000.0)
		_assert_true(restored_dynamic_health != null and restored_dynamic_health.call("is_dead"), "dynamic enemy can be defeated after restore")
		await get_tree().process_frame
		_assert_equal(dynamic_director.call("get_dynamic_enemy_count"), 0, "defeated dynamic enemy releases its director slot")
		_assert_true(GameManager.complete_objective(), "dynamic spawn validation restores the completed objective state")
		_assert_true(cihang.get_node_or_null("ParasiticFlowerAshen") != null, "cihang outskirts includes an ashen parasitic flower variant")
	_assert_true(cihang.get_node_or_null("ParasiticFlowerViolet") != null, "cihang outskirts includes a violet parasitic flower variant")
	_assert_true(cihang.get_node_or_null("ParasiticFlowerScarlet/EncounterMember") == null, "parasitic flowers remain decorative and outside encounter targets")
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
	_assert_true(GameManager.set_run_difficulty(1), "idle session accepts a difficulty choice")
	_assert_true(GameManager.start_run(), "a run can start with the preselected difficulty")
	_assert_equal(GameManager.get_run_difficulty(), 1, "the preselected difficulty is retained at run start")
	_assert_true(not GameManager.set_run_difficulty(0), "the selected difficulty locks for the active run")
	_assert_true(GameManager.start_disaster(0), "hard difficulty accepts its first concurrent disaster")
	_assert_true(GameManager.start_disaster(1), "hard difficulty accepts its second concurrent disaster")
	_assert_true(not GameManager.start_disaster(2), "hard difficulty blocks a third concurrent disaster")
	_assert_equal(GameManager.get_active_disaster_count(), 2, "hard difficulty keeps a two-disaster slot limit")
	_assert_true(GameManager.has_method("get_disaster_kind_at"), "multi-disaster HUD can query every active disaster")
	_assert_true(GameManager.has_method("get_disaster_phase_at"), "multi-disaster HUD can query each disaster phase")
	_assert_true(GameManager.has_method("get_disaster_remaining_seconds_at"), "multi-disaster HUD can query each disaster countdown")
	_assert_true(GameManager.reset_run(), "difficulty test run can reset")
	_assert_true(GameManager.set_run_difficulty(2), "idle session accepts hell difficulty")
	_assert_true(GameManager.start_run(), "hell difficulty run can start")
	_assert_true(GameManager.start_disaster(0), "hell difficulty accepts a first disaster")
	_assert_true(GameManager.start_disaster(1), "hell difficulty accepts a second disaster")
	_assert_true(GameManager.start_disaster(2), "hell difficulty has no numeric disaster slot limit")
	_assert_equal(GameManager.get_active_disaster_count(), 3, "hell difficulty retains every legal concurrent disaster")
	_assert_true(GameManager.reset_run(), "hell difficulty test run can reset")
	_assert_true(GameManager.start_run(0, 13579, 1), "a one-floor run can be started for the final-map integration")
	_assert_equal(GameManager.claim_boss_completion_route(), 0, "boss completion cannot be claimed before final-floor exploration")
	_assert_true(GameManager.prepare_floor(), "the one-floor run can enter exploration")
	_assert_true(GameManager.get_run_seed() == 13579, "the selected run seed is retained")
	var final_map_seed: int = GameManager.get_map_seed()
	_assert_true(final_map_seed != 0, "the final-map run derives a non-zero map seed")
	_assert_true(GameManager.apply_boss_damage(100.0), "final-map boss accepts first combat damage")
	_assert_true(GameManager.acknowledge_boss_phase_transition(), "final-map boss exposes an explicit phase transition")
	_assert_true(GameManager.apply_boss_damage(100.0), "final-map boss accepts second combat damage")
	_assert_true(GameManager.acknowledge_boss_phase_transition(), "final-map boss exposes the second phase transition")
	_assert_true(GameManager.apply_boss_damage(100.0), "final-map boss accepts lethal combat damage")
	_assert_equal(GameManager.get_boss_completion_route(), 1, "combat route completes the final-map boss")
	_assert_equal(GameManager.claim_boss_completion_route(), 1, "final-map combat completion can be claimed")
	_assert_true(GameManager.complete_run(), "claimed boss completion ends a one-floor run")
	var crystals_after_win: int = GameManager.get_meta_crystals()
	_assert_true(crystals_after_win > 0, "winning a run grants meta crystals")
	_assert_true(GameManager.reset_run(), "completed final-map run can be reset")
	_assert_true(GameManager.start_run(0, 24680, 1), "a second one-floor run can start")
	_assert_true(GameManager.prepare_floor(), "the second final-map run can enter exploration")
	GameManager.add_meta_crystals(7)
	var crystals_before_failure: int = GameManager.get_meta_crystals()
	_assert_true(GameManager.mark_dead(), "the final-map run can enter the dead state")
	_assert_true(GameManager.finalize_run_failure(), "final failure settles the dead run")
	_assert_equal(GameManager.get_meta_crystals(), crystals_before_failure, "final failure preserves meta crystals")
	_assert_true(not GameManager.save_safe_exit(), "finalized failure cannot create a safe-exit snapshot")
	_assert_true(GameManager.reset_run(), "failed final-map run can be reset")
	_assert_true(GameManager.start_run(0, 314159, 1), "final core scene run can start")
	_assert_true(GameManager.prepare_floor(), "final core scene run can enter exploration")
	var final_core: Node = FINAL_CORE_SCENE.instantiate()
	add_child(final_core)
	await get_tree().process_frame
	var final_camera: Camera2D = final_core.get_node_or_null("Player/Camera2D") as Camera2D
	_assert_true(final_camera != null and final_camera.enabled, "final core camera is enabled")
	if final_camera != null:
		_assert_true(
			final_camera.limit_right - final_camera.limit_left > viewport_size.x,
			"final core camera limits leave horizontal room for following"
		)
		_assert_true(
			final_camera.limit_bottom - final_camera.limit_top > viewport_size.y,
			"final core camera limits leave vertical room for following"
		)
	var final_environment_presenter: Node = final_core.get_node_or_null("WorldEnvironmentPresenter")
	_assert_true(final_environment_presenter != null, "final core instantiates the world environment presenter")
	if final_environment_presenter != null:
		_assert_true(final_environment_presenter.get_node_or_null("EnvironmentCanvas/MoonSprite") != null, "final presenter owns the moon sprite")
		_assert_true(final_environment_presenter.get_node_or_null("EnvironmentCanvas/WeatherTint") != null, "final presenter owns the weather tint")
		_assert_true(final_environment_presenter.get_node_or_null("EnvironmentCanvas/FogLayer") != null, "final presenter owns the fog layer")
		_assert_true(final_environment_presenter.get_node_or_null("EnvironmentCanvas/ParticleLayer") != null, "final presenter owns the particle layer")
	_assert_true(final_core.get_node_or_null("BossCore") != null, "final core scene instantiates the boss")
	_assert_true(final_core.get_node_or_null("SuppressionComponent0") != null, "final core exposes suppression component zero")
	_assert_true(final_core.get_node_or_null("SuppressionComponent1") != null, "final core exposes suppression component one")
	_assert_true(final_core.get_node_or_null("SuppressionComponent2") != null, "final core exposes suppression component two")
	_assert_true(final_core.get_node_or_null("EnvironmentDevice0") != null, "final core exposes environment device zero")
	_assert_true(final_core.get_node_or_null("EnvironmentDevice1") != null, "final core exposes environment device one")
	_assert_true(final_core.get_node_or_null("EnvironmentDevice2") != null, "final core exposes environment device two")
	_assert_true(final_core.get_node_or_null("BossHUD/BossLabel") != null, "final core displays boss progress HUD")
	_assert_true(final_core.get_node_or_null("FinalExit") != null, "final core exposes a dedicated final exit")
	var final_boss: Node = final_core.get_node("BossCore")
	_assert_true(final_boss.has_method("apply_damage"), "boss scene forwards combat damage")
	_assert_true(final_boss is PhysicsBody2D, "final boss participates in combat collision")
	_assert_equal((final_boss as PhysicsBody2D).collision_layer, 2, "final boss is visible to the player attack layer")
	_assert_true(final_boss.get_node_or_null("HealthComponent") is HealthComponent, "final boss exposes the shared health contract")
	_assert_true(final_boss.has_method("sync_health_from_game_manager"), "final boss exposes domain-health synchronization for restore")
	_assert_true(final_core.get_node("SuppressionComponent0").has_method("collect"), "suppression components expose collection")
	_assert_true(final_core.get_node("SuppressionComponent0") is Area2D, "suppression components expose a player interaction area")
	_assert_true(final_core.get_node("EnvironmentDevice0").has_method("activate"), "environment devices expose activation")
	_assert_true(final_core.get_node("EnvironmentDevice0") is Area2D, "environment devices expose a player interaction area")
	_assert_true(final_core.get_node("FinalExit").has_method("interact"), "final exit exposes an interaction command")
	var final_player: CharacterBody2D = final_core.get_node("Player") as CharacterBody2D
	final_player.global_position = (final_boss as Node2D).global_position + Vector2(48.0, 0.0)
	var boss_health_before_attack: float = GameManager.get_boss_health()
	Input.action_press(&"attack")
	await get_tree().physics_frame
	Input.action_release(&"attack")
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(0.12).timeout
	_assert_true(GameManager.get_boss_health() < boss_health_before_attack, "player melee attack damages the final boss through normal combat collision")
	_assert_true(final_boss.call("apply_damage", 100.0), "final scene boss accepts combat damage")
	_assert_true(GameManager.acknowledge_boss_phase_transition(), "final scene boss phase transition is playable")
	_assert_true(final_boss.call("apply_damage", 100.0), "final scene boss accepts second phase damage")
	_assert_true(GameManager.acknowledge_boss_phase_transition(), "final scene boss second phase transition is playable")
	_assert_true(final_boss.call("apply_damage", 100.0), "final scene boss accepts lethal damage")
	_assert_equal(GameManager.claim_boss_completion_route(), 1, "final scene combat route unlocks the final exit")
	_assert_true(final_core.get_node("FinalExit").call("interact"), "final exit completes the one-floor run")
	_assert_equal(GameManager.get_run_state(), 8, "final exit enters the run-won state")
	final_core.queue_free()
	await get_tree().process_frame
	_assert_true(GameManager.reset_run(), "final core scene run can reset")
	_assert_true(GameManager.start_run(0, 112233, 1), "luck quality sync run can start")
	_assert_true(GameManager.prepare_floor(), "luck quality sync run can enter exploration")
	_assert_true(GameManager.complete_objective(), "luck quality sync run can complete its objective")
	var luck_upgrade: Resource = load("res://assets/upgrades/luck_upgrade.tres") as Resource
	_assert_true(GameManager.apply_run_upgrade(luck_upgrade, 2.3, 3), "a legendary luck reward can be applied")
	var run_buff_draft: RefCounted = GameManager.get("_run_buff_draft") as RefCounted
	_assert_true(run_buff_draft != null, "active run exposes a buff draft model")
	if run_buff_draft != null:
		_assert_true(
			is_equal_approx(float(run_buff_draft.call("get_luck")), GameManager.get_run_luck()),
			"legendary luck reward keeps draft and build luck in sync"
		)
	_assert_true(GameManager.reset_run(), "luck quality sync run can reset")
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


func _not_rects_intersect(first: Rect2, second: Rect2) -> bool:
	return not first.intersects(second, true)


func _rects_intersect(first: Rect2, second: Rect2) -> bool:
	return first.intersects(second, true)


func _get_polygon_axis_span(polygon: PackedVector2Array, use_x_axis: bool) -> float:
	if polygon.is_empty():
		return 0.0
	var minimum: float = INF
	var maximum: float = -INF
	for point: Vector2 in polygon:
		var axis_value: float = point.x if use_x_axis else point.y
		minimum = minf(minimum, axis_value)
		maximum = maxf(maximum, axis_value)
	return maximum - minimum


func _wait_for_animation_state(
	playback: AnimationNodeStateMachinePlayback,
	expected_state: StringName,
	max_frames: int = 6
) -> bool:
	for _frame in range(max_frames):
		if playback.get_current_node() == expected_state:
			return true
		await get_tree().process_frame
	return playback.get_current_node() == expected_state


func _press_interact_key(target: Node) -> void:
	var press_event := InputEventKey.new()
	press_event.keycode = KEY_E
	press_event.physical_keycode = KEY_E
	press_event.pressed = true
	_assert_true(press_event.is_action_pressed(&"interact"), "physical E event maps to interact")
	target.call("_input", press_event)
	await get_tree().process_frame
