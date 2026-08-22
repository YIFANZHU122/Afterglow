extends Node2D

## 地下室场景（1280×720）
## 场景加载时定位玩家出生点，并设置相机边界（由场景尺寸决定，而非硬编码在玩家场景中）

const WORLD_WIDTH: float = 1280.0
const WORLD_HEIGHT: float = 720.0
const WALL_THICKNESS: float = 40.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D


func _ready() -> void:
	var spawn_marker = get_node_or_null(GameManager.spawn_point_name)
	if spawn_marker:
		player.global_position = spawn_marker.global_position
	else:
		push_warning("[Basement] 出生点 '" + GameManager.spawn_point_name + "' 未找到！")

	_setup_camera_limits()


func _setup_camera_limits() -> void:
	camera.limit_left = int(WALL_THICKNESS)
	camera.limit_top = int(WALL_THICKNESS)
	camera.limit_right = int(WORLD_WIDTH - WALL_THICKNESS)
	camera.limit_bottom = int(WORLD_HEIGHT - WALL_THICKNESS)
