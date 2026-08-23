extends Node

## GameManager —— 全局游戏管理器（Autoload 单例）
## 职责：场景切换、传送出生点记录、传送冷却防抖

# 传送后玩家应出现的出生点名称（由 TransitionZone 设置，由各场景读取）
var spawn_point_name: String = "PlayerSpawn"

# 传送冷却计时器（秒），防止传送后出生在传送区域内反复触发
var _transition_cooldown: float = 0.0

# 冷却时长
const COOLDOWN_TIME: float = 0.5


func _process(delta: float) -> void:
	if _transition_cooldown > 0.0:
		_transition_cooldown -= delta


## 切换到目标场景，并设置出生点名称
func change_scene(scene_path: String, spawn_name: String = "PlayerSpawn") -> void:
	if _transition_cooldown > 0.0:
		return
	if scene_path.is_empty():
		push_warning("[GameManager] target_scene 路径为空，无法传送！")
		return
	_transition_cooldown = COOLDOWN_TIME
	spawn_point_name = spawn_name
	TimeManager.save_state()
	get_tree().change_scene_to_file(scene_path)


## 当前是否可以传送（供 TransitionZone 检查）
func can_transition() -> bool:
	return _transition_cooldown <= 0.0
