extends CharacterBody2D

## 最小追击型敌人：直线追踪玩家，接触时按冷却造成伤害。

@export var move_speed: float = 90.0
@export var contact_damage: float = 8.0
@export var attack_range: float = 72.0
@export var attack_cooldown: float = 1.0

@onready var health: HealthComponent = $HealthComponent
@onready var visual: Polygon2D = $Visual
@onready var health_bar: ProgressBar = $HealthBar
@onready var presenter: Variant = get_node_or_null("Presenter")

var _attack_cooldown_remaining: float = 0.0
var _defeated: bool = false
var _missing_presenter_warned: bool = false


func _ready() -> void:
	health.health_changed.connect(_on_health_changed)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_on_health_changed(health.get_health(), health.max_health)


func _physics_process(delta: float) -> void:
	if _defeated:
		return
	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)
	var player: Node2D = _get_player()
	if player == null:
		velocity = Vector2.ZERO
		return
	var offset: Vector2 = player.global_position - global_position
	if offset.length() > attack_range:
		velocity = offset.normalized() * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_try_attack(player)


func _try_attack(player: Node2D) -> void:
	if _attack_cooldown_remaining > 0.0:
		return
	var player_health: Node = player.get_node_or_null("HealthComponent")
	if player_health == null:
		return
	if bool(player_health.call("is_dead")):
		return
	player_health.call("take_damage", contact_damage)
	_attack_cooldown_remaining = attack_cooldown


func _get_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	return players[0] as Node2D if players.size() > 0 else null


func _on_health_changed(current: float, max_value: float) -> void:
	health_bar.value = current
	health_bar.max_value = max_value


func _on_damaged(_amount: float) -> void:
	if presenter != null:
		presenter.play_hit()
	else:
		_warn_missing_presenter()


func _on_died() -> void:
	if _defeated:
		return
	_defeated = true
	velocity = Vector2.ZERO
	visual.visible = false
	health_bar.visible = false
	collision_layer = 0
	collision_mask = 0
	if presenter != null:
		presenter.set_dead(true)
	else:
		_warn_missing_presenter()


func _warn_missing_presenter() -> void:
	if _missing_presenter_warned:
		return
	_missing_presenter_warned = true
	push_warning("[ChaserEnemy] Presenter is missing; gameplay continues without presentation feedback")
