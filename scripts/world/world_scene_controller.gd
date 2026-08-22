extends Node2D
class_name WorldSceneController

## 世界场景组装器：负责出生点注入和相机边界，不实现关卡规则。

const WALL_THICKNESS: float = 40.0


func _ready() -> void:
	_place_player_at_spawn()
	_setup_camera_limits()


func _get_world_size() -> Vector2:
	return Vector2(1280.0, 720.0)


func _place_player_at_spawn() -> void:
	var player: CharacterBody2D = get_node_or_null("Player") as CharacterBody2D
	if player == null:
		push_warning("[%s] Player 节点未找到。" % name)
		return
	var spawn_marker: Marker2D = get_node_or_null(GameManager.spawn_point_name) as Marker2D
	if spawn_marker == null:
		push_warning("[%s] 出生点 '%s' 未找到！" % [name, GameManager.spawn_point_name])
		return
	player.global_position = spawn_marker.global_position


func _setup_camera_limits() -> void:
	var camera: Camera2D = get_node_or_null("Player/Camera2D") as Camera2D
	if camera == null:
		push_warning("[%s] Player/Camera2D 节点未找到。" % name)
		return
	var world_size: Vector2 = _get_world_size()
	camera.limit_left = int(WALL_THICKNESS)
	camera.limit_top = int(WALL_THICKNESS)
	camera.limit_right = int(world_size.x - WALL_THICKNESS)
	camera.limit_bottom = int(world_size.y - WALL_THICKNESS)
