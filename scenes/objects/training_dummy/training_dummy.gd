extends StaticBody2D
class_name TrainingDummy

## 训练人偶：100 血，死亡后 1 秒刷新；每 5 秒检查角色是否在攻击距离内并发射子弹

@export var shoot_interval: float = 5.0
@export var shoot_range: float = 600.0
@export var bullet_scene: PackedScene

@onready var health: HealthComponent = $HealthComponent
@onready var visual: Polygon2D = $Visual
@onready var health_bar: ProgressBar = $HealthBar
@onready var shoot_timer: Timer = $ShootTimer
@onready var respawn_timer: Timer = $RespawnTimer


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


## 被击打反馈：闪红 0.2 秒
func _on_damaged(_amount: float) -> void:
	visual.modulate = Color(1.8, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.2)


func _on_died() -> void:
	# 隐藏 + 停止发射 + 禁用碰撞，1 秒后刷新
	visual.visible = false
	health_bar.visible = false
	collision_layer = 0
	collision_mask = 0
	shoot_timer.stop()
	respawn_timer.start()


func _on_respawn_timeout() -> void:
	health.reset()
	visual.visible = true
	health_bar.visible = true
	collision_layer = 2
	collision_mask = 0
	shoot_timer.start()


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
	var bullet := bullet_scene.instantiate() as Area2D
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
	bullet.setup(target - global_position)
