extends Area2D

## 传送区域
## 玩家进入后切换到 target_scene，并在目标场景的 spawn_point_name 出生点出现

# 目标场景路径（res:// 开头）
@export var target_scene: String = ""

# 当本次离开后抵达最终层时使用的终局场景路径
@export var final_floor_scene: String = "res://scenes/world/final_core/final_core.tscn"

# 目标场景中的出生点节点名称
@export var spawn_point_name: String = "PlayerSpawn"

@export var requires_objective_complete: bool = false
@export var requires_escape_startup: bool = false

var _player: Node2D
var _player_nearby: bool = false
var _was_hit: bool = false
var _enemy_count: int = 0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_process(requires_escape_startup)


func _process(delta: float) -> void:
	if not requires_escape_startup or not _player_nearby or _player == null:
		return
	if not Input.is_action_pressed(&"interact"):
		return
	var player_moving: bool = _player.velocity.length_squared() > 0.01 if _player is CharacterBody2D else false
	GameManager.advance_escape_exit(delta, player_moving, _was_hit, _enemy_count > 0)
	_was_hit = false
	if GameManager.is_escape_exit_started():
		_try_transition(_player)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		_enemy_count += 1
		return
	if body.is_in_group("player"):
		_player = body as Node2D
		_player_nearby = _player != null
		var health: Node = body.get_node_or_null("HealthComponent")
		if health != null and health.has_signal("damaged") and not health.damaged.is_connected(_on_player_damaged):
			health.damaged.connect(_on_player_damaged)
	_try_transition(body)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("enemy"):
		_enemy_count = maxi(_enemy_count - 1, 0)
		return
	if body == _player:
		_player_nearby = false
		_player = null
		_was_hit = false


func _on_player_damaged(_amount: float) -> void:
	_was_hit = true


func _try_transition(body: Node) -> void:
	if not GameManager.can_transition():
		return
	if requires_objective_complete and not GameManager.is_floor_clear():
		return
	if requires_escape_startup and not GameManager.is_escape_exit_started():
		return
	if body.is_in_group("player"):
		var destination_scene: String = target_scene
		if requires_objective_complete:
			if requires_escape_startup:
				if not GameManager.depart_floor():
					return
			elif not GameManager.start_next_floor():
				return
			if GameManager.get_floor_number() == GameManager.get_total_floors() and not final_floor_scene.is_empty():
				destination_scene = final_floor_scene
		GameManager.change_scene(destination_scene, spawn_point_name)
