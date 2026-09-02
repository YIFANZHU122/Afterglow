extends Node

const RUN_SESSION_MODEL_SCRIPT: Script = preload("res://scripts/core/run_session_model.gd")
const RUN_RANDOM_STREAM_MODEL_SCRIPT: Script = preload("res://scripts/core/run_random_stream_model.gd")
const RUN_SNAPSHOT_DATA_SCRIPT: Script = preload("res://scripts/core/run_snapshot_data.gd")
const RUN_SAVE_MODEL_SCRIPT: Script = preload("res://scripts/core/run_save_model.gd")
const BOSS_PROGRESS_MODEL_SCRIPT: Script = preload("res://scripts/combat/boss_progress_model.gd")
const RUN_REWARD_MODEL_SCRIPT: Script = preload("res://scripts/progression/run_reward_model.gd")
const RUN_BUILD_MODEL_SCRIPT: Script = preload("res://scripts/progression/run_build_model.gd")
const SURVIVAL_TUNING_SCRIPT: Script = preload("res://scripts/data/survival_tuning.gd")
const SURVIVAL_VITALS_MODEL_SCRIPT: Script = preload("res://scripts/player/survival_vitals_model.gd")
const SURVIVAL_CONSUMPTION_MODEL_SCRIPT: Script = preload("res://scripts/player/survival_consumption_model.gd")
const SURVIVAL_CLOCK_MODEL_SCRIPT: Script = preload("res://scripts/world/survival_clock_model.gd")
const DISASTER_SCHEDULER_MODEL_SCRIPT: Script = preload("res://scripts/world/disaster_scheduler_model.gd")
const RESOURCE_BUDGET_MODEL_SCRIPT: Script = preload("res://scripts/world/resource_budget_model.gd")
const ESCAPE_OBJECTIVE_MODEL_SCRIPT: Script = preload("res://scripts/world/escape_objective_model.gd")
const THREAT_BUDGET_MODEL_SCRIPT: Script = preload("res://scripts/world/threat_budget_model.gd")
const DISASTER_EVENT_MODEL_SCRIPT: Script = preload("res://scripts/world/disaster_event_model.gd")
const INVENTORY_MODEL_SCRIPT: Script = preload("res://scripts/items/inventory_model.gd")
const ITEM_CATALOG_SCRIPT: Script = preload("res://scripts/items/item_catalog.gd")
const WORLD_SCENE_CATALOG_SCRIPT: Script = preload("res://scripts/world/world_scene_catalog.gd")
const META_PROGRESSION_MODEL_SCRIPT: Script = preload("res://scripts/progression/meta_progression_model.gd")
const RUN_BUFF_DRAFT_MODEL_SCRIPT: Script = preload("res://scripts/progression/run_buff_draft_model.gd")
const UPGRADE_DEFINITION_SCRIPT: Script = preload("res://scripts/data/upgrade_definition.gd")
const NIGHT_FOG_MODEL_SCRIPT: Script = preload("res://scripts/world/night_fog_model.gd")
const MOON_CYCLE_MODEL_SCRIPT: Script = preload("res://scripts/world/moon_cycle_model.gd")
const DARKNESS_MARK_MODEL_SCRIPT: Script = preload("res://scripts/world/darkness_mark_model.gd")
const NOISE_EVENT_MODEL_SCRIPT: Script = preload("res://scripts/combat/noise_event_model.gd")
const CHARACTER_BUILD_MODEL_SCRIPT: Script = preload("res://scripts/progression/character_build_model.gd")
const CHARACTER_ATTRIBUTES_MODEL_SCRIPT: Script = preload("res://scripts/progression/character_attributes_model.gd")
const EQUIPMENT_MODEL_SCRIPT: Script = preload("res://scripts/items/equipment_model.gd")
const EQUIPMENT_TRANSACTION_MODEL_SCRIPT: Script = preload("res://scripts/items/equipment_transaction_model.gd")
const EQUIPMENT_INTERACTION_MODEL_SCRIPT: Script = preload("res://scripts/player/equipment_interaction_model.gd")
const ENVIRONMENT_EFFECT_RESOLVER_SCRIPT: Script = preload("res://scripts/world/environment_effect_resolver.gd")

## GameManager —— 全局游戏管理器（Autoload 单例）
## 职责：本局运行会话、场景切换、传送出生点记录、传送冷却防抖

signal run_state_changed(state: int, floor_number: int)
signal run_reward_changed(level: int, xp: int, xp_to_next_level: int)
signal run_build_changed(damage_multiplier: float, move_speed_multiplier: float)
signal meta_progression_changed(crystals: int, equipped_initial_buff: StringName, reroll_level: int)
signal survival_changed(
	hunger: float,
	water: float,
	elapsed_seconds: float,
	day_index: int,
	is_night: bool,
	overtime_stage: int,
	disaster_probability: float
)
signal survival_environment_damage(damage_ratio: float)
signal escape_objective_changed(parts: int, fuel: int, cloth: int, key: int, startup_seconds: float, started: bool)
signal disaster_changed(kind: int, phase: int, remaining_seconds: float, risk_level: int, countermeasure_progress: float)
signal boss_progress_changed(phase: int, health: float, completion_route: int, components: int, devices: int)
signal noise_event_emitted(noise_event: RefCounted)

# 传送后玩家应出现的出生点名称（由 TransitionZone 设置，由各场景读取）
var spawn_point_name: String = "PlayerSpawn"

# 传送冷却计时器（秒），防止传送后出生在传送区域内反复触发
var _transition_cooldown: float = 0.0
var _run_session: RefCounted
var _run_random_stream: RefCounted
var _run_save: RefCounted
var _boss_progress: RefCounted
var _run_reward: RefCounted
var _run_build: RefCounted
var _survival_vitals: RefCounted
var _survival_consumption: RefCounted
var _survival_clock: RefCounted
var _disaster_scheduler: RefCounted
var _resource_budget: RefCounted
var _escape_objective: RefCounted
var _threat_budget: RefCounted
var _night_fog: RefCounted
var _moon_cycle: RefCounted
var _darkness_mark: RefCounted
var _active_disasters: Array[RefCounted] = []
var _allowed_disaster_kinds: Array[int] = []
var _disaster_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _run_difficulty: int = SURVIVAL_TUNING_SCRIPT.Difficulty.NORMAL
var _reward_choice_used: bool = false
var _meta_crystals: int = 0
var _meta_progression: RefCounted
var _run_buff_draft: RefCounted
var _character_build: RefCounted
var _equipment_transaction: RefCounted
var _equipment_interaction: RefCounted
var _environment_effect_resolver: RefCounted
var _environment_effects: Dictionary = {}
var _run_settlement_awarded: bool = false
var _pending_scene_state: Dictionary = {}
var _collected_escape_material_ids: Array[String] = []
var _runtime_scene: Node
var _resume_scene_id: StringName = StringName()
var _resume_scene_path: String = ""
var _resume_spawn_point_name: StringName = StringName()

const META_SAVE_PATH: String = "user://afterglow_meta.json"

# 冷却时长
const COOLDOWN_TIME: float = 0.5


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_run_session = RUN_SESSION_MODEL_SCRIPT.new()
	_run_random_stream = RUN_RANDOM_STREAM_MODEL_SCRIPT.new()
	_run_save = RUN_SAVE_MODEL_SCRIPT.new()
	_boss_progress = BOSS_PROGRESS_MODEL_SCRIPT.new()
	_run_reward = RUN_REWARD_MODEL_SCRIPT.new()
	_run_build = RUN_BUILD_MODEL_SCRIPT.new()
	_reset_survival_models()
	_reset_escape_objective()
	_reset_allowed_disaster_kinds()
	_disaster_rng.seed = 20260827
	_meta_progression = META_PROGRESSION_MODEL_SCRIPT.new()
	_run_buff_draft = RUN_BUFF_DRAFT_MODEL_SCRIPT.new(20260827)
	_load_meta_progression()
	_character_build = _create_character_build()
	_equipment_transaction = EQUIPMENT_TRANSACTION_MODEL_SCRIPT.new()
	_equipment_interaction = EQUIPMENT_INTERACTION_MODEL_SCRIPT.new()
	_environment_effect_resolver = ENVIRONMENT_EFFECT_RESOLVER_SCRIPT.new()
	_refresh_environment_effects()


func _process(delta: float) -> void:
	if _transition_cooldown > 0.0:
		_transition_cooldown -= delta
	if _run_session != null and _run_session.is_run_active() and not _run_session.is_paused():
		tick_survival(delta)


## 切换到目标场景，并设置出生点名称
func change_scene(scene_path: String, spawn_name: String = "PlayerSpawn") -> void:
	if _transition_cooldown > 0.0:
		return
	if scene_path.is_empty():
		push_warning("[GameManager] target_scene 路径为空，无法传送！")
		return
	_transition_cooldown = COOLDOWN_TIME
	spawn_point_name = spawn_name
	get_tree().change_scene_to_file(scene_path)


func register_runtime_scene(scene: Node) -> bool:
	if scene == null:
		return false
	var floor_number: int = get_floor_number()
	var catalog: RefCounted = WORLD_SCENE_CATALOG_SCRIPT.new()
	var scene_id: StringName = catalog.get_scene_id(floor_number)
	var scene_path: String = catalog.get_scene_path(floor_number)
	var actual_scene_path: String = String(scene.scene_file_path)
	if scene_id.is_empty() or scene_path.is_empty() or actual_scene_path != scene_path:
		return false
	_runtime_scene = scene
	_resume_scene_id = scene_id
	_resume_scene_path = actual_scene_path
	_resume_spawn_point_name = StringName(spawn_point_name)
	return true


## 开始一局新的运行；仅空闲状态可调用。
func start_run(difficulty: int = -1, run_seed: int = 20260827, total_floors: int = 6) -> bool:
	if _run_session == null or not _run_session.start_run(difficulty, total_floors):
		return false
	_run_difficulty = _run_session.get_difficulty()
	if _run_save != null:
		_run_save.clear_files()
	if _run_random_stream == null:
		_run_random_stream = RUN_RANDOM_STREAM_MODEL_SCRIPT.new()
	if not _run_random_stream.start(run_seed, 1):
		_run_session.reset()
		return false
	get_tree().paused = false
	_run_reward = RUN_REWARD_MODEL_SCRIPT.new()
	_run_build = RUN_BUILD_MODEL_SCRIPT.new()
	_run_buff_draft = RUN_BUFF_DRAFT_MODEL_SCRIPT.new(run_seed)
	_run_buff_draft.add_reroll_charges(_meta_progression.get_run_reroll_charges())
	_apply_equipped_initial_buff()
	_reset_survival_models()
	_reset_escape_objective()
	_boss_progress = BOSS_PROGRESS_MODEL_SCRIPT.new()
	_active_disasters.clear()
	_collected_escape_material_ids.clear()
	_pending_scene_state.clear()
	_resume_scene_id = StringName()
	_resume_scene_path = ""
	_resume_spawn_point_name = StringName()
	_reset_allowed_disaster_kinds()
	_reward_choice_used = false
	_run_settlement_awarded = false
	_emit_run_state_changed()
	_emit_run_reward_changed()
	_emit_run_build_changed()
	_emit_meta_progression_changed()
	_emit_survival_changed()
	_emit_escape_objective_changed()
	_emit_boss_progress_changed()
	return true


## 完成本层准备并进入探索状态。
func prepare_floor() -> bool:
	if _run_session == null or not _run_session.prepare_floor():
		return false
	_emit_run_state_changed()
	return true


## 标记当前楼层目标完成。
func complete_objective() -> bool:
	if _run_session == null or not _run_session.complete_objective():
		return false
	_emit_run_state_changed()
	return true


## 标记当前楼层已清除。
func clear_floor() -> bool:
	if _run_session == null or not _run_session.clear_floor():
		return false
	_emit_run_state_changed()
	return true


func apply_run_upgrade(definition: Resource, quality_multiplier: float = 1.0, quality: int = 0) -> bool:
	if _reward_choice_used or not is_objective_complete() or is_floor_clear() or _run_build == null:
		return false
	if definition == null or definition.get_script() != UPGRADE_DEFINITION_SCRIPT \
		or not bool(definition.call("is_valid")) \
		or not is_finite(quality_multiplier) or quality_multiplier <= 0.0 \
		or quality < UPGRADE_DEFINITION_SCRIPT.Quality.COMMON \
		or quality > UPGRADE_DEFINITION_SCRIPT.Quality.LEGENDARY:
		return false
	var amount: float = float(definition.get("amount"))
	var definition_multiplier: float = float(definition.get("quality_multiplier"))
	var buff_id := StringName(definition.get("buff_id"))
	if buff_id.is_empty():
		buff_id = StringName(definition.get("id"))
	var effect_type: int = int(definition.get("effect_type"))
	var applied_amount: float = amount * maxf(definition_multiplier, 0.0) * quality_multiplier
	if not _run_build.apply_effect(
		effect_type,
		applied_amount,
		buff_id,
		1,
		quality
	):
		return false
	if _run_buff_draft != null:
		_run_buff_draft.apply_candidate(
			buff_id,
			applied_amount if effect_type == UPGRADE_DEFINITION_SCRIPT.EffectType.LUCK else 0.1
		)
	_reward_choice_used = true
	_emit_run_build_changed()
	return clear_floor()


func get_run_damage_multiplier() -> float:
	return _run_build.get_damage_multiplier() if _run_build != null else 1.0


func get_character_build_model() -> RefCounted:
	return _character_build


func allocate_character_attribute(attribute: int, amount: int = 1) -> bool:
	return _character_build != null and _character_build.allocate_attribute(attribute, amount)


func confirm_character_attributes() -> bool:
	return _character_build != null and _character_build.confirm_attributes()


func get_character_attribute_points_remaining() -> int:
	return _character_build.get_attribute_points_remaining() if _character_build != null else 0


func get_character_attribute_total_points() -> int:
	return _character_build.get_attribute_total_points() if _character_build != null else 0


func get_character_attribute_value(attribute: int) -> int:
	return _character_build.get_attribute_value(attribute) if _character_build != null else 0


func are_character_attributes_confirmed() -> bool:
	return _character_build != null and _character_build.are_attributes_confirmed()


func equip_character_item(item_id: StringName) -> bool:
	if _character_build == null or item_id.is_empty():
		return false
	var item: ItemData = ITEM_CATALOG_SCRIPT.new().get_item(item_id)
	if item == null:
		return false
	var before: Dictionary = _character_build.create_snapshot()
	if not _character_build.equip_item(item, Inventory.get_occupied_slot_count()):
		return false
	if not Inventory.configure_slot_count(_character_build.get_inventory_slot_count()):
		_character_build.restore_snapshot(before, ITEM_CATALOG_SCRIPT.new())
		return false
	return true


func start_equipping_selected_item() -> bool:
	if _equipment_interaction == null or _character_build == null or _run_session == null \
		or not _run_session.is_run_active() or _run_session.is_paused():
		return false
	var item: ItemData = Inventory.get_selected_item()
	if item == null or item.item_type != ItemData.ItemType.EQUIPMENT or item.equipment_definition == null:
		return false
	return _equipment_interaction.start(int(item.equipment_definition.slot), item.id)


func start_unequipping_character_slot(slot: int) -> bool:
	if _equipment_interaction == null or _character_build == null or _run_session == null \
		or not _run_session.is_run_active() or _run_session.is_paused():
		return false
	var item_id: StringName = _character_build.get_equipped_item_id(slot)
	if item_id.is_empty():
		return false
	return _equipment_interaction.start_unequip(slot, item_id)


func advance_character_equipment_interaction(delta: float, is_moving: bool, was_hit: bool) -> bool:
	if _equipment_interaction == null or _equipment_transaction == null or _character_build == null:
		return false
	if not _equipment_interaction.advance(delta, is_moving, was_hit):
		return false
	var request: Dictionary = _equipment_interaction.consume_completed()
	var operation: int = int(request.get("operation", -1))
	var slot: int = int(request.get("slot", -1))
	if operation == EQUIPMENT_INTERACTION_MODEL_SCRIPT.Operation.EQUIP:
		return _equipment_transaction.equip_selected(Inventory, _character_build, ITEM_CATALOG_SCRIPT.new())
	if operation == EQUIPMENT_INTERACTION_MODEL_SCRIPT.Operation.UNEQUIP:
		return _equipment_transaction.unequip_slot(Inventory, _character_build, ITEM_CATALOG_SCRIPT.new(), slot)
	return false


func cancel_character_equipment_interaction() -> bool:
	return _equipment_interaction != null and _equipment_interaction.cancel()


func get_character_equipment_interaction_remaining_seconds() -> float:
	return _equipment_interaction.get_remaining_seconds() if _equipment_interaction != null else 0.0


func unequip_character_slot(slot: int) -> bool:
	return _equipment_transaction != null and _character_build != null \
		and _equipment_transaction.unequip_slot(Inventory, _character_build, ITEM_CATALOG_SCRIPT.new(), slot)


func get_run_move_speed_multiplier() -> float:
	return _run_build.get_move_speed_multiplier() if _run_build != null else 1.0


func get_run_upgrade_stack(upgrade_id: StringName) -> int:
	return _run_build.get_upgrade_stack(upgrade_id) if _run_build != null else 0


func get_run_max_health_multiplier() -> float:
	return _run_build.get_max_health_multiplier() if _run_build != null else 1.0


func get_run_damage_reduction() -> float:
	return _run_build.get_damage_reduction() if _run_build != null else 0.0


func get_run_max_stamina_multiplier() -> float:
	return _run_build.get_max_stamina_multiplier() if _run_build != null else 1.0


func get_run_max_stamina_bonus() -> float:
	return get_run_max_stamina_multiplier() - 1.0


func get_run_stamina_regen_multiplier() -> float:
	return _run_build.get_stamina_regen_multiplier() if _run_build != null else 1.0


func get_run_xp_multiplier() -> float:
	return _run_build.get_xp_multiplier() if _run_build != null else 1.0


func get_run_luck() -> float:
	return _run_build.get_luck() if _run_build != null else 0.0


func get_run_survival_consumption_multiplier() -> float:
	return _run_build.get_survival_consumption_multiplier() if _run_build != null else 1.0


func get_run_upgrade_quality(upgrade_id: StringName) -> int:
	return _run_build.get_upgrade_quality(upgrade_id) if _run_build != null else 0


func get_run_upgrade_stacks() -> Dictionary:
	return _run_build.get_upgrade_stacks() if _run_build != null else {}


func get_run_buff_summary() -> Array[Dictionary]:
	return _run_build.get_buff_summary() if _run_build != null else []


func get_run_reroll_charges() -> int:
	return _run_buff_draft.get_reroll_charges() if _run_buff_draft != null else 0


func refresh_run_buff_candidates(buff_ids: Array, count: int = 4) -> Array[Dictionary]:
	if _run_buff_draft == null:
		return []
	return _run_buff_draft.generate_candidates(buff_ids, count)


func consume_run_buff_reroll() -> bool:
	return _run_buff_draft != null and _run_buff_draft.consume_reroll()


func apply_run_buff_effect(effect_type: int, amount: float, buff_id: StringName, quality_multiplier: float = 1.0) -> bool:
	if _run_build == null or _run_buff_draft == null:
		return false
	var scaled_amount := amount * maxf(quality_multiplier, 0.0)
	if not _run_build.apply_effect(effect_type, scaled_amount, buff_id):
		return false
	_run_buff_draft.apply_candidate(
		buff_id,
		scaled_amount if effect_type == UPGRADE_DEFINITION_SCRIPT.EffectType.LUCK else 0.1
	)
	_emit_run_build_changed()
	return true


func is_floor_clear() -> bool:
	return get_run_state() == RUN_SESSION_MODEL_SCRIPT.State.FLOOR_CLEAR


## 开始下一层并进入准备状态。
func start_next_floor() -> bool:
	if _run_session == null or not _run_session.start_next_floor():
		return false
	_run_difficulty = _run_session.get_difficulty()
	if _run_random_stream != null:
		_run_random_stream.begin_floor(_run_session.get_floor_number())
	_survival_clock = SURVIVAL_CLOCK_MODEL_SCRIPT.new()
	_disaster_scheduler = DISASTER_SCHEDULER_MODEL_SCRIPT.new(_run_difficulty)
	_threat_budget = THREAT_BUDGET_MODEL_SCRIPT.new()
	_active_disasters.clear()
	_collected_escape_material_ids.clear()
	_pending_scene_state.clear()
	_reset_allowed_disaster_kinds()
	_reset_escape_objective()
	_boss_progress = BOSS_PROGRESS_MODEL_SCRIPT.new()
	_reward_choice_used = false
	_emit_run_state_changed()
	_emit_survival_changed()
	_emit_escape_objective_changed()
	return true


## 标记本局死亡。
func mark_dead() -> bool:
	if _run_session == null or not _run_session.mark_dead():
		return false
	_emit_run_state_changed()
	return true


func revive() -> bool:
	if _run_session == null or not _run_session.revive():
		return false
	_emit_run_state_changed()
	return true


## 结束本局，保留会话结果直到显式重置。
func end_run() -> bool:
	if _run_session == null or not _run_session.end_run():
		return false
	_reset_escape_objective()
	_active_disasters.clear()
	_reset_allowed_disaster_kinds()
	_emit_run_state_changed()
	_emit_escape_objective_changed()
	return true


func complete_run() -> bool:
	if _run_session == null or _boss_progress == null or _run_settlement_awarded:
		return false
	if not bool(_boss_progress.call("is_completion_claimed")) or not _run_session.complete_run():
		return false
	_run_settlement_awarded = true
	add_meta_crystals(20)
	if _run_save != null:
		_run_save.invalidate_run("victory-%d" % get_run_seed())
	_reset_escape_objective()
	_active_disasters.clear()
	_reset_allowed_disaster_kinds()
	_emit_run_state_changed()
	_emit_escape_objective_changed()
	return true


func finalize_run_failure() -> bool:
	if _run_session == null or _run_settlement_awarded or not _run_session.end_run():
		return false
	_run_settlement_awarded = true
	if _run_save != null:
		_run_save.invalidate_run("failure-%d" % get_run_seed())
	if _run_reward != null:
		_run_reward.reset()
	if _run_build != null:
		_run_build.reset()
	_character_build = _create_character_build()
	_run_buff_draft = RUN_BUFF_DRAFT_MODEL_SCRIPT.new()
	Inventory.drop_all()
	_reward_choice_used = false
	_reset_survival_models()
	_reset_escape_objective()
	_boss_progress = BOSS_PROGRESS_MODEL_SCRIPT.new()
	_run_random_stream = RUN_RANDOM_STREAM_MODEL_SCRIPT.new()
	_active_disasters.clear()
	_reset_allowed_disaster_kinds()
	_emit_run_state_changed()
	_emit_run_reward_changed()
	_emit_run_build_changed()
	_emit_survival_changed()
	_emit_escape_objective_changed()
	_emit_boss_progress_changed()
	return true


## 重置本局状态，为下一次开始做准备。
func reset_run() -> bool:
	if _run_session == null:
		return false
	var session_changed: bool = _run_session.reset()
	var reward_changed: bool = _run_reward.reset() if _run_reward != null else false
	var build_changed: bool = _run_build.reset() if _run_build != null else false
	_character_build = _create_character_build()
	_run_buff_draft = RUN_BUFF_DRAFT_MODEL_SCRIPT.new()
	_reward_choice_used = false
	_run_difficulty = SURVIVAL_TUNING_SCRIPT.Difficulty.NORMAL
	_run_difficulty = _run_session.get_difficulty()
	_reset_survival_models()
	_reset_escape_objective()
	_active_disasters.clear()
	_collected_escape_material_ids.clear()
	_pending_scene_state.clear()
	_resume_scene_id = StringName()
	_resume_scene_path = ""
	_resume_spawn_point_name = StringName()
	_boss_progress = BOSS_PROGRESS_MODEL_SCRIPT.new()
	_run_random_stream = RUN_RANDOM_STREAM_MODEL_SCRIPT.new()
	_run_settlement_awarded = false
	_reset_allowed_disaster_kinds()
	get_tree().paused = false
	if not session_changed and not reward_changed and not build_changed:
		return false
	_emit_run_state_changed()
	_emit_run_reward_changed()
	_emit_run_build_changed()
	_emit_survival_changed()
	_emit_escape_objective_changed()
	return true


func tick_survival(delta: float) -> float:
	if delta <= 0.0 or _run_session == null or not _run_session.is_run_active() or _run_session.is_paused():
		return 0.0
	if _survival_vitals == null or _survival_clock == null or _disaster_scheduler == null:
		return 0.0
	_survival_clock.advance(delta)
	_refresh_environment_effects()
	if _threat_budget != null:
		_threat_budget.set_time_context(_survival_clock.get_day_index(), _survival_clock.get_overtime_stage())
	var consumption_multiplier: float = SURVIVAL_TUNING_SCRIPT.difficulty_consumption_multiplier(_run_difficulty) \
		* get_run_survival_consumption_multiplier() \
		* _survival_consumption.get_consumption_multiplier() \
		* maxf(float(_environment_effects.get("hunger_drain_multiplier", 1.0)), float(_environment_effects.get("water_drain_multiplier", 1.0)))
	var damage_ratio: float = _survival_vitals.tick(
		delta,
		consumption_multiplier
	)
	damage_ratio += delta * float(_environment_effects.get("hazard_damage_per_second", 0.0))
	_survival_consumption.tick(delta)
	advance_disasters(delta)
	if _disaster_scheduler.should_check(delta):
		var disaster_rng := RandomNumberGenerator.new()
		disaster_rng.seed = maxi(random_int(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_DISASTERS, 1, 2147483646), 1)
		if _disaster_scheduler.roll_trigger(
			disaster_rng,
			_survival_clock.get_elapsed_seconds(),
			get_active_disaster_count()
		):
			var kind: int = _disaster_scheduler.roll_disaster_kind(
				disaster_rng,
				_survival_clock.get_elapsed_seconds(),
				_survival_clock.is_night()
			)
			if not start_disaster(kind):
				_disaster_scheduler.register_miss()
	if damage_ratio > 0.0:
		survival_environment_damage.emit(damage_ratio)
	_emit_survival_changed()
	return damage_ratio


func consume_food(amount: float) -> bool:
	if _survival_vitals == null or not _run_session.is_run_active() or _run_session.is_paused():
		return false
	var consumed: bool = _survival_vitals.consume_food(amount)
	if consumed:
		_emit_survival_changed()
	return consumed


func consume_water(amount: float) -> bool:
	if _survival_vitals == null or not _run_session.is_run_active() or _run_session.is_paused():
		return false
	var consumed: bool = _survival_vitals.consume_water(amount)
	if consumed:
		_emit_survival_changed()
	return consumed


func use_selected_item() -> bool:
	if _survival_vitals == null or _survival_consumption == null or _run_session == null \
		or not _run_session.is_run_active() or _run_session.is_paused():
		return false
	var item: ItemData = Inventory.get_selected_item()
	if item == null:
		return false
	if item.item_type == ItemData.ItemType.EQUIPMENT:
		return start_equipping_selected_item()
	var vitals_before: Dictionary = _survival_vitals.create_snapshot()
	var disease_before: Dictionary = _survival_consumption.create_snapshot()
	var consumed: bool = false
	if item.item_type == ItemData.ItemType.FOOD:
		var disease_chance: float = item.disease_chance * (1.0 + float(_run_difficulty) * 0.2)
		var roll: float = random_float(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_CONTAINERS)
		consumed = _survival_consumption.consume_food(item, _survival_vitals, roll, disease_chance)
	elif item.item_type == ItemData.ItemType.CONTAINER:
		var container_state: Dictionary = Inventory.get_selected_container_snapshot()
		var amount: int = int(container_state.get("amount", 0))
		if amount <= 0:
			return false
		var water_disease_chance: float = _water_disease_chance(int(container_state.get("source", 0)))
		consumed = _survival_consumption.consume_water(
			10.0,
			_survival_vitals,
			random_float(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_CONTAINERS),
			0.0 if bool(container_state.get("purified", false)) else water_disease_chance
		)
	elif item.water_restore > 0.0:
		consumed = _survival_consumption.consume_water(
			item.water_restore,
			_survival_vitals,
			random_float(RUN_RANDOM_STREAM_MODEL_SCRIPT.STREAM_CONTAINERS)
		)
	var consumed_inventory: bool = Inventory.consume_selected_water(1) if item.item_type == ItemData.ItemType.CONTAINER else Inventory.consume_selected(1)
	if not consumed or not consumed_inventory:
		_survival_vitals.restore_snapshot(vitals_before)
		_survival_consumption.restore_snapshot(disease_before)
		return false
	_emit_survival_changed()
	return true


func fill_selected_container_from_source(source_type: int, amount: int = 1) -> bool:
	if _run_session == null or not _run_session.is_run_active() or _run_session.is_paused() or amount <= 0:
		return false
	return Inventory.fill_selected_container(source_type, amount, false)


func get_water_disease_chance(source_type: int) -> float:
	return _water_disease_chance(source_type)


func _water_disease_chance(source_type: int) -> float:
	var base: float = 0.35
	match source_type:
		1:
			base = 0.10
		2:
			base = 0.20
		3:
			base = 0.35
		_:
			base = 0.35
	return clampf(base + 0.05 * float(_run_difficulty), 0.0, 1.0)


func has_disease() -> bool:
	return _survival_consumption != null and _survival_consumption.has_disease()


func get_disease_remaining_seconds() -> float:
	return _survival_consumption.get_disease_remaining_seconds() if _survival_consumption != null else 0.0


func cure_disease() -> bool:
	if _survival_consumption == null or not _survival_consumption.cure():
		return false
	_emit_survival_changed()
	return true


func collect_escape_material(material_type: int, amount: int = 1) -> bool:
	if _escape_objective == null or not _run_session.is_run_active() or _run_session.is_paused():
		return false
	var collected: bool = _escape_objective.collect_material(material_type, amount)
	if collected:
		_emit_escape_objective_changed()
	return collected


func record_escape_material_entity(entity_id: String) -> bool:
	if entity_id.is_empty() or _collected_escape_material_ids.has(entity_id):
		return false
	_collected_escape_material_ids.append(entity_id)
	return true


func get_escape_material_required(material_type: int) -> int:
	return _escape_objective.get_required_amount(material_type) if _escape_objective != null else 0


func get_escape_material_collected(material_type: int) -> int:
	return _escape_objective.get_collected_amount(material_type) if _escape_objective != null else 0


func has_all_escape_materials() -> bool:
	return _escape_objective != null and _escape_objective.has_all_materials()


func advance_escape_exit(delta: float, player_moving: bool, was_hit: bool, enemy_nearby: bool) -> bool:
	if _escape_objective == null or not _run_session.is_run_active() or _run_session.is_paused():
		return false
	var started: bool = _escape_objective.advance_exit_startup(delta, player_moving, was_hit, enemy_nearby)
	_emit_escape_objective_changed()
	return started


func get_escape_startup_seconds() -> float:
	return _escape_objective.get_exit_startup_seconds() if _escape_objective != null else 0.0


func is_escape_exit_started() -> bool:
	return _escape_objective != null and _escape_objective.is_exit_started()


func depart_floor() -> bool:
	if not is_floor_clear() or _escape_objective == null or not _escape_objective.is_exit_started():
		return false
	if _run_session.is_final_floor():
		return false
	var boundary_snapshot: RefCounted = _create_run_snapshot()
	if not save_floor_boundary(boundary_snapshot):
		return false
	if not _escape_objective.consume_for_departure():
		return false
	if not start_next_floor():
		return false
	_emit_escape_objective_changed()
	return true


func get_guaranteed_food_budget() -> int:
	return _resource_budget.get_guaranteed_food() if _resource_budget != null else 0


func get_guaranteed_water_budget() -> int:
	return _resource_budget.get_guaranteed_water() if _resource_budget != null else 0


func get_total_food_budget() -> int:
	return _resource_budget.get_total_food() if _resource_budget != null else 0


func get_total_water_budget() -> int:
	return _resource_budget.get_total_water() if _resource_budget != null else 0


func pause_run() -> bool:
	if _run_session == null or not _run_session.pause():
		return false
	get_tree().paused = true
	_emit_run_state_changed()
	_emit_survival_changed()
	return true


func resume_run() -> bool:
	if _run_session == null or not _run_session.resume():
		return false
	get_tree().paused = false
	_emit_run_state_changed()
	_emit_survival_changed()
	return true


func set_run_difficulty(difficulty: int) -> bool:
	if _run_session == null or not _run_session.configure_difficulty(difficulty):
		return false
	_run_difficulty = _run_session.get_difficulty()
	return true


func get_run_difficulty() -> int:
	return _run_session.get_difficulty() if _run_session != null else _run_difficulty


func get_run_seed() -> int:
	return int(_run_random_stream.call("get_run_seed")) if _run_random_stream != null else 0


func get_map_seed() -> int:
	return int(_run_random_stream.call("get_map_seed")) if _run_random_stream != null else 0


func get_random_event_index(stream_name: StringName) -> int:
	return int(_run_random_stream.call("get_event_index", stream_name)) if _run_random_stream != null else -1


func random_int(stream_name: StringName, from: int, to: int) -> int:
	if _run_random_stream == null or _run_session == null or not _run_session.is_run_active():
		return 0
	return int(_run_random_stream.call("randi_range", stream_name, from, to))


func random_float(stream_name: StringName) -> float:
	if _run_random_stream == null or _run_session == null or not _run_session.is_run_active():
		return 0.0
	return float(_run_random_stream.call("randf", stream_name))


func emit_noise_event(noise_event: RefCounted) -> bool:
	if noise_event == null or noise_event.get_script() != NOISE_EVENT_MODEL_SCRIPT:
		return false
	noise_event_emitted.emit(noise_event)
	return true


func apply_boss_damage(amount: float) -> bool:
	if not _can_advance_boss() or not bool(_boss_progress.call("apply_combat_damage", amount)):
		return false
	_emit_boss_progress_changed()
	return true


func acknowledge_boss_phase_transition() -> bool:
	if not _can_advance_boss() or not bool(_boss_progress.call("acknowledge_phase_transition")):
		return false
	_emit_boss_progress_changed()
	return true


func collect_boss_component(component_index: int) -> bool:
	if not _can_advance_boss() or not bool(_boss_progress.call("collect_suppression_component", component_index)):
		return false
	_emit_boss_progress_changed()
	return true


func activate_boss_device(device_index: int) -> bool:
	if not _can_advance_boss() or not bool(_boss_progress.call("activate_environment_device", device_index)):
		return false
	_emit_boss_progress_changed()
	return true


func claim_boss_completion_route() -> int:
	if _boss_progress == null or _run_session == null or not _run_session.is_final_floor() \
		or _run_session.get_state() != RUN_SESSION_MODEL_SCRIPT.State.EXPLORING:
		return BOSS_PROGRESS_MODEL_SCRIPT.CompletionRoute.NONE
	var route: int = int(_boss_progress.call("claim_completion_route"))
	if route == BOSS_PROGRESS_MODEL_SCRIPT.CompletionRoute.NONE:
		return route
	if not _run_session.complete_objective() or not _run_session.clear_floor():
		return BOSS_PROGRESS_MODEL_SCRIPT.CompletionRoute.NONE
	_emit_boss_progress_changed()
	_emit_run_state_changed()
	return route


func get_boss_phase() -> int:
	return int(_boss_progress.call("get_phase")) if _boss_progress != null else BOSS_PROGRESS_MODEL_SCRIPT.Phase.FIRST


func get_boss_health() -> float:
	return float(_boss_progress.call("get_health")) if _boss_progress != null else 0.0


func is_boss_phase_transition_pending() -> bool:
	return _boss_progress != null and bool(_boss_progress.call("is_phase_transition_pending"))


func get_boss_collected_component_count() -> int:
	return int(_boss_progress.call("get_collected_component_count")) if _boss_progress != null else 0


func get_boss_activated_device_count() -> int:
	return int(_boss_progress.call("get_activated_device_count")) if _boss_progress != null else 0


func get_boss_completion_route() -> int:
	return int(_boss_progress.call("get_completion_route")) if _boss_progress != null else BOSS_PROGRESS_MODEL_SCRIPT.CompletionRoute.NONE


func add_meta_crystals(amount: int) -> bool:
	if amount <= 0:
		return false
	if _meta_progression == null:
		_meta_progression = META_PROGRESSION_MODEL_SCRIPT.new()
	_meta_progression.add_crystals(amount)
	_meta_crystals = _meta_progression.get_crystals()
	_save_meta_progression()
	_emit_meta_progression_changed()
	return true


func get_meta_crystals() -> int:
	return _meta_progression.get_crystals() if _meta_progression != null else _meta_crystals


func get_meta_lifetime_crystals() -> int:
	return _meta_progression.get_lifetime_crystals() if _meta_progression != null else 0


func get_meta_crystal_tier() -> int:
	return _meta_progression.get_crystal_tier() if _meta_progression != null else 0


func get_meta_attribute_point_bonus() -> int:
	return _meta_progression.get_attribute_point_bonus() if _meta_progression != null else 0


func purchase_initial_buff(buff_id: StringName, cost: int = 10) -> bool:
	if _meta_progression == null or not _meta_progression.purchase_initial_buff(buff_id, cost):
		return false
	_meta_crystals = _meta_progression.get_crystals()
	_save_meta_progression()
	_emit_meta_progression_changed()
	return true


func equip_initial_buff(buff_id: StringName) -> bool:
	if _meta_progression == null or not _meta_progression.equip_initial_buff(buff_id):
		return false
	_save_meta_progression()
	_emit_meta_progression_changed()
	return true


func purchase_reroll_level(cost: int) -> bool:
	if _meta_progression == null or not _meta_progression.purchase_reroll_level(cost):
		return false
	_meta_crystals = _meta_progression.get_crystals()
	_save_meta_progression()
	_emit_meta_progression_changed()
	return true


func get_equipped_initial_buff() -> StringName:
	return _meta_progression.get_equipped_initial_buff() if _meta_progression != null else StringName()


func get_initial_buff_level(buff_id: StringName) -> int:
	return _meta_progression.get_initial_buff_level(buff_id) if _meta_progression != null else 0


func get_meta_reroll_level() -> int:
	return _meta_progression.get_reroll_level() if _meta_progression != null else 0


func has_valid_run_snapshot() -> bool:
	return _run_save != null and bool(_run_save.call("has_valid_run"))


func save_safe_exit(snapshot: RefCounted = null) -> bool:
	if _run_save == null or _run_session == null or not _run_session.is_run_active() or _run_settlement_awarded:
		return false
	var run_snapshot: RefCounted = snapshot if snapshot != null else _create_run_snapshot()
	return bool(_run_save.call("save_safe_exit", run_snapshot))


func save_floor_boundary(snapshot: RefCounted = null) -> bool:
	if _run_save == null or _run_session == null or not _run_session.is_run_active() or _run_settlement_awarded:
		return false
	var run_snapshot: RefCounted = snapshot if snapshot != null else _create_run_snapshot()
	return bool(_run_save.call("save_floor_boundary", run_snapshot))


func restore_safe_exit() -> bool:
	if _run_save == null or _run_session == null or not _run_session.get_state() == RUN_SESSION_MODEL_SCRIPT.State.IDLE:
		return false
	var snapshot: RefCounted = _run_save.call("load_latest") as RefCounted
	if snapshot == null:
		return false
	if not _restore_run_snapshot(snapshot):
		return false
	get_tree().paused = _run_session.is_paused()
	_emit_all_runtime_state()
	return true


func restore_safe_exit_to_scene() -> bool:
	if _run_save == null or _run_session == null or not _run_session.get_state() == RUN_SESSION_MODEL_SCRIPT.State.IDLE:
		return false
	var snapshot: RefCounted = _run_save.call("load_latest") as RefCounted
	if snapshot == null:
		return false
	var session_state: Dictionary = snapshot.get("run_session_state") as Dictionary
	if session_state == null:
		return false
	var floor_number: int = int(session_state.get("floor_number", 0))
	var scene_id: StringName = StringName(session_state.get("scene_id", ""))
	var scene_path: String = String(session_state.get("scene_path", ""))
	var spawn_name: StringName = StringName(session_state.get("spawn_point_name", ""))
	var catalog: RefCounted = WORLD_SCENE_CATALOG_SCRIPT.new()
	if not catalog.is_valid_location(floor_number, scene_id, scene_path) \
		or not catalog.is_valid_spawn_point(floor_number, spawn_name):
		return false
	if not _restore_run_snapshot(snapshot):
		return false
	_resume_scene_id = scene_id
	_resume_scene_path = scene_path
	_resume_spawn_point_name = spawn_name
	spawn_point_name = String(spawn_name)
	get_tree().paused = _run_session.is_paused()
	_emit_all_runtime_state()
	change_scene(scene_path, String(spawn_name))
	return true


func get_resume_scene_path() -> String:
	return _resume_scene_path


func get_resume_scene_id() -> StringName:
	return _resume_scene_id


func get_resume_spawn_point_name() -> StringName:
	return _resume_spawn_point_name


func get_hunger() -> float:
	return _survival_vitals.get_hunger() if _survival_vitals != null else 0.0


func get_water() -> float:
	return _survival_vitals.get_water() if _survival_vitals != null else 0.0


func get_survival_stamina_recovery_multiplier() -> float:
	return _survival_vitals.get_stamina_recovery_multiplier() if _survival_vitals != null else 1.0


func get_survival_healing_multiplier() -> float:
	return _survival_vitals.get_healing_multiplier() if _survival_vitals != null else 1.0


func get_survival_stamina_cost_multiplier() -> float:
	return _survival_vitals.get_stamina_cost_multiplier() if _survival_vitals != null else 1.0


func get_survival_move_speed_multiplier() -> float:
	return _survival_vitals.get_move_speed_multiplier() if _survival_vitals != null else 1.0


func get_floor_elapsed_seconds() -> float:
	return _survival_clock.get_elapsed_seconds() if _survival_clock != null else 0.0


func get_floor_day_index() -> int:
	return _survival_clock.get_day_index() if _survival_clock != null else 1


func is_floor_night() -> bool:
	return _survival_clock.is_night() if _survival_clock != null else false


func get_overtime_stage() -> int:
	return _survival_clock.get_overtime_stage() if _survival_clock != null else 0


func get_night_index() -> int:
	if _survival_clock == null:
		return 0
	return maxi(int(floor(_survival_clock.get_elapsed_seconds() / SURVIVAL_TUNING_SCRIPT.CYCLE_DURATION_SECONDS)), 0)


func get_night_fog_phase() -> int:
	if _night_fog == null or _survival_clock == null:
		return 0
	var cycle_seconds: float = fmod(_survival_clock.get_elapsed_seconds(), SURVIVAL_TUNING_SCRIPT.CYCLE_DURATION_SECONDS)
	var night_elapsed: float = maxf(cycle_seconds - SURVIVAL_TUNING_SCRIPT.DAY_DURATION_SECONDS, 0.0)
	return int(_night_fog.get_phase(night_elapsed, _survival_clock.is_night()))


func get_moon_kind() -> int:
	return int(_moon_cycle.get_kind(get_night_index())) if _moon_cycle != null else 0


func get_monster_spawn_multiplier() -> float:
	return float(_moon_cycle.get_monster_spawn_multiplier(get_night_index())) if _moon_cycle != null else 1.0


func get_special_spawn_ratio() -> float:
	return float(_moon_cycle.get_special_spawn_ratio(get_night_index())) if _moon_cycle != null else 0.0


func get_enemy_speed_multiplier() -> float:
	return float(_moon_cycle.get_enemy_speed_multiplier(get_night_index())) if _moon_cycle != null else 1.0


func get_night_elapsed_seconds() -> float:
	if _survival_clock == null:
		return 0.0
	var cycle_seconds: float = fmod(_survival_clock.get_elapsed_seconds(), SURVIVAL_TUNING_SCRIPT.CYCLE_DURATION_SECONDS)
	return maxf(cycle_seconds - SURVIVAL_TUNING_SCRIPT.DAY_DURATION_SECONDS, 0.0)


func is_new_moon() -> bool:
	return _moon_cycle != null and _moon_cycle.is_new_moon(get_night_index())


func register_darkness_attack(fully_dark: bool) -> bool:
	return _darkness_mark != null and _darkness_mark.register_dark_attack(is_new_moon(), fully_dark, get_night_index())


func has_darkness_mark() -> bool:
	return _darkness_mark != null and _darkness_mark.has_pending_mark()


func consume_new_moon_mark() -> Dictionary:
	return _darkness_mark.consume_for_new_moon() if _darkness_mark != null else {"budget_multiplier": 1.0, "special_tier_two_warning": false}


func get_disaster_probability() -> float:
	return _disaster_scheduler.get_trigger_probability(get_floor_elapsed_seconds()) \
		if _disaster_scheduler != null else 0.0


func get_environment_effects() -> Dictionary:
	return _environment_effects.duplicate(true)


func _refresh_environment_effects() -> void:
	if _environment_effect_resolver == null:
		_environment_effects = {}
		return
	var disaster_kinds: Array[int] = []
	for event: RefCounted in _active_disasters:
		if bool(event.call("is_active")):
			disaster_kinds.append(int(event.call("get_kind")))
	var weather: StringName = &"clear"
	if disaster_kinds.has(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.RAINSTORM):
		weather = &"rain"
	elif disaster_kinds.has(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.HEATWAVE):
		weather = &"heatwave"
	elif disaster_kinds.has(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.DENSE_FOG):
		weather = &"dense_fog"
	elif disaster_kinds.has(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.COLD_SNAP):
		weather = &"cold_snap"
	_environment_effects = _environment_effect_resolver.resolve(weather, disaster_kinds, 0, false)


func start_disaster(kind: int) -> bool:
	if _run_session == null or not _run_session.is_run_active() or _run_session.is_paused():
		return false
	if _disaster_scheduler == null:
		return false
	if not _allowed_disaster_kinds.has(kind):
		return false
	var slot_limit: int = _get_disaster_slot_limit()
	if slot_limit >= 0 and get_active_disaster_count() >= slot_limit:
		return false
	if _has_active_disaster_kind(kind):
		return false
	var elapsed_seconds: float = get_floor_elapsed_seconds()
	if not _disaster_scheduler.can_trigger_kind(kind, elapsed_seconds):
		return false
	var event: RefCounted = DISASTER_EVENT_MODEL_SCRIPT.new()
	if not bool(event.call("start_warning", kind, elapsed_seconds)):
		return false
	if not _disaster_scheduler.register_trigger(kind, elapsed_seconds):
		return false
	_active_disasters.append(event)
	_refresh_environment_effects()
	_emit_disaster_changed()
	return true


func advance_disasters(delta: float) -> bool:
	if delta <= 0.0 or _run_session == null or not _run_session.is_run_active() or _run_session.is_paused():
		return false
	var changed: bool = false
	var had_active_events: bool = not _active_disasters.is_empty()
	var remaining_events: Array[RefCounted] = []
	for event: RefCounted in _active_disasters:
		if bool(event.call("advance", delta)):
			changed = true
		if bool(event.call("is_active")):
			remaining_events.append(event)
		else:
			changed = true
	_active_disasters = remaining_events
	_refresh_environment_effects()
	if changed or had_active_events:
		_emit_disaster_changed()
	return changed


func advance_disaster_countermeasure(kind: int, progress_delta: float, interrupted: bool = false) -> bool:
	if _run_session == null or not _run_session.is_run_active() or _run_session.is_paused():
		return false
	for event: RefCounted in _active_disasters:
		if not bool(event.call("is_active")) or int(event.call("get_kind")) != kind:
			continue
		if interrupted:
			var interruption_recorded: bool = bool(event.call("interrupt_countermeasure"))
			if interruption_recorded:
				_emit_disaster_changed()
			return interruption_recorded
		var progress_recorded: bool = bool(event.call("advance_countermeasure", progress_delta))
		if progress_recorded and not bool(event.call("is_active")):
			_active_disasters.erase(event)
		if progress_recorded:
			_emit_disaster_changed()
		return progress_recorded
	return false


func get_active_disaster_count() -> int:
	var count: int = 0
	for event: RefCounted in _active_disasters:
		if bool(event.call("is_active")):
			count += 1
	return count


func get_threat_budget_bonus_ratio() -> float:
	for event: RefCounted in _active_disasters:
		if int(event.call("get_kind")) == DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.MONSTER_SURGE \
			and int(event.call("get_phase")) == DISASTER_EVENT_MODEL_SCRIPT.Phase.ACTIVE:
			return 0.5
	return 0.0


func get_current_threat_budget() -> int:
	if _threat_budget == null:
		return 0
	_threat_budget.set_time_context(get_floor_day_index(), get_overtime_stage())
	_threat_budget.set_disaster_bonus_ratio(get_threat_budget_bonus_ratio())
	return int(_threat_budget.call("get_active_budget"))


func get_primary_disaster_kind() -> int:
	var event: RefCounted = _get_primary_disaster()
	return int(event.call("get_kind")) if event != null else -1


func get_primary_disaster_phase() -> int:
	var event: RefCounted = _get_primary_disaster()
	return int(event.call("get_phase")) if event != null else DISASTER_EVENT_MODEL_SCRIPT.Phase.IDLE


func get_primary_disaster_remaining_seconds() -> float:
	var event: RefCounted = _get_primary_disaster()
	return float(event.call("get_remaining_seconds")) if event != null else 0.0


func get_primary_disaster_countermeasure_progress() -> float:
	var event: RefCounted = _get_primary_disaster()
	return float(event.call("get_countermeasure_progress")) if event != null else 0.0


func get_disaster_kind_at(index: int) -> int:
	var event: RefCounted = _get_active_disaster_at(index)
	return int(event.call("get_kind")) if event != null else -1


func get_disaster_phase_at(index: int) -> int:
	var event: RefCounted = _get_active_disaster_at(index)
	return int(event.call("get_phase")) if event != null else DISASTER_EVENT_MODEL_SCRIPT.Phase.IDLE


func get_disaster_remaining_seconds_at(index: int) -> float:
	var event: RefCounted = _get_active_disaster_at(index)
	return float(event.call("get_remaining_seconds")) if event != null else 0.0


func get_disaster_countermeasure_progress_at(index: int) -> float:
	var event: RefCounted = _get_active_disaster_at(index)
	return float(event.call("get_countermeasure_progress")) if event != null else 0.0


func get_disaster_risk_level_at(index: int) -> int:
	var kind: int = get_disaster_kind_at(index)
	if kind < 0:
		return 0
	return 3 if kind >= DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.FLASH_FLOOD else 1


func configure_floor_disaster_kinds(kinds: Array[int]) -> bool:
	if kinds.is_empty():
		return false
	var normalized_kinds: Array[int] = []
	for kind: int in kinds:
		if kind < DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.RAINSTORM \
			or kind > DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.HUNTER:
			return false
		if not normalized_kinds.has(kind):
			normalized_kinds.append(kind)
	_allowed_disaster_kinds = normalized_kinds
	return true


func get_primary_disaster_risk_level() -> int:
	var kind: int = get_primary_disaster_kind()
	if kind < 0:
		return 0
	return 3 if kind >= DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.FLASH_FLOOD else 1


func _get_disaster_slot_limit() -> int:
	return SURVIVAL_TUNING_SCRIPT.disaster_slot_limit(_run_difficulty)


func _has_active_disaster_kind(kind: int) -> bool:
	for event: RefCounted in _active_disasters:
		if bool(event.call("is_active")) and int(event.call("get_kind")) == kind:
			return true
	return false


func _get_primary_disaster() -> RefCounted:
	for event: RefCounted in _active_disasters:
		if bool(event.call("is_active")):
			return event
	return null


func _get_active_disaster_at(index: int) -> RefCounted:
	if index < 0:
		return null
	var active_index: int = 0
	for event: RefCounted in _active_disasters:
		if not bool(event.call("is_active")):
			continue
		if active_index == index:
			return event
		active_index += 1
	return null


func _reset_allowed_disaster_kinds() -> void:
	_allowed_disaster_kinds.clear()
	for kind in range(
		DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.RAINSTORM,
		DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.HUNTER + 1
	):
		_allowed_disaster_kinds.append(kind)


func _emit_disaster_changed() -> void:
	disaster_changed.emit(
		get_primary_disaster_kind(),
		get_primary_disaster_phase(),
		get_primary_disaster_remaining_seconds(),
		get_primary_disaster_risk_level(),
		get_primary_disaster_countermeasure_progress()
	)


func add_run_xp(amount: int) -> bool:
	if _run_reward == null or amount <= 0:
		return false
	var scaled_amount: int = maxi(int(round(float(amount) * get_run_xp_multiplier())), 1)
	var leveled_up: bool = _run_reward.add_xp(scaled_amount)
	_emit_run_reward_changed()
	return leveled_up


func get_run_level() -> int:
	return _run_reward.get_level() if _run_reward != null else 1


func get_run_xp() -> int:
	return _run_reward.get_xp() if _run_reward != null else 0


func get_run_xp_to_next_level() -> int:
	return _run_reward.get_xp_to_next_level() if _run_reward != null else 100


func get_run_state() -> int:
	return _run_session.get_state() if _run_session != null else RUN_SESSION_MODEL_SCRIPT.State.IDLE


func get_floor_number() -> int:
	return _run_session.get_floor_number() if _run_session != null else 0


func get_total_floors() -> int:
	return _run_session.get_total_floors() if _run_session != null else RUN_SESSION_MODEL_SCRIPT.DEFAULT_TOTAL_FLOORS


func is_run_idle() -> bool:
	return get_run_state() == RUN_SESSION_MODEL_SCRIPT.State.IDLE


func is_preparing_floor() -> bool:
	return get_run_state() == RUN_SESSION_MODEL_SCRIPT.State.PREPARING_FLOOR


func is_objective_complete() -> bool:
	return get_run_state() == RUN_SESSION_MODEL_SCRIPT.State.OBJECTIVE_COMPLETE \
		or get_run_state() == RUN_SESSION_MODEL_SCRIPT.State.FLOOR_CLEAR


func is_run_dead() -> bool:
	return get_run_state() == RUN_SESSION_MODEL_SCRIPT.State.DEAD


func _reset_survival_models() -> void:
	_survival_vitals = SURVIVAL_VITALS_MODEL_SCRIPT.new()
	_survival_consumption = SURVIVAL_CONSUMPTION_MODEL_SCRIPT.new()
	_survival_clock = SURVIVAL_CLOCK_MODEL_SCRIPT.new()
	_disaster_scheduler = DISASTER_SCHEDULER_MODEL_SCRIPT.new(_run_difficulty)
	_threat_budget = THREAT_BUDGET_MODEL_SCRIPT.new()
	_night_fog = NIGHT_FOG_MODEL_SCRIPT.new()
	_moon_cycle = MOON_CYCLE_MODEL_SCRIPT.new()
	_darkness_mark = DARKNESS_MARK_MODEL_SCRIPT.new()
	_refresh_environment_effects()


func _reset_escape_objective() -> void:
	_resource_budget = RESOURCE_BUDGET_MODEL_SCRIPT.new(_run_difficulty)
	_escape_objective = ESCAPE_OBJECTIVE_MODEL_SCRIPT.new()


func _emit_survival_changed() -> void:
	survival_changed.emit(
		get_hunger(),
		get_water(),
		get_floor_elapsed_seconds(),
		get_floor_day_index(),
		is_floor_night(),
		get_overtime_stage(),
		get_disaster_probability()
	)


func _emit_escape_objective_changed() -> void:
	if _escape_objective == null:
		return
	escape_objective_changed.emit(
		_escape_objective.get_collected_amount(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MaterialType.PARTS),
		_escape_objective.get_collected_amount(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MaterialType.FUEL),
		_escape_objective.get_collected_amount(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MaterialType.CLOTH),
		_escape_objective.get_collected_amount(ESCAPE_OBJECTIVE_MODEL_SCRIPT.MaterialType.KEY),
		_escape_objective.get_exit_startup_seconds(),
		_escape_objective.is_exit_started()
	)


func _emit_run_state_changed() -> void:
	run_state_changed.emit(get_run_state(), get_floor_number())


func _emit_run_reward_changed() -> void:
	run_reward_changed.emit(get_run_level(), get_run_xp(), get_run_xp_to_next_level())


func _emit_run_build_changed() -> void:
	run_build_changed.emit(get_run_damage_multiplier(), get_run_move_speed_multiplier())


func _emit_boss_progress_changed() -> void:
	boss_progress_changed.emit(
		get_boss_phase(),
		get_boss_health(),
		get_boss_completion_route(),
		get_boss_collected_component_count(),
		get_boss_activated_device_count()
	)


func _can_advance_boss() -> bool:
	return _run_session != null \
		and _boss_progress != null \
		and _run_session.is_run_active() \
		and not _run_session.is_paused() \
		and _run_session.is_final_floor() \
		and _run_session.get_state() == RUN_SESSION_MODEL_SCRIPT.State.EXPLORING


func _create_run_snapshot() -> RefCounted:
	var snapshot: RefCounted = RUN_SNAPSHOT_DATA_SCRIPT.new()
	var run_session_state: Dictionary = _run_session.create_snapshot()
	var catalog: RefCounted = WORLD_SCENE_CATALOG_SCRIPT.new()
	var floor_number: int = int(run_session_state.get("floor_number", 0))
	var scene_id: StringName = _resume_scene_id
	var scene_path: String = _resume_scene_path
	var spawn_name: StringName = _resume_spawn_point_name
	if floor_number > 0:
		if scene_id.is_empty():
			scene_id = catalog.get_scene_id(floor_number)
		if scene_path.is_empty():
			scene_path = catalog.get_scene_path(floor_number)
		if spawn_name.is_empty():
			spawn_name = catalog.get_default_spawn_point(floor_number)
	run_session_state["scene_id"] = scene_id
	run_session_state["scene_path"] = scene_path
	run_session_state["spawn_point_name"] = spawn_name
	snapshot.set("run_session_state", run_session_state)
	snapshot.set("random_stream_state", _run_random_stream.create_snapshot())
	snapshot.set("survival_state", {
		"vitals": _survival_vitals.create_snapshot(),
		"consumption": _survival_consumption.create_snapshot(),
		"clock": _survival_clock.create_snapshot(),
		"scheduler": _disaster_scheduler.create_snapshot(),
		"threat_budget": _threat_budget.create_snapshot(),
		"night_fog": _night_fog.create_snapshot() if _night_fog != null else {},
		"moon_cycle": _moon_cycle.create_snapshot() if _moon_cycle != null else {},
		"darkness_mark": _darkness_mark.create_snapshot() if _darkness_mark != null else {},
		"environment_effects": _environment_effects.duplicate(true),
		"reward": _run_reward.create_snapshot(),
		"build": _run_build.create_snapshot(),
		"buff_draft": _run_buff_draft.create_snapshot() if _run_buff_draft != null else {},
		"reward_choice_used": _reward_choice_used,
	})
	snapshot.set("boss_state", _boss_progress.create_snapshot())
	snapshot.set("escape_state", _escape_objective.create_snapshot())
	var disaster_snapshots: Array[Dictionary] = []
	for event: RefCounted in _active_disasters:
		disaster_snapshots.append(event.create_snapshot())
	snapshot.set("disaster_state", {
		"events": disaster_snapshots,
		"allowed_kinds": _allowed_disaster_kinds.duplicate(),
	})
	var player_state: Dictionary = {}
	var enemy_entities: Array[Dictionary] = []
	var current_scene: Node = _runtime_scene if is_instance_valid(_runtime_scene) else null
	if current_scene != null:
		var player: Node = current_scene.get_node_or_null("Player")
		if player != null and player.has_method("create_snapshot"):
			player_state = player.call("create_snapshot")
		for entity: Node in _get_scene_group_nodes(current_scene, "enemy"):
			if entity.is_in_group("dynamic_enemy"):
				continue
			if entity.has_method("create_snapshot"):
				enemy_entities.append(entity.call("create_snapshot"))
	snapshot.set("player_state", player_state)
	snapshot.set("enemy_state", {"entities": enemy_entities})
	snapshot.set("inventory_state", Inventory.create_snapshot())
	snapshot.set("character_build_state", _character_build.create_snapshot() if _character_build != null else {})
	snapshot.set("building_state", _create_building_snapshot(current_scene))
	snapshot.set("interaction_state", _create_interaction_snapshot(current_scene))
	return snapshot


func get_runtime_snapshot() -> RefCounted:
	return _create_run_snapshot() if _run_session != null and _run_session.is_run_active() else null


func _restore_run_snapshot(snapshot: RefCounted) -> bool:
	if _run_session == null or not _run_session.get_state() == RUN_SESSION_MODEL_SCRIPT.State.IDLE:
		return false
	if snapshot == null or snapshot.get_script() != RUN_SNAPSHOT_DATA_SCRIPT:
		return false
	var restored_session: RefCounted = RUN_SESSION_MODEL_SCRIPT.new()
	var restored_random: RefCounted = RUN_RANDOM_STREAM_MODEL_SCRIPT.new()
	var restored_boss: RefCounted = BOSS_PROGRESS_MODEL_SCRIPT.new()
	if not bool(restored_session.call("restore_snapshot", snapshot.get("run_session_state"))):
		return false
	var restored_session_state: Dictionary = snapshot.get("run_session_state") as Dictionary
	var restored_floor_number: int = restored_session.get_floor_number()
	var restored_scene_id: StringName = StringName(restored_session_state.get("scene_id", ""))
	var restored_scene_path: String = String(restored_session_state.get("scene_path", ""))
	var restored_spawn_name: StringName = StringName(restored_session_state.get("spawn_point_name", ""))
	var has_scene_id: bool = restored_session_state.has("scene_id")
	var has_scene_path: bool = restored_session_state.has("scene_path")
	var has_spawn_name: bool = restored_session_state.has("spawn_point_name")
	var location_metadata_count: int = int(has_scene_id) + int(has_scene_path) + int(has_spawn_name)
	var catalog: RefCounted = WORLD_SCENE_CATALOG_SCRIPT.new()
	if location_metadata_count == 0 and restored_floor_number > 0:
		restored_scene_id = catalog.get_scene_id(restored_floor_number)
		restored_scene_path = catalog.get_scene_path(restored_floor_number)
		restored_spawn_name = catalog.get_default_spawn_point(restored_floor_number)
	elif location_metadata_count > 0 and location_metadata_count < 3:
		return false
	if restored_floor_number > 0 \
		and (not catalog.is_valid_location(restored_floor_number, restored_scene_id, restored_scene_path) \
		or not catalog.is_valid_spawn_point(restored_floor_number, restored_spawn_name)):
		return false
	if not bool(restored_random.call("restore_snapshot", snapshot.get("random_stream_state"))):
		return false
	if not bool(restored_boss.call("restore_snapshot", snapshot.get("boss_state"))):
		return false
	var restored_player_state: Dictionary = snapshot.get("player_state") as Dictionary
	var restored_enemy_state: Dictionary = snapshot.get("enemy_state") as Dictionary
	var restored_building_state: Dictionary = snapshot.get("building_state") as Dictionary
	var restored_interaction_state: Dictionary = snapshot.get("interaction_state") as Dictionary
	if restored_player_state == null or restored_enemy_state == null or restored_building_state == null or restored_interaction_state == null:
		return false
	if not _validate_entity_snapshot(restored_player_state, false) or not _validate_enemy_snapshot(restored_enemy_state):
		return false
	if not _validate_interaction_snapshot(restored_interaction_state):
		return false
	var survival_state: Dictionary = snapshot.get("survival_state") as Dictionary
	if survival_state == null:
		return false
	var restored_vitals: RefCounted = SURVIVAL_VITALS_MODEL_SCRIPT.new()
	var restored_consumption: RefCounted = SURVIVAL_CONSUMPTION_MODEL_SCRIPT.new()
	var restored_clock: RefCounted = SURVIVAL_CLOCK_MODEL_SCRIPT.new()
	var restored_scheduler: RefCounted = DISASTER_SCHEDULER_MODEL_SCRIPT.new(restored_session.get_difficulty())
	var restored_threat: RefCounted = THREAT_BUDGET_MODEL_SCRIPT.new()
	var restored_night_fog: RefCounted = NIGHT_FOG_MODEL_SCRIPT.new()
	var restored_moon_cycle: RefCounted = MOON_CYCLE_MODEL_SCRIPT.new()
	var restored_darkness_mark: RefCounted = DARKNESS_MARK_MODEL_SCRIPT.new()
	var restored_reward: RefCounted = RUN_REWARD_MODEL_SCRIPT.new()
	var restored_build: RefCounted = RUN_BUILD_MODEL_SCRIPT.new()
	var restored_buff_draft: RefCounted = RUN_BUFF_DRAFT_MODEL_SCRIPT.new()
	if not survival_state.has("vitals") or not restored_vitals.restore_snapshot(survival_state["vitals"]):
		return false
	var consumption_state: Dictionary = survival_state.get("consumption", {}) as Dictionary
	if consumption_state == null or not restored_consumption.restore_snapshot(consumption_state):
		return false
	if not survival_state.has("clock") or not restored_clock.restore_snapshot(survival_state["clock"]):
		return false
	if not survival_state.has("scheduler") or not restored_scheduler.restore_snapshot(survival_state["scheduler"]):
		return false
	if not survival_state.has("threat_budget") or not restored_threat.restore_snapshot(survival_state["threat_budget"]):
		return false
	if survival_state.has("night_fog") and not restored_night_fog.restore_snapshot(survival_state["night_fog"]):
		return false
	if survival_state.has("moon_cycle") and not restored_moon_cycle.restore_snapshot(survival_state["moon_cycle"]):
		return false
	if survival_state.has("darkness_mark") and not restored_darkness_mark.restore_snapshot(survival_state["darkness_mark"]):
		return false
	if survival_state.has("environment_effects") and not survival_state["environment_effects"] is Dictionary:
		return false
	if not survival_state.has("reward") or not restored_reward.restore_snapshot(survival_state["reward"]):
		return false
	if not survival_state.has("build") or not restored_build.restore_snapshot(survival_state["build"]):
		return false
	var buff_draft_state: Variant = survival_state.get("buff_draft", {})
	if buff_draft_state is Dictionary and not (buff_draft_state as Dictionary).is_empty() \
		and not restored_buff_draft.restore_snapshot(buff_draft_state):
		return false
	var restored_escape: RefCounted = ESCAPE_OBJECTIVE_MODEL_SCRIPT.new()
	if not bool(restored_escape.call("restore_snapshot", snapshot.get("escape_state"))):
		return false
	var inventory_state: Dictionary = snapshot.get("inventory_state") as Dictionary
	if inventory_state == null:
		return false
	var raw_character_build_state: Variant = snapshot.get("character_build_state")
	var character_build_state: Dictionary = raw_character_build_state as Dictionary if raw_character_build_state is Dictionary else {}
	if not character_build_state.is_empty():
		var restored_character_build: RefCounted = _create_character_build()
		if not restored_character_build.restore_snapshot(character_build_state, ITEM_CATALOG_SCRIPT.new()):
			return false
		_character_build = restored_character_build
	var inventory_validator: RefCounted = INVENTORY_MODEL_SCRIPT.new(8, ITEM_CATALOG_SCRIPT.new())
	if not inventory_validator.restore_snapshot(inventory_state):
		return false
	var disaster_state: Dictionary = snapshot.get("disaster_state") as Dictionary
	if disaster_state == null:
		return false
	var restored_allowed_disaster_kinds: Array[int] = []
	for raw_kind: Variant in disaster_state.get("allowed_kinds", []):
		var kind: int = int(raw_kind)
		if kind < DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.RAINSTORM or kind > DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.HUNTER:
			return false
		if not restored_allowed_disaster_kinds.has(kind):
			restored_allowed_disaster_kinds.append(kind)
	var restored_disasters: Array[RefCounted] = []
	for event_data: Variant in disaster_state.get("events", []):
		var event: RefCounted = DISASTER_EVENT_MODEL_SCRIPT.new()
		if not bool(event.call("restore_snapshot", event_data)):
			return false
		restored_disasters.append(event)
	if not _validate_building_snapshot(restored_building_state):
		return false
	_run_session = restored_session
	_run_random_stream = restored_random
	_boss_progress = restored_boss
	_run_difficulty = _run_session.get_difficulty()
	_survival_vitals = restored_vitals
	_survival_consumption = restored_consumption
	_survival_clock = restored_clock
	_disaster_scheduler = restored_scheduler
	_threat_budget = restored_threat
	_night_fog = restored_night_fog
	_moon_cycle = restored_moon_cycle
	_darkness_mark = restored_darkness_mark
	_run_reward = restored_reward
	_run_build = restored_build
	_run_buff_draft = restored_buff_draft
	_escape_objective = restored_escape
	_reward_choice_used = bool(survival_state.get("reward_choice_used", false))
	_active_disasters = restored_disasters
	_allowed_disaster_kinds = restored_allowed_disaster_kinds
	_refresh_environment_effects()
	if not Inventory.restore_snapshot(inventory_state):
		return false
	_pending_scene_state = {
		"floor_number": restored_floor_number,
		"scene_id": restored_scene_id,
		"scene_path": restored_scene_path,
		"spawn_point_name": restored_spawn_name,
		"run_session_state": {
			"floor_number": restored_floor_number,
			"scene_id": restored_scene_id,
			"scene_path": restored_scene_path,
			"spawn_point_name": restored_spawn_name,
		},
		"player_state": restored_player_state.duplicate(true),
		"enemy_state": restored_enemy_state.duplicate(true),
		"building_state": restored_building_state.duplicate(true),
		"interaction_state": restored_interaction_state.duplicate(true),
	}
	_collected_escape_material_ids.clear()
	for raw_id: Variant in restored_interaction_state.get("escape_material_ids", []):
		_collected_escape_material_ids.append(String(raw_id))
	_run_settlement_awarded = false
	_resume_scene_id = restored_scene_id
	_resume_scene_path = restored_scene_path
	_resume_spawn_point_name = restored_spawn_name
	if not restored_spawn_name.is_empty():
		spawn_point_name = String(restored_spawn_name)
	return true


func apply_pending_scene_state(scene: Node) -> bool:
	if _pending_scene_state.is_empty():
		return true
	if scene == null:
		return false
	var pending_session_state: Dictionary = _pending_scene_state.get("run_session_state", {}) as Dictionary
	var pending_floor_number: int = int(_pending_scene_state.get("floor_number", pending_session_state.get("floor_number", 0)))
	var pending_scene_id: StringName = StringName(_pending_scene_state.get("scene_id", pending_session_state.get("scene_id", "")))
	var pending_scene_path: String = String(_pending_scene_state.get("scene_path", pending_session_state.get("scene_path", "")))
	var pending_spawn_name: StringName = StringName(_pending_scene_state.get("spawn_point_name", pending_session_state.get("spawn_point_name", "")))
	var catalog: RefCounted = WORLD_SCENE_CATALOG_SCRIPT.new()
	if not catalog.is_valid_location(pending_floor_number, pending_scene_id, pending_scene_path) \
		or not catalog.is_valid_spawn_point(pending_floor_number, pending_spawn_name):
		return false
	if String(scene.scene_file_path) != pending_scene_path:
		return false
	var player_state: Dictionary = _pending_scene_state.get("player_state", {}) as Dictionary
	var player: Node = scene.get_node_or_null("Player")
	if not player_state.is_empty() and (player == null or not player.has_method("restore_snapshot")):
		return false
	var enemy_state: Dictionary = _pending_scene_state.get("enemy_state", {}) as Dictionary
	var enemy_by_id: Dictionary = {}
	for entity: Node in _get_scene_group_nodes(scene, "enemy"):
		enemy_by_id[entity.name] = entity
	var enemy_snapshots: Array = enemy_state.get("entities", []) as Array
	for raw_snapshot: Variant in enemy_snapshots:
		if not raw_snapshot is Dictionary or not enemy_by_id.has(String((raw_snapshot as Dictionary).get("entity_id", ""))):
			return false
	for raw_snapshot: Variant in enemy_snapshots:
		var entity_snapshot: Dictionary = raw_snapshot as Dictionary
		var entity: Node = enemy_by_id[String(entity_snapshot["entity_id"])]
		if not entity.has_method("restore_snapshot"):
			return false
	if not player_state.is_empty() and not bool(player.call("restore_snapshot", player_state)):
		return false
	for raw_snapshot: Variant in enemy_snapshots:
		var entity_snapshot: Dictionary = raw_snapshot as Dictionary
		var entity: Node = enemy_by_id[String(entity_snapshot["entity_id"])]
		if not bool(entity.call("restore_snapshot", entity_snapshot)):
			return false
	var interaction_state: Dictionary = _pending_scene_state.get("interaction_state", {}) as Dictionary
	var building_state: Dictionary = _pending_scene_state.get("building_state", {}) as Dictionary
	if not _apply_building_snapshot(scene, building_state):
		return false
	var collected_ids: Array = interaction_state.get("escape_material_ids", []) as Array
	for node: Node in _get_scene_group_nodes(scene, "snapshot_escape_material"):
		if collected_ids.has(node.name):
			node.queue_free()
	for node: Node in _get_scene_group_nodes(scene, "snapshot_suppression_component"):
		if (interaction_state.get("suppression_component_ids", []) as Array).has(node.name):
			node.visible = false
			node.set_process(false)
	for node: Node in _get_scene_group_nodes(scene, "snapshot_environment_device"):
		if (interaction_state.get("environment_device_ids", []) as Array).has(node.name):
			node.modulate = Color(0.35, 1.0, 0.65, 1.0)
	var resource_snapshots: Array = interaction_state.get("resource_nodes", []) as Array
	if interaction_state.has("resource_nodes"):
		var resource_by_id: Dictionary = {}
		for node: Node in _get_scene_group_nodes(scene, "persistent_resource"):
			var node_id: String = String(node.get("entity_id"))
			if node_id.is_empty() or resource_by_id.has(node_id):
				return false
			resource_by_id[node_id] = node
		for raw_snapshot: Variant in resource_snapshots:
			if not raw_snapshot is Dictionary:
				return false
			var resource_snapshot: Dictionary = raw_snapshot
			var resource_id: String = String(resource_snapshot.get("entity_id", ""))
			if resource_id.is_empty() or not resource_by_id.has(resource_id):
				return false
			var resource_node: Node = resource_by_id[resource_id]
			if not resource_node.has_method("restore_snapshot") or not resource_node.call("restore_snapshot", resource_snapshot):
				return false
	var campfire_snapshots: Array = interaction_state.get("campfires", []) as Array
	if interaction_state.has("campfires"):
		var campfire_by_id: Dictionary = {}
		for node: Node in _get_scene_group_nodes(scene, "snapshot_campfire"):
			var node_campfire_id: String = String(node.get("entity_id"))
			if node_campfire_id.is_empty() or campfire_by_id.has(node_campfire_id):
				return false
			campfire_by_id[node_campfire_id] = node
		for raw_snapshot: Variant in campfire_snapshots:
			if not raw_snapshot is Dictionary:
				return false
			var campfire_snapshot: Dictionary = raw_snapshot
			var snapshot_campfire_id: String = String(campfire_snapshot.get("entity_id", ""))
			if snapshot_campfire_id.is_empty() or not campfire_by_id.has(snapshot_campfire_id):
				return false
			var campfire: Node = campfire_by_id[snapshot_campfire_id]
			if not campfire.has_method("restore_snapshot") or not campfire.call("restore_snapshot", campfire_snapshot):
				return false
	var torch_snapshots: Array = interaction_state.get("torches", []) as Array
	if interaction_state.has("torches"):
		var torch_by_id: Dictionary = {}
		for node: Node in _get_scene_group_nodes(scene, "snapshot_torch"):
			var node_torch_id: String = String(node.get("entity_id"))
			if node_torch_id.is_empty() or torch_by_id.has(node_torch_id):
				return false
			torch_by_id[node_torch_id] = node
		for raw_snapshot: Variant in torch_snapshots:
			if not raw_snapshot is Dictionary:
				return false
			var torch_snapshot: Dictionary = raw_snapshot
			var snapshot_torch_id: String = String(torch_snapshot.get("entity_id", ""))
			if snapshot_torch_id.is_empty() or not torch_by_id.has(snapshot_torch_id):
				return false
			var torch: Node = torch_by_id[snapshot_torch_id]
			if not torch.has_method("restore_snapshot") or not torch.call("restore_snapshot", torch_snapshot):
				return false
	var dynamic_director_snapshots: Array = interaction_state.get("dynamic_spawn_directors", []) as Array
	if interaction_state.has("dynamic_spawn_directors"):
		var directors: Array[Node] = _get_scene_group_nodes(scene, "snapshot_dynamic_spawn_director")
		if directors.size() != dynamic_director_snapshots.size():
			return false
		for index: int in dynamic_director_snapshots.size():
			var director_snapshot: Variant = dynamic_director_snapshots[index]
			if not director_snapshot is Dictionary or not directors[index].has_method("restore_snapshot") \
				or not directors[index].call("restore_snapshot", director_snapshot):
				return false
	_pending_scene_state.clear()
	return true


func _validate_entity_snapshot(snapshot: Dictionary, require_entity_id: bool) -> bool:
	if snapshot.is_empty():
		return true
	if require_entity_id and String(snapshot.get("entity_id", "")).is_empty():
		return false
	return snapshot.has("position") and snapshot.has("health")


func _validate_enemy_snapshot(snapshot: Dictionary) -> bool:
	if snapshot.is_empty():
		return true
	if not snapshot.has("entities") or typeof(snapshot["entities"]) != TYPE_ARRAY:
		return false
	for raw_snapshot: Variant in snapshot["entities"]:
		if not raw_snapshot is Dictionary or not _validate_entity_snapshot(raw_snapshot as Dictionary, true):
			return false
	return true


func _validate_interaction_snapshot(snapshot: Dictionary) -> bool:
	if snapshot.is_empty():
		return true
	for key: String in ["escape_material_ids", "suppression_component_ids", "environment_device_ids", "campfires", "torches", "dynamic_spawn_directors"]:
		if snapshot.has(key) and typeof(snapshot[key]) != TYPE_ARRAY:
			return false
	if snapshot.has("resource_nodes"):
		if typeof(snapshot["resource_nodes"]) != TYPE_ARRAY:
			return false
		var seen_resource_ids: Dictionary = {}
		for raw_resource: Variant in snapshot["resource_nodes"]:
			if not raw_resource is Dictionary:
				return false
			var resource_snapshot: Dictionary = raw_resource
			var resource_id: String = String(resource_snapshot.get("entity_id", ""))
			if resource_id.is_empty() or seen_resource_ids.has(resource_id) \
				or not _is_integral_number(resource_snapshot.get("remaining_units")) \
				or resource_snapshot.get("depleted") is not bool:
				return false
			seen_resource_ids[resource_id] = true
	if snapshot.has("campfires"):
		var seen_campfire_ids: Dictionary = {}
		for raw_campfire: Variant in snapshot["campfires"]:
			if not raw_campfire is Dictionary:
				return false
			var campfire_snapshot: Dictionary = raw_campfire
			var campfire_id: String = String(campfire_snapshot.get("entity_id", ""))
			if campfire_id.is_empty() or seen_campfire_ids.has(campfire_id) \
				or not _is_integral_number(campfire_snapshot.get("format_version")) \
				or not _is_numeric_value(campfire_snapshot.get("fuel_seconds")) \
				or not _is_numeric_value(campfire_snapshot.get("stability")) \
				or campfire_snapshot.get("lit") is not bool:
				return false
			if float(campfire_snapshot.get("fuel_seconds")) < 0.0 or float(campfire_snapshot.get("stability")) < 0.0 \
				or float(campfire_snapshot.get("stability")) > 1.0:
				return false
			var processing_state: Variant = campfire_snapshot.get("processing_state", {})
			if not processing_state is Dictionary:
				return false
			if not (processing_state as Dictionary).is_empty():
				for processing_key: String in ["format_version", "cooking_state", "cooking_remaining", "cooking_slot", "purifying_state", "purifying_remaining", "purifying_slot"]:
					if not (processing_state as Dictionary).has(processing_key):
						return false
				if int((processing_state as Dictionary).get("format_version")) != 1 \
					or int((processing_state as Dictionary).get("cooking_state")) < 0 or int((processing_state as Dictionary).get("cooking_state")) > 3 \
					or int((processing_state as Dictionary).get("purifying_state")) < 0 or int((processing_state as Dictionary).get("purifying_state")) > 3 \
					or not _is_numeric_value((processing_state as Dictionary).get("cooking_remaining")) \
					or not _is_numeric_value((processing_state as Dictionary).get("purifying_remaining")):
					return false
			seen_campfire_ids[campfire_id] = true
	if snapshot.has("torches"):
		var seen_torch_ids: Dictionary = {}
		for raw_torch: Variant in snapshot["torches"]:
			if not raw_torch is Dictionary:
				return false
			var torch_snapshot: Dictionary = raw_torch
			var torch_id: String = String(torch_snapshot.get("entity_id", ""))
			var remaining: Variant = torch_snapshot.get("remaining_seconds")
			if torch_id.is_empty() or seen_torch_ids.has(torch_id) \
				or not _is_integral_number(torch_snapshot.get("format_version")) \
				or not _is_numeric_value(remaining) or torch_snapshot.get("lit") is not bool:
				return false
			if float(remaining) < 0.0 or (bool(torch_snapshot.get("lit")) and is_zero_approx(float(remaining))):
				return false
			seen_torch_ids[torch_id] = true
	if snapshot.has("dynamic_spawn_directors"):
		for raw_director: Variant in snapshot["dynamic_spawn_directors"]:
			if not raw_director is Dictionary:
				return false
			var director_snapshot: Dictionary = raw_director
			if int(director_snapshot.get("format_version", -1)) != 1 \
				or not director_snapshot.get("director_state", {}) is Dictionary \
				or not director_snapshot.get("entities", []) is Array:
				return false
			for raw_entity: Variant in director_snapshot.get("entities", []) as Array:
				if not raw_entity is Dictionary:
					return false
				var entity: Dictionary = raw_entity
				if String(entity.get("entity_id", "")).is_empty() or int(entity.get("threat_cost", 0)) < 1 \
					or not entity.get("state", {}) is Dictionary:
					return false
	return true


func _is_integral_number(value: Variant) -> bool:
	return (value is int) or (value is float and is_finite(value) and is_equal_approx(value, floor(value)))


func _is_numeric_value(value: Variant) -> bool:
	return value is int or value is float


func _validate_building_snapshot(snapshot: Dictionary) -> bool:
	if not snapshot.has("entities") or typeof(snapshot["entities"]) != TYPE_ARRAY:
		return false
	var seen_ids: Dictionary = {}
	for raw_entity: Variant in snapshot["entities"]:
		if not raw_entity is Dictionary:
			return false
		var entity: Dictionary = raw_entity
		var entity_id: String = String(entity.get("entity_id", ""))
		if entity_id.is_empty() or seen_ids.has(entity_id):
			return false
		var state: Dictionary = entity.get("state", {}) as Dictionary
		if state == null or not state.has("format_version") or not state.has("kind") or not state.has("position") or not state.has("health"):
			return false
		var position: Variant = state.get("position")
		var valid_position: bool = position is Vector2 or (position is Array and (position as Array).size() == 2 \
			and _is_numeric_value((position as Array)[0]) and _is_numeric_value((position as Array)[1]))
		if not valid_position or not _is_numeric_value(state.get("health")):
			return false
		seen_ids[entity_id] = true
	return true


func _create_building_snapshot(scene: Node) -> Dictionary:
	var entities: Array[Dictionary] = []
	if scene != null:
		for node: Node in _get_scene_group_nodes(scene, "snapshot_building"):
			if node.has_method("create_snapshot"):
				entities.append({"entity_id": String(node.get("entity_id")), "state": node.call("create_snapshot")})
	entities.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return String(left.get("entity_id", "")) < String(right.get("entity_id", "")))
	return {"entities": entities}


func _apply_building_snapshot(scene: Node, snapshot: Dictionary) -> bool:
	if snapshot.is_empty():
		return true
	var by_id: Dictionary = {}
	for node: Node in _get_scene_group_nodes(scene, "snapshot_building"):
		var entity_id: String = String(node.get("entity_id"))
		if entity_id.is_empty() or by_id.has(entity_id):
			return false
		by_id[entity_id] = node
	for raw_entity: Variant in snapshot.get("entities", []) as Array:
		var entity: Dictionary = raw_entity as Dictionary
		var entity_id: String = String(entity.get("entity_id", ""))
		if not by_id.has(entity_id):
			return false
		var node: Node = by_id[entity_id]
		if not node.has_method("restore_snapshot") or not node.call("restore_snapshot", entity.get("state", {})):
			return false
	return true


func _create_interaction_snapshot(scene: Node) -> Dictionary:
	var suppression_ids: Array[String] = []
	var device_ids: Array[String] = []
	var resource_snapshots: Array[Dictionary] = []
	var campfire_snapshots: Array[Dictionary] = []
	var torch_snapshots: Array[Dictionary] = []
	var dynamic_director_snapshots: Array[Dictionary] = []
	if scene != null:
		for node: Node in _get_scene_group_nodes(scene, "snapshot_suppression_component"):
			if not node.visible:
				suppression_ids.append(node.name)
		for node: Node in _get_scene_group_nodes(scene, "snapshot_environment_device"):
			if node.modulate.is_equal_approx(Color(0.35, 1.0, 0.65, 1.0)):
				device_ids.append(node.name)
		for node: Node in _get_scene_group_nodes(scene, "persistent_resource"):
			if node.has_method("create_snapshot"):
				resource_snapshots.append(node.call("create_snapshot"))
		for node: Node in _get_scene_group_nodes(scene, "snapshot_campfire"):
			if node.has_method("create_snapshot"):
				campfire_snapshots.append(node.call("create_snapshot"))
		for node: Node in _get_scene_group_nodes(scene, "snapshot_torch"):
			if node.has_method("create_snapshot"):
				torch_snapshots.append(node.call("create_snapshot"))
		for node: Node in _get_scene_group_nodes(scene, "snapshot_dynamic_spawn_director"):
			if node.has_method("create_snapshot"):
				dynamic_director_snapshots.append(node.call("create_snapshot"))
	resource_snapshots.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return String(left.get("entity_id", "")) < String(right.get("entity_id", "")))
	campfire_snapshots.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return String(left.get("entity_id", "")) < String(right.get("entity_id", "")))
	torch_snapshots.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return String(left.get("entity_id", "")) < String(right.get("entity_id", "")))
	return {
		"escape_material_ids": _collected_escape_material_ids.duplicate(),
		"suppression_component_ids": suppression_ids,
		"environment_device_ids": device_ids,
		"resource_nodes": resource_snapshots,
		"campfires": campfire_snapshots,
		"torches": torch_snapshots,
		"dynamic_spawn_directors": dynamic_director_snapshots,
	}


func _load_meta_progression() -> void:
	if not FileAccess.file_exists(META_SAVE_PATH):
		return
	var file := FileAccess.open(META_SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) == OK and parser.data is Dictionary:
		if _meta_progression == null:
			_meta_progression = META_PROGRESSION_MODEL_SCRIPT.new()
		_meta_progression.restore_snapshot(parser.data as Dictionary)
		_meta_crystals = _meta_progression.get_crystals()
	file.close()


func _save_meta_progression() -> void:
	var file := FileAccess.open(META_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	var snapshot: Dictionary = _meta_progression.create_snapshot() if _meta_progression != null else {"meta_crystals": _meta_crystals}
	snapshot["schema_version"] = 1
	file.store_string(JSON.stringify(snapshot))
	file.close()


func _apply_equipped_initial_buff() -> void:
	if _meta_progression == null or _run_build == null:
		return
	var buff_id: StringName = _meta_progression.get_equipped_initial_buff()
	var level: int = _meta_progression.get_initial_buff_level(buff_id)
	if buff_id.is_empty() or level <= 0:
		return
	var effect_type: int = UPGRADE_DEFINITION_SCRIPT.EffectType.DAMAGE_MULTIPLIER
	var amount: float = 0.1
	match buff_id:
		&"speed", &"move_speed":
			effect_type = UPGRADE_DEFINITION_SCRIPT.EffectType.MOVE_SPEED_MULTIPLIER
			amount = 0.06
		&"vitality":
			effect_type = UPGRADE_DEFINITION_SCRIPT.EffectType.MAX_STAMINA_MULTIPLIER
			amount = 0.10
		&"max_stamina":
			effect_type = UPGRADE_DEFINITION_SCRIPT.EffectType.MAX_STAMINA_MULTIPLIER
			amount = 0.15
		&"stamina_regen":
			effect_type = UPGRADE_DEFINITION_SCRIPT.EffectType.STAMINA_REGEN_MULTIPLIER
			amount = 0.20
		&"survival_efficiency":
			effect_type = UPGRADE_DEFINITION_SCRIPT.EffectType.SURVIVAL_CONSUMPTION_MULTIPLIER
			amount = 0.10
		&"luck":
			effect_type = UPGRADE_DEFINITION_SCRIPT.EffectType.LUCK
			amount = 0.10
	if _run_build.apply_effect(effect_type, amount, buff_id, level):
		for _index: int in range(level):
			_run_buff_draft.apply_candidate(buff_id, amount)


func _create_character_build() -> RefCounted:
	var total_points: int = CHARACTER_ATTRIBUTES_MODEL_SCRIPT.INITIAL_POINTS + get_meta_attribute_point_bonus()
	var attributes: RefCounted = CHARACTER_ATTRIBUTES_MODEL_SCRIPT.new(total_points)
	var equipment: RefCounted = EQUIPMENT_MODEL_SCRIPT.new(ITEM_CATALOG_SCRIPT.new())
	return CHARACTER_BUILD_MODEL_SCRIPT.new(attributes, equipment, self, null)


func _emit_meta_progression_changed() -> void:
	if _meta_progression == null:
		return
	meta_progression_changed.emit(
		_meta_progression.get_crystals(),
		_meta_progression.get_equipped_initial_buff(),
		_meta_progression.get_reroll_level()
	)


func _get_scene_group_nodes(scene: Node, group_name: StringName) -> Array[Node]:
	var nodes: Array[Node] = []
	if scene == null:
		return nodes
	for node: Node in get_tree().get_nodes_in_group(group_name):
		if scene.is_ancestor_of(node):
			nodes.append(node)
	return nodes


func _emit_all_runtime_state() -> void:
	_emit_run_state_changed()
	_emit_run_reward_changed()
	_emit_run_build_changed()
	_emit_survival_changed()
	_emit_escape_objective_changed()
	_emit_disaster_changed()
	_emit_boss_progress_changed()


## 当前是否可以传送（供 TransitionZone 检查）
func can_transition() -> bool:
	return _transition_cooldown <= 0.0
