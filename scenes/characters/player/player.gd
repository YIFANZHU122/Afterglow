extends CharacterBody2D

## 玩家角色控制器
## WASD 移动 + Shift 奔跑体力 + 血量 + 近战攻击 + 死亡复活 + 物品丢弃

## 体力值变化信号，供 UI 监听（current: 当前体力, max_value: 最大体力）
signal stamina_changed(current: float, max_value: float)

# 步行速度（像素/秒）
@export var walk_speed: float = 300.0
# 奔跑速度倍率
@export var run_speed_multiplier: float = 1.6
# 疲劳速度倍率（体力为 0 时）
@export var exhausted_speed_multiplier: float = 0.5

# 最大体力
@export var max_stamina: float = 100.0
# 奔跑体力消耗速率（每秒）
@export var stamina_drain_rate: float = 30.0
# 体力回复速率（每秒）
@export var stamina_regen_rate: float = 15.0

# 场景注入的基础武器，保证玩家进入演示关卡后即可战斗。
@export var default_weapon: ItemData

const STAMINA_MODEL_SCRIPT: Script = preload("res://scripts/player/stamina_model.gd")
const PLAYER_INPUT_ADAPTER_SCRIPT: Script = preload("res://scripts/player/player_input_adapter.gd")
const MELEE_ATTACK_MODEL_SCRIPT: Script = preload("res://scripts/combat/melee_attack_model.gd")
const RANGED_WEAPON_MODEL_SCRIPT: Script = preload("res://scripts/combat/ranged_weapon_model.gd")
const NOISE_EVENT_MODEL_SCRIPT: Script = preload("res://scripts/combat/noise_event_model.gd")
const REVIVE_MODEL_SCRIPT: Script = preload("res://scripts/progression/revive_model.gd")
const CHARACTER_BUILD_MODEL_SCRIPT: Script = preload("res://scripts/progression/character_build_model.gd")
const ITEM_DROP_SERVICE_SCRIPT: Script = preload("res://scripts/items/item_drop_service.gd")
const ITEM_CATALOG_SCRIPT: Script = preload("res://scripts/items/item_catalog.gd")
const BULLET_SCENE: PackedScene = preload("res://scenes/objects/bullet/bullet.tscn")
const VAULT_ACTION_MODEL_SCRIPT: Script = preload("res://scripts/player/vault_action_model.gd")
const DIGGING_MODEL_SCRIPT: Script = preload("res://scripts/world/digging_model.gd")
const WATER_TRAVERSAL_MODEL_SCRIPT: Script = preload("res://scripts/player/water_traversal_model.gd")
const STEP_TERRAIN_MODEL_SCRIPT: Script = preload("res://scripts/world/step_terrain_model.gd")

var _stamina_model: StaminaModel
var _input_adapter: PlayerInputAdapter
var _melee_attack_model: MeleeAttackModel
var _revive_model: ReviveModel
var _item_drop_service: ItemDropService
var _item_catalog: RefCounted
var _ranged_weapon: RefCounted
var _ranged_weapon_id: StringName = &""
var _reload_inventory_rounds: int = 0
var _reload_cancelled: bool = false
var _character_build: RefCounted
var _vault_action: RefCounted
var _digging: RefCounted
var _water_traversal: RefCounted
var _vault_height_steps: int = 0
var _has_high_vault: bool = false
var _terrain_kind: int = 1
var _terrain_depth_steps: int = 0
var _water_depth_steps: int = 0
# 当前朝向（用于攻击动画方向），默认朝下
var _facing_direction: Vector2 = Vector2.DOWN

@onready var stamina_bar: ProgressBar = $HUD/StaminaBar
@onready var health: HealthComponent = $HealthComponent
@onready var health_bar: ProgressBar = $HUD/HealthBar
@onready var attack_area: AttackArea = $AttackArea
@onready var camera: Camera2D = $Camera2D
@onready var revive_button: Button = $HUD/ReviveButton
@onready var survival_status: Label = $HUD/StatusStack/SurvivalStatus
@onready var buff_status: Label = $HUD/StatusStack/BuffStatus
@onready var build_status: Label = $HUD/StatusStack/BuildStatus
@onready var equipment_status: Label = $HUD/StatusStack/EquipmentStatus
@onready var equipment_bar: Node = $HUD/EquipmentBar
@onready var presenter: Variant = get_node_or_null("Presenter")

var _missing_presenter_warned: bool = false


func _ready() -> void:
	_configure_camera()
	_item_catalog = ITEM_CATALOG_SCRIPT.new()
	_character_build = GameManager.get_character_build_model()
	if _character_build == null:
		_character_build = CHARACTER_BUILD_MODEL_SCRIPT.new(null, null, GameManager, null)
	_character_build.refresh_weight(Inventory.get_total_weight())
	_update_build_status()
	_update_equipment_status()
	var effective_max_stamina: float = _character_build.get_max_stamina(max_stamina)
	var effective_regen_rate: float = stamina_regen_rate * _character_build.get_stamina_regen_multiplier()
	_stamina_model = STAMINA_MODEL_SCRIPT.new(effective_max_stamina, stamina_drain_rate, effective_regen_rate)
	_input_adapter = PLAYER_INPUT_ADAPTER_SCRIPT.new()
	_melee_attack_model = MELEE_ATTACK_MODEL_SCRIPT.new()
	_revive_model = REVIVE_MODEL_SCRIPT.new()
	_item_drop_service = ITEM_DROP_SERVICE_SCRIPT.new()
	_vault_action = VAULT_ACTION_MODEL_SCRIPT.new(0.8, 1.5)
	_digging = DIGGING_MODEL_SCRIPT.new(1.5, 3.0)
	_water_traversal = WATER_TRAVERSAL_MODEL_SCRIPT.new(effective_max_stamina, 2.0)
	if equipment_bar != null and equipment_bar.has_signal("unequip_requested"):
		equipment_bar.connect("unequip_requested", _on_unequip_requested)
	stamina_bar.max_value = effective_max_stamina
	stamina_changed.connect(_on_stamina_changed)
	_on_stamina_changed(_stamina_model.get_stamina(), _stamina_model.get_max_stamina())

	# 血量初始化
	health.apply_max_health_multiplier(GameManager.get_run_max_health_multiplier())
	health.set_damage_taken_multiplier(1.0 - GameManager.get_run_damage_reduction())
	health.health_changed.connect(_on_health_changed)
	health.damaged.connect(_on_player_damaged)
	health.died.connect(_on_player_died)
	_on_health_changed(health.get_health(), health.max_health)

	# 复活按钮
	revive_button.pressed.connect(_on_revive_pressed)
	GameManager.survival_changed.connect(_on_survival_changed)
	GameManager.run_build_changed.connect(_on_run_build_changed)
	_update_buff_status()
	GameManager.survival_environment_damage.connect(_on_survival_environment_damage)
	_on_survival_changed(
		GameManager.get_hunger(),
		GameManager.get_water(),
		GameManager.get_floor_elapsed_seconds(),
		GameManager.get_floor_day_index(),
		GameManager.is_floor_night(),
		GameManager.get_overtime_stage(),
		GameManager.get_disaster_probability()
	)


func _configure_camera() -> void:
	if camera == null:
		push_warning("[Player] Camera2D is missing; player movement will continue without a camera")
		return
	# Keep the player centered while the world controller clamps the view at map edges.
	camera.enabled = true
	camera.position_smoothing_enabled = false
	camera.drag_horizontal_enabled = false
	camera.drag_vertical_enabled = false
	camera.make_current()

func _physics_process(delta: float) -> void:
	if _revive_model.is_dead():
		return
	var command: PlayerCommand = _input_adapter.collect_command()
	_advance_traversal(delta, command)
	if _vault_action.get_state() != VAULT_ACTION_MODEL_SCRIPT.State.IDLE or _digging.get_state() != DIGGING_MODEL_SCRIPT.State.IDLE:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	GameManager.advance_character_equipment_interaction(delta, command.move_direction != Vector2.ZERO, false)
	_character_build.refresh_weight(Inventory.get_total_weight())
	_update_build_status()
	_update_equipment_status()
	_advance_ranged_weapon(delta, command.move_direction)
	_update_stamina(delta, command)
	_handle_movement(command.move_direction)
	_handle_inventory_input(command)
	_handle_attack_input(command)


func set_traversal_context(vault_height_steps: int, terrain_kind: int, terrain_depth_steps: int, water_depth_steps: int, has_high_vault: bool = false) -> void:
	_vault_height_steps = clampi(vault_height_steps, 0, 9)
	_terrain_kind = terrain_kind
	_terrain_depth_steps = clampi(terrain_depth_steps, 0, 3)
	_water_depth_steps = maxi(water_depth_steps, 0)
	_has_high_vault = has_high_vault


func _advance_traversal(delta: float, command: PlayerCommand) -> void:
	if command.vault_pressed and _vault_action.get_state() == VAULT_ACTION_MODEL_SCRIPT.State.IDLE:
		var ratio: float = _character_build.get_current_weight() / maxf(_character_build.get_max_carry_capacity(), 0.01)
		var cost: float = _vault_action.get_stamina_cost(_vault_height_steps, _has_high_vault)
		if _stamina_model.get_stamina() >= cost and _vault_action.try_start(_vault_height_steps, _has_high_vault, _stamina_model.get_stamina(), ratio):
			_stamina_model.try_spend(cost)
	if command.dig_pressed and _digging.get_state() == DIGGING_MODEL_SCRIPT.State.IDLE:
		var selected: ItemData = Inventory.get_selected_item()
		var selected_stack: RefCounted = Inventory.get_selected_stack()
		var durability: int = selected_stack.get_durability() if selected_stack != null else 0
		if selected != null and selected.id == &"shovel" and _stamina_model.get_stamina() >= 2.0 and _digging.try_start(_terrain_kind, _terrain_depth_steps, durability):
			_stamina_model.try_spend(2.0)
	if command.move_direction != Vector2.ZERO:
		_vault_action.cancel()
		_digging.cancel()
	if _vault_action.advance(delta):
		global_position += _facing_direction.normalized() * STEP_TERRAIN_MODEL_SCRIPT.steps_to_pixels(_vault_height_steps)
	if _digging.advance(delta):
		_terrain_depth_steps = maxi(_terrain_depth_steps - 1, 0)
		Inventory.damage_selected_durability(1)
		_emit_noise(NOISE_EVENT_MODEL_SCRIPT.Kind.BUILD, 0.45)
	if _water_depth_steps != _water_traversal.get_depth_steps():
		_water_traversal.start(_water_depth_steps)
	_water_traversal.tick(delta, command.move_direction != Vector2.ZERO)


func _update_stamina(delta: float, command: PlayerCommand) -> void:
	_stamina_model.tick_with_modifiers(
		delta,
		command.move_direction,
		command.sprint_requested and _character_build.can_run(),
		GameManager.get_survival_stamina_recovery_multiplier(),
		GameManager.get_survival_stamina_cost_multiplier() * _character_build.get_stamina_cost_multiplier()
	)
	stamina_changed.emit(_stamina_model.get_stamina(), _stamina_model.get_max_stamina())


func _handle_movement(direction: Vector2) -> void:
	velocity = direction * _get_current_speed()
	if direction != Vector2.ZERO:
		_facing_direction = direction
	_present_movement(direction)
	move_and_slide()


func _get_current_speed() -> float:
	return walk_speed * _stamina_model.get_speed_multiplier(run_speed_multiplier, exhausted_speed_multiplier) \
		* _character_build.get_move_speed_multiplier() \
		* GameManager.get_survival_move_speed_multiplier()


func _on_stamina_changed(current: float, _max_value: float) -> void:
	stamina_bar.value = current


## 物品栏切换：滚轮 + 数字键 1~5 + Q 丢弃选中物品
func _handle_inventory_input(command: PlayerCommand) -> void:
	if command.cycle_delta != 0:
		Inventory.cycle_selected(command.cycle_delta)
	if command.selected_slot != PlayerCommand.NO_SELECTED_SLOT:
		Inventory.set_selected_slot(command.selected_slot)
	if command.drop_pressed:
		_drop_selected_item()
	if command.use_pressed:
		GameManager.use_selected_item()


func _drop_selected_item() -> void:
	var stack: RefCounted = Inventory.drop_selected()
	if stack == null:
		return
	_item_drop_service.spawn_stack(get_tree().current_scene, stack, global_position)


## 攻击：鼠标左键 + 当前选中物品是剑 → 近战判定
func _handle_attack_input(command: PlayerCommand) -> void:
	if not command.attack_pressed:
		return
	var selected: ItemData = Inventory.get_selected_item()
	if selected == null:
		selected = default_weapon
	if selected != null and selected.item_type == ItemData.ItemType.FIREARM:
		_handle_firearm_attack(selected)
		return
	if not _melee_attack_model.can_attack(selected):
		return
	var melee_cost: float = _stamina_model.get_max_stamina() * 0.06 * GameManager.get_survival_stamina_cost_multiplier()
	if not _stamina_model.try_spend(melee_cost):
		return
	stamina_changed.emit(_stamina_model.get_stamina(), _stamina_model.get_max_stamina())
	attack_area.start_attack(_character_build.get_melee_damage(_melee_attack_model.get_damage(selected)))
	_present_attack(_facing_direction)
	_emit_noise(NOISE_EVENT_MODEL_SCRIPT.Kind.MELEE, 1.0)


func _handle_firearm_attack(item: ItemData) -> void:
	if not _ensure_ranged_weapon(item):
		return
	if _ranged_weapon.is_reloading():
		return
	if not _ranged_weapon.try_fire():
		_begin_ranged_reload(item)
		return
	var direction: Vector2 = (get_global_mouse_position() - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = _facing_direction
	_spawn_bullet(direction, item.ranged_damage * GameManager.get_run_damage_multiplier())
	_present_attack(direction)
	_emit_noise(NOISE_EVENT_MODEL_SCRIPT.Kind.FIREARM, item.noise_strength)


func _ensure_ranged_weapon(item: ItemData) -> bool:
	if item == null or item.item_type != ItemData.ItemType.FIREARM:
		return false
	if _ranged_weapon != null and _ranged_weapon_id == item.id:
		return true
	_ranged_weapon = RANGED_WEAPON_MODEL_SCRIPT.new(item.magazine_capacity, item.reload_seconds, item.fire_cooldown_seconds)
	if not _ranged_weapon.load_magazine(0):
		_ranged_weapon = null
		return false
	_ranged_weapon_id = item.id
	_reload_inventory_rounds = 0
	_reload_cancelled = false
	return true


func _begin_ranged_reload(item: ItemData) -> bool:
	if _ranged_weapon == null or item == null or item.ammo_item_id.is_empty():
		return false
	var ammo: ItemData = _item_catalog.get_item(item.ammo_item_id) if _item_catalog != null else null
	var available: int = _get_inventory_quantity(item.ammo_item_id)
	if ammo == null or available <= 0:
		return false
	if not _ranged_weapon.start_reload(available):
		return false
	_reload_inventory_rounds = available
	_reload_cancelled = false
	return true


func _advance_ranged_weapon(delta: float, move_direction: Vector2) -> void:
	if _ranged_weapon == null:
		return
	if _ranged_weapon.is_reloading() and move_direction != Vector2.ZERO:
		_ranged_weapon.interrupt_reload()
		_reload_cancelled = true
		_reload_inventory_rounds = 0
		return
	var was_reloading: bool = _ranged_weapon.is_reloading()
	_ranged_weapon.advance(delta)
	if was_reloading and not _ranged_weapon.is_reloading():
		if not _reload_cancelled:
			var consumed: int = maxi(_reload_inventory_rounds - _ranged_weapon.get_reserve_rounds(), 0)
			var item: ItemData = _item_catalog.get_item(_get_ranged_ammo_id()) if _item_catalog != null else null
			if item != null and consumed > 0:
				Inventory.remove_quantity(item, consumed)
		_reload_inventory_rounds = 0
		_reload_cancelled = false


func _get_ranged_ammo_id() -> StringName:
	var item: ItemData = _item_catalog.get_item(_ranged_weapon_id) if _item_catalog != null else null
	return item.ammo_item_id if item != null else &""


func _get_inventory_quantity(item_id: StringName) -> int:
	var total: int = 0
	for stack: RefCounted in Inventory.get_stacks():
		if stack != null and stack.get_definition() != null and stack.get_definition().id == item_id:
			total += stack.get_quantity()
	return total


func _spawn_bullet(direction: Vector2, damage: float) -> void:
	var bullet: Area2D = BULLET_SCENE.instantiate() as Area2D
	if bullet == null:
		return
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
	bullet.set("target_group", &"enemy")
	bullet.call("setup", direction, damage)


func _emit_noise(kind: int, strength: float) -> void:
	var manager: Node = get_node_or_null("/root/GameManager")
	if manager == null or not manager.has_method("emit_noise_event"):
		return
	var raining: bool = bool(manager.call("is_raining")) if manager.has_method("is_raining") else false
	manager.call("emit_noise_event", NOISE_EVENT_MODEL_SCRIPT.new(kind, global_position, strength, raining))


func _on_health_changed(current: float, max_value: float) -> void:
	health_bar.value = current
	health_bar.max_value = max_value


func _on_player_damaged(_amount: float) -> void:
	GameManager.cancel_character_equipment_interaction()
	if _ranged_weapon != null and _ranged_weapon.is_reloading():
		_ranged_weapon.interrupt_reload()
		_reload_cancelled = true
		_reload_inventory_rounds = 0
	_present_hit()


func _on_survival_environment_damage(damage_ratio: float) -> void:
	if damage_ratio <= 0.0 or health == null or health.is_dead():
		return
	health.take_damage(health.max_health * damage_ratio)


func _on_survival_changed(
	hunger: float,
	water: float,
	elapsed_seconds: float,
	day_index: int,
	is_night: bool,
	overtime_stage: int,
	disaster_probability: float
) -> void:
	if survival_status == null:
		return
	var phase_name: String = "夜晚" if is_night else "白天"
	var risk_name: String = _get_disaster_risk_name(disaster_probability)
	var overtime_text: String = "  超时 %d" % overtime_stage if overtime_stage > 0 else ""
	survival_status.text = "饥饿 %d  水分 %d\n第 %d 天  %s  %s%s" % [
		int(floor(hunger)),
		int(floor(water)),
		day_index,
		phase_name,
		risk_name,
		overtime_text,
	]
	survival_status.tooltip_text = "本图已停留 %d 秒；灾难概率不显示精确数值。" % int(floor(elapsed_seconds))


func _on_run_build_changed(_damage_multiplier: float, _move_speed_multiplier: float) -> void:
	_update_buff_status()


func _update_buff_status() -> void:
	if buff_status == null:
		return
	var parts: Array[String] = []
	for item: Dictionary in GameManager.get_run_buff_summary():
		parts.append("%s +%d" % [String(item.get("id", "")), int(item.get("stack", 0))])
	var summary := "、".join(parts) if not parts.is_empty() else "暂无"
	buff_status.text = "Buff  %s\n幸运 %.2f" % [summary, GameManager.get_run_luck()]


func _update_build_status() -> void:
	if build_status == null or _character_build == null:
		return
	var weight: float = _character_build.get_current_weight()
	var capacity: float = _character_build.get_max_carry_capacity()
	var ratio: float = weight / capacity if capacity > 0.0 else 0.0
	var run_text: String = "可奔跑" if _character_build.can_run() else "禁止奔跑"
	build_status.text = "负重 %.1f/%.1f（%.0f%%）  %s" % [weight, capacity, ratio * 100.0, run_text]


func _update_equipment_status() -> void:
	if equipment_status == null or _character_build == null:
		return
	var head: String = _get_equipment_name(0, "空")
	var chest: String = _get_equipment_name(1, "空")
	var legs: String = _get_equipment_name(2, "空")
	var backpack: String = _get_equipment_name(3, "无背包")
	var remaining: float = GameManager.get_character_equipment_interaction_remaining_seconds()
	var changing_text: String = "\n换装中 %.1fs" % remaining if remaining > 0.0 else ""
	equipment_status.text = "装备  头:%s  甲:%s\n裤:%s  包:%s%s" % [head, chest, legs, backpack, changing_text]
	if equipment_bar != null and equipment_bar.has_method("refresh"):
		equipment_bar.call(
		"refresh",
		PackedStringArray([head if head != "空" else "", chest if chest != "空" else "", legs if legs != "空" else "", backpack if backpack != "无背包" else ""]),
		remaining
	)


func _get_equipment_name(slot: int, empty_name: String) -> String:
	var item_id: StringName = _character_build.get_equipped_item_id(slot)
	if item_id.is_empty():
		return empty_name
	var item: ItemData = _item_catalog.get_item(item_id) if _item_catalog != null else null
	return item.display_name if item != null and not item.display_name.is_empty() else String(item_id)


func _on_unequip_requested(slot: int) -> void:
	GameManager.start_unequipping_character_slot(slot)


func _get_disaster_risk_name(disaster_probability: float) -> String:
	if disaster_probability >= 0.60:
		return "灾变临界"
	if disaster_probability >= 0.35:
		return "危险"
	if disaster_probability >= 0.15:
		return "警戒"
	return "平稳"


## 玩家死亡：掉落所有物品 + 隐藏 + 显示复活按钮
func _on_player_died() -> void:
	if not _revive_model.mark_dead():
		return
	GameManager.mark_dead()
	# 掉落所有物品到当前位置
	var stacks: Array = Inventory.drop_all()
	for stack: RefCounted in stacks:
		_item_drop_service.spawn_stack(get_tree().current_scene, stack, global_position)
	# 表现层处理死亡显示，玩法层只禁用碰撞。
	_present_dead(true)
	collision_layer = 0
	collision_mask = 0
	# 显示复活按钮
	revive_button.visible = true


func _on_revive_pressed() -> void:
	if not _revive_model.request():
		return
	revive_button.disabled = true
	revive_button.text = "复活中... 5s"
	await get_tree().create_timer(5.0).timeout
	_revive()


func _revive() -> void:
	if not _revive_model.complete():
		return
	GameManager.revive()
	health.reset()
	_present_dead(false)
	collision_layer = 1
	collision_mask = 3
	global_position = _get_spawn_point()
	revive_button.text = "复活"
	revive_button.disabled = false
	revive_button.visible = false


func _get_spawn_point() -> Vector2:
	var scene := get_tree().current_scene
	var spawn := scene.get_node_or_null("PlayerSpawn") if scene != null else null
	if spawn != null:
		return spawn.global_position
	return global_position


func _present_movement(direction: Vector2) -> void:
	if presenter == null:
		_warn_missing_presenter()
		return
	presenter.set_movement(direction)


func _present_attack(direction: Vector2) -> void:
	if presenter == null:
		_warn_missing_presenter()
		return
	presenter.play_attack(direction)


func _present_hit() -> void:
	if presenter == null:
		_warn_missing_presenter()
		return
	presenter.play_hit()


func _present_dead(dead: bool) -> void:
	if presenter == null:
		_warn_missing_presenter()
		return
	presenter.set_dead(dead)


func _warn_missing_presenter() -> void:
	if _missing_presenter_warned:
		return
	_missing_presenter_warned = true
	push_warning("[Player] Presenter is missing; gameplay continues without presentation feedback")


func create_snapshot() -> Dictionary:
	return {
		"entity_id": name,
		"position": [global_position.x, global_position.y],
		"velocity": [velocity.x, velocity.y],
		"facing_direction": [_facing_direction.x, _facing_direction.y],
		"stamina": _stamina_model.create_snapshot() if _stamina_model != null else {},
		"health": health.create_snapshot() if health != null else {},
		"revive": _revive_model.create_snapshot() if _revive_model != null else {},
		"character_build": _character_build.create_snapshot() if _character_build != null else {},
		"ranged_weapon_id": _ranged_weapon_id,
		"ranged_weapon": _ranged_weapon.create_snapshot() if _ranged_weapon != null else {},
		"traversal": {
			"vault": _vault_action.create_snapshot() if _vault_action != null else {},
			"digging": _digging.create_snapshot() if _digging != null else {},
			"water": _water_traversal.create_snapshot() if _water_traversal != null else {},
			"vault_height_steps": _vault_height_steps,
			"terrain_kind": _terrain_kind,
			"terrain_depth_steps": _terrain_depth_steps,
			"water_depth_steps": _water_depth_steps,
			"has_high_vault": _has_high_vault,
		},
		"collision_layer": collision_layer,
		"collision_mask": collision_mask,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["entity_id", "position", "velocity", "facing_direction", "stamina", "health", "revive", "collision_layer", "collision_mask"]:
		if not snapshot.has(key):
			return false
	var position: Vector2 = _decode_vector(snapshot["position"])
	var restored_velocity: Vector2 = _decode_vector(snapshot["velocity"])
	var facing: Vector2 = _decode_vector(snapshot["facing_direction"])
	if not position.is_finite() or not restored_velocity.is_finite() or not facing.is_finite():
		return false
	if _stamina_model == null or not _stamina_model.restore_snapshot(snapshot["stamina"]):
		return false
	if health == null or not health.restore_snapshot(snapshot["health"]):
		return false
	if _revive_model == null or not _revive_model.restore_snapshot(snapshot["revive"]):
		return false
	if snapshot.has("character_build") and not snapshot["character_build"].is_empty():
		if _character_build == null or not _character_build.restore_snapshot(snapshot["character_build"], _item_catalog):
			return false
	if snapshot.has("ranged_weapon_id") and snapshot.has("ranged_weapon"):
		var restored_weapon_id: StringName = StringName(snapshot["ranged_weapon_id"])
		var restored_weapon_snapshot: Dictionary = snapshot["ranged_weapon"] as Dictionary
		if not restored_weapon_id.is_empty() and not restored_weapon_snapshot.is_empty():
			var restored_item: ItemData = _item_catalog.get_item(restored_weapon_id) if _item_catalog != null else null
			if restored_item == null or restored_item.item_type != ItemData.ItemType.FIREARM:
				return false
			var restored_weapon: RefCounted = RANGED_WEAPON_MODEL_SCRIPT.new(restored_item.magazine_capacity, restored_item.reload_seconds, restored_item.fire_cooldown_seconds)
			if not restored_weapon.restore_snapshot(restored_weapon_snapshot):
				return false
			_ranged_weapon = restored_weapon
			_ranged_weapon_id = restored_weapon_id
		else:
			_ranged_weapon = null
			_ranged_weapon_id = &""
	if snapshot.has("traversal"):
		var traversal_state: Dictionary = snapshot["traversal"] as Dictionary
		if traversal_state == null:
			return false
		if traversal_state.has("vault") and not _vault_action.restore_snapshot(traversal_state["vault"]):
			return false
		if traversal_state.has("digging") and not _digging.restore_snapshot(traversal_state["digging"]):
			return false
		if traversal_state.has("water") and not _water_traversal.restore_snapshot(traversal_state["water"]):
			return false
		_vault_height_steps = clampi(int(traversal_state.get("vault_height_steps", 0)), 0, 9)
		_terrain_kind = int(traversal_state.get("terrain_kind", 0))
		_terrain_depth_steps = clampi(int(traversal_state.get("terrain_depth_steps", 0)), 0, 3)
		_water_depth_steps = maxi(int(traversal_state.get("water_depth_steps", 0)), 0)
		_has_high_vault = bool(traversal_state.get("has_high_vault", false))
	global_position = position
	velocity = restored_velocity
	_facing_direction = facing
	collision_layer = int(snapshot["collision_layer"])
	collision_mask = int(snapshot["collision_mask"])
	_present_dead(_revive_model.is_dead())
	return true


func _decode_vector(value: Variant) -> Vector2:
	if value is Array and (value as Array).size() == 2:
		return Vector2(float((value as Array)[0]), float((value as Array)[1]))
	return Vector2(INF, INF)
