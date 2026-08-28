extends StaticBody2D
class_name TrainingDummy

## 训练人偶：100 血，死亡后 1 秒刷新；每 5 秒检查角色是否在攻击距离内并发射子弹

@export var shoot_interval: float = 5.0
@export var shoot_range: float = 600.0
@export var bullet_scene: PackedScene

@onready var health: HealthComponent = $HealthComponent
@onready var health_bar: ProgressBar = $HealthBar
@onready var shoot_timer: Timer = $ShootTimer
@onready var respawn_timer: Timer = $RespawnTimer
@onready var presenter: Variant = get_node_or_null("Presenter")

var _missing_presenter_warned: bool = false


func _ready() -> void:
	health.health_changed.connect(_on_health_changed)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	shoot_timer.timeout.connect(_on_shoot_timeout)
	respawn_timer.timeout.connect(_on_respawn_timeout)
	_on_health_changed(health.get_health(), health.max_health)
	shoot_timer.start()


func _on_health_changed(current: float, max_value: float) -> void:
	health_bar.value = current
	health_bar.max_value = max_value


func _on_damaged(_amount: float) -> void:
	if presenter != null:
		presenter.play_hit()
	else:
		_warn_missing_presenter()


func _on_died() -> void:
	# 停止发射 + 禁用碰撞，1 秒后刷新；视觉隐藏由 Presenter 负责。
	health_bar.visible = false
	collision_layer = 0
	collision_mask = 0
	shoot_timer.stop()
	respawn_timer.start()
	if presenter != null:
		presenter.set_dead(true)
	else:
		_warn_missing_presenter()


func _on_respawn_timeout() -> void:
	health.reset()
	health_bar.visible = true
	collision_layer = 2
	collision_mask = 0
	shoot_timer.start()
	if presenter != null:
		presenter.set_dead(false)
	else:
		_warn_missing_presenter()


func _on_shoot_timeout() -> void:
	var player := _get_player()
	if player == null:
		return
	var player_health: HealthComponent = player.get_node_or_null("HealthComponent")
	if player_health != null and player_health.is_dead():
		return
	if global_position.distance_to(player.global_position) > shoot_range:
		return
	_shoot_at(player.global_position)


func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null


func _shoot_at(target: Vector2) -> void:
	if bullet_scene == null:
		return
	var shot_direction: Vector2 = (target - global_position).normalized()
	var bullet := bullet_scene.instantiate() as Area2D
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
	bullet.setup(shot_direction)
	if presenter != null:
		presenter.play_attack(shot_direction)
	else:
		_warn_missing_presenter()


func _warn_missing_presenter() -> void:
	if _missing_presenter_warned:
		return
	_missing_presenter_warned = true
	push_warning("[TrainingDummy] Presenter is missing; gameplay continues without presentation feedback")


func create_snapshot() -> Dictionary:
	return {
		"entity_id": name,
		"position": [global_position.x, global_position.y],
		"health": health.create_snapshot() if health != null else {},
		"shoot_time_left": shoot_timer.time_left if shoot_timer != null else 0.0,
		"respawn_time_left": respawn_timer.time_left if respawn_timer != null else 0.0,
		"visible": visible,
		"collision_layer": collision_layer,
		"collision_mask": collision_mask,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["entity_id", "position", "health", "shoot_time_left", "respawn_time_left", "visible", "collision_layer", "collision_mask"]:
		if not snapshot.has(key):
			return false
	var raw_position: Array = snapshot["position"] as Array
	if raw_position == null or raw_position.size() != 2:
		return false
	var position := Vector2(float(raw_position[0]), float(raw_position[1]))
	if not position.is_finite() or float(snapshot["shoot_time_left"]) < 0.0 or float(snapshot["respawn_time_left"]) < 0.0:
		return false
	if health == null or not health.restore_snapshot(snapshot["health"]):
		return false
	global_position = position
	visible = bool(snapshot["visible"])
	collision_layer = int(snapshot["collision_layer"])
	collision_mask = int(snapshot["collision_mask"])
	shoot_timer.stop()
	respawn_timer.stop()
	if float(snapshot["respawn_time_left"]) > 0.0:
		respawn_timer.start(float(snapshot["respawn_time_left"]))
	else:
		shoot_timer.start(maxf(float(snapshot["shoot_time_left"]), 0.01))
	if presenter != null:
		presenter.set_dead(health.is_dead())
	return true
