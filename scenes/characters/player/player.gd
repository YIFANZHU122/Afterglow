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
const REVIVE_MODEL_SCRIPT: Script = preload("res://scripts/progression/revive_model.gd")
const ITEM_DROP_SERVICE_SCRIPT: Script = preload("res://scripts/items/item_drop_service.gd")

var _stamina_model: StaminaModel
var _input_adapter: PlayerInputAdapter
var _melee_attack_model: MeleeAttackModel
var _revive_model: ReviveModel
var _item_drop_service: ItemDropService
# 当前朝向（用于攻击动画方向），默认朝下
var _facing_direction: Vector2 = Vector2.DOWN

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stamina_bar: ProgressBar = $HUD/StaminaBar
@onready var health: HealthComponent = $HealthComponent
@onready var health_bar: ProgressBar = $HUD/HealthBar
@onready var attack_area: AttackArea = $AttackArea
@onready var revive_button: Button = $HUD/ReviveButton
@onready var presenter: Variant = get_node_or_null("Presenter")

var _missing_presenter_warned: bool = false


func _ready() -> void:
	_stamina_model = STAMINA_MODEL_SCRIPT.new(max_stamina, stamina_drain_rate, stamina_regen_rate)
	_input_adapter = PLAYER_INPUT_ADAPTER_SCRIPT.new()
	_melee_attack_model = MELEE_ATTACK_MODEL_SCRIPT.new()
	_revive_model = REVIVE_MODEL_SCRIPT.new()
	_item_drop_service = ITEM_DROP_SERVICE_SCRIPT.new()
	stamina_bar.max_value = max_stamina
	stamina_changed.connect(_on_stamina_changed)
	_on_stamina_changed(_stamina_model.get_stamina(), _stamina_model.get_max_stamina())

	# 血量初始化
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_player_died)
	_on_health_changed(health.get_health(), health.max_health)

	# 复活按钮
	revive_button.pressed.connect(_on_revive_pressed)

func _physics_process(delta: float) -> void:
	if _revive_model.is_dead():
		return
	var command: PlayerCommand = _input_adapter.collect_command()
	_update_stamina(delta, command)
	_handle_movement(command.move_direction)
	_handle_inventory_input(command)
	_handle_attack_input(command)


func _update_stamina(delta: float, command: PlayerCommand) -> void:
	_stamina_model.tick(delta, command.move_direction, command.sprint_requested)
	stamina_changed.emit(_stamina_model.get_stamina(), _stamina_model.get_max_stamina())


func _handle_movement(direction: Vector2) -> void:
	velocity = direction * _get_current_speed()
	if direction != Vector2.ZERO:
		_facing_direction = direction
	_present_movement(direction)
	move_and_slide()


func _get_current_speed() -> float:
	return walk_speed * _stamina_model.get_speed_multiplier(run_speed_multiplier, exhausted_speed_multiplier) \
		* GameManager.get_run_move_speed_multiplier()


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


func _drop_selected_item() -> void:
	var item := Inventory.drop_selected()
	if item == null:
		return
	_item_drop_service.spawn_item(get_tree().current_scene, item, global_position)


## 攻击：鼠标左键 + 当前选中物品是剑 → 近战判定
func _handle_attack_input(command: PlayerCommand) -> void:
	if not command.attack_pressed:
		return
	var selected: ItemData = Inventory.get_selected_item()
	if selected == null:
		selected = default_weapon
	if not _melee_attack_model.can_attack(selected):
		return
	attack_area.start_attack(_melee_attack_model.get_damage(selected) * GameManager.get_run_damage_multiplier())
	_present_attack(_facing_direction)


func _on_health_changed(current: float, max_value: float) -> void:
	health_bar.value = current
	health_bar.max_value = max_value


## 玩家死亡：掉落所有物品 + 隐藏 + 显示复活按钮
func _on_player_died() -> void:
	if not _revive_model.mark_dead():
		return
	GameManager.mark_dead()
	# 掉落所有物品到当前位置
	var items := Inventory.drop_all()
	for item in items:
		_item_drop_service.spawn_item(get_tree().current_scene, item, global_position)
	# 隐藏 + 禁用碰撞
	sprite.visible = false
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
	sprite.visible = true
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
