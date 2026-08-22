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

# 进入奔跑所需的最低体力比例（1/4），也是疲劳恢复的阈值
const RUN_STAMINA_RATIO: float = 0.25
const ITEM_WORLD_SCENE: PackedScene = preload("res://scenes/objects/item_world/item_world.tscn")

enum MoveState {
	WALKING,
	RUNNING,
	EXHAUSTED,
}

var _stamina: float = 0.0
var _move_state: MoveState = MoveState.WALKING
var _is_dead: bool = false
# 当前朝向（用于攻击动画方向），默认朝下
var _facing_direction: Vector2 = Vector2.DOWN

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stamina_bar: ProgressBar = $HUD/StaminaBar
@onready var health: HealthComponent = $HealthComponent
@onready var health_bar: ProgressBar = $HUD/HealthBar
@onready var attack_area: AttackArea = $AttackArea
@onready var revive_button: Button = $HUD/ReviveButton


func _ready() -> void:
	_stamina = max_stamina
	stamina_bar.max_value = max_stamina
	stamina_changed.connect(_on_stamina_changed)
	_on_stamina_changed(_stamina, max_stamina)

	# 血量初始化
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_player_died)
	_on_health_changed(health.get_health(), health.max_health)

	# 复活按钮
	revive_button.pressed.connect(_on_revive_pressed)

	# 初始朝下站立（定格在 down 动画中间帧）
	sprite.animation = &"down"
	sprite.frame = 1
	sprite.stop()


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_update_stamina(delta, direction)
	_handle_movement(direction)
	_handle_inventory_input()
	_handle_attack_input()


func _update_stamina(delta: float, direction: Vector2) -> void:
	var sprinting := Input.is_action_pressed("sprint")
	var is_moving := direction != Vector2.ZERO

	match _move_state:
		MoveState.WALKING:
			_stamina = minf(_stamina + stamina_regen_rate * delta, max_stamina)
			if sprinting and is_moving and _stamina >= max_stamina * RUN_STAMINA_RATIO:
				_set_state(MoveState.RUNNING)

		MoveState.RUNNING:
			_stamina = maxf(_stamina - stamina_drain_rate * delta, 0.0)
			if _stamina <= 0.0:
				_set_state(MoveState.EXHAUSTED)
			elif not sprinting or not is_moving:
				_set_state(MoveState.WALKING)

		MoveState.EXHAUSTED:
			_stamina = minf(_stamina + stamina_regen_rate * delta, max_stamina)
			if _stamina >= max_stamina * RUN_STAMINA_RATIO:
				_set_state(MoveState.WALKING)

	stamina_changed.emit(_stamina, max_stamina)


func _set_state(new_state: MoveState) -> void:
	_move_state = new_state


func _handle_movement(direction: Vector2) -> void:
	velocity = direction * _get_current_speed()
	_update_animation(direction)
	move_and_slide()


## 根据移动方向切换行走动画；停止时定格在当前方向的中间帧（站立姿势）
func _update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		sprite.stop()
		sprite.frame = 1
		return

	_facing_direction = direction

	var anim_name: StringName
	if absf(direction.x) > absf(direction.y):
		anim_name = &"right" if direction.x > 0.0 else &"left"
	else:
		anim_name = &"down" if direction.y > 0.0 else &"up"

	if sprite.animation != anim_name or not sprite.is_playing():
		sprite.play(anim_name)


func _get_current_speed() -> float:
	match _move_state:
		MoveState.RUNNING:
			return walk_speed * run_speed_multiplier
		MoveState.EXHAUSTED:
			return walk_speed * exhausted_speed_multiplier
		_:
			return walk_speed


func _on_stamina_changed(current: float, _max_value: float) -> void:
	stamina_bar.value = current


## 物品栏切换：滚轮 + 数字键 1~5 + Q 丢弃选中物品
func _handle_inventory_input() -> void:
	if Input.is_action_just_pressed("cycle_prev"):
		Inventory.cycle_selected(-1)
	if Input.is_action_just_pressed("cycle_next"):
		Inventory.cycle_selected(1)
	for i in range(Inventory.SLOT_COUNT):
		if Input.is_action_just_pressed("slot_%d" % (i + 1)):
			Inventory.set_selected_slot(i)
	if Input.is_action_just_pressed("drop"):
		_drop_selected_item()


func _drop_selected_item() -> void:
	var item := Inventory.drop_selected()
	if item == null:
		return
	_spawn_item_world(item, global_position)


## 在指定位置生成世界物品
func _spawn_item_world(item: ItemData, pos: Vector2) -> void:
	var item_world: ItemWorld = ITEM_WORLD_SCENE.instantiate() as ItemWorld
	item_world.item_data = item
	get_tree().current_scene.add_child(item_world)
	item_world.global_position = pos


## 攻击：鼠标左键 + 当前选中物品是剑 → 近战判定
func _handle_attack_input() -> void:
	if not Input.is_action_just_pressed("attack"):
		return
	var selected: ItemData = Inventory.get_selected_item()
	if selected == null:
		return
	if selected.item_type != ItemData.ItemType.SWORD:
		return
	attack_area.start_attack(selected.attack_damage)
	_play_attack_animation()


## 攻击动画：朝当前朝向轻微前冲 + 闪白（无攻击帧图时的视觉反馈）
func _play_attack_animation() -> void:
	# 闪白
	sprite.modulate = Color(2.0, 2.0, 2.0)
	var white_tween := create_tween()
	white_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

	# 朝朝向方向轻微前冲（挥砍位移感）
	var target_pos: Vector2 = global_position + _facing_direction.normalized() * 22.0
	var dash_tween := create_tween()
	dash_tween.tween_property(self, "global_position", target_pos, 0.12)


func _on_health_changed(current: float, max_value: float) -> void:
	health_bar.value = current
	health_bar.max_value = max_value


## 玩家死亡：掉落所有物品 + 隐藏 + 显示复活按钮
func _on_player_died() -> void:
	_is_dead = true
	# 掉落所有物品到当前位置
	var items := Inventory.drop_all()
	for item in items:
		_spawn_item_world(item, global_position)
	# 隐藏 + 禁用碰撞
	sprite.visible = false
	collision_layer = 0
	collision_mask = 0
	# 显示复活按钮
	revive_button.visible = true


func _on_revive_pressed() -> void:
	revive_button.disabled = true
	revive_button.text = "复活中... 5s"
	await get_tree().create_timer(5.0).timeout
	_revive()


func _revive() -> void:
	health.reset()
	_is_dead = false
	sprite.visible = true
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