extends Node

const RUN_SESSION_MODEL_SCRIPT: Script = preload("res://scripts/core/run_session_model.gd")
const RUN_REWARD_MODEL_SCRIPT: Script = preload("res://scripts/progression/run_reward_model.gd")
const RUN_BUILD_MODEL_SCRIPT: Script = preload("res://scripts/progression/run_build_model.gd")

## GameManager —— 全局游戏管理器（Autoload 单例）
## 职责：本局运行会话、场景切换、传送出生点记录、传送冷却防抖

signal run_state_changed(state: int, floor_number: int)
signal run_reward_changed(level: int, xp: int, xp_to_next_level: int)
signal run_build_changed(damage_multiplier: float, move_speed_multiplier: float)

# 传送后玩家应出现的出生点名称（由 TransitionZone 设置，由各场景读取）
var spawn_point_name: String = "PlayerSpawn"

# 传送冷却计时器（秒），防止传送后出生在传送区域内反复触发
var _transition_cooldown: float = 0.0
var _run_session: RefCounted
var _run_reward: RefCounted
var _run_build: RefCounted
var _reward_choice_used: bool = false

# 冷却时长
const COOLDOWN_TIME: float = 0.5


func _ready() -> void:
	_run_session = RUN_SESSION_MODEL_SCRIPT.new()
	_run_reward = RUN_REWARD_MODEL_SCRIPT.new()
	_run_build = RUN_BUILD_MODEL_SCRIPT.new()


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
	get_tree().change_scene_to_file(scene_path)


## 开始一局新的运行；仅空闲状态可调用。
func start_run() -> bool:
	if _run_session == null or not _run_session.start_run():
		return false
	_run_reward = RUN_REWARD_MODEL_SCRIPT.new()
	_run_build = RUN_BUILD_MODEL_SCRIPT.new()
	_reward_choice_used = false
	_emit_run_state_changed()
	_emit_run_reward_changed()
	_emit_run_build_changed()
	return true


## 完成本层准备并进入探索状态。
func prepare_floor() -> bool:
	if _run_session == null or not _run_session.prepare_floor():
		return false
	_emit_run_state_changed()
	return true


## 标记当前楼层目标完成。
func complete_objective() -> bool:
	if _run_session == null or not _run_session.complete_objective():
		return false
	_emit_run_state_changed()
	return true


## 标记当前楼层已清除。
func clear_floor() -> bool:
	if _run_session == null or not _run_session.clear_floor():
		return false
	_emit_run_state_changed()
	return true


func apply_run_upgrade(definition: Resource) -> bool:
	if _reward_choice_used or not is_objective_complete() or is_floor_clear() or _run_build == null:
		return false
	if not _run_build.apply_upgrade(definition):
		return false
	_reward_choice_used = true
	_emit_run_build_changed()
	return clear_floor()


func get_run_damage_multiplier() -> float:
	return _run_build.get_damage_multiplier() if _run_build != null else 1.0


func get_run_move_speed_multiplier() -> float:
	return _run_build.get_move_speed_multiplier() if _run_build != null else 1.0


func get_run_upgrade_stack(upgrade_id: StringName) -> int:
	return _run_build.get_upgrade_stack(upgrade_id) if _run_build != null else 0


func is_floor_clear() -> bool:
	return get_run_state() == RUN_SESSION_MODEL_SCRIPT.State.FLOOR_CLEAR


## 开始下一层并进入准备状态。
func start_next_floor() -> bool:
	if _run_session == null or not _run_session.start_next_floor():
		return false
	_reward_choice_used = false
	_emit_run_state_changed()
	return true


## 标记本局死亡。
func mark_dead() -> bool:
	if _run_session == null or not _run_session.mark_dead():
		return false
	_emit_run_state_changed()
	return true


func revive() -> bool:
	if _run_session == null or not _run_session.revive():
		return false
	_emit_run_state_changed()
	return true


## 结束本局，保留会话结果直到显式重置。
func end_run() -> bool:
	if _run_session == null or not _run_session.end_run():
		return false
	_emit_run_state_changed()
	return true


## 重置本局状态，为下一次开始做准备。
func reset_run() -> bool:
	if _run_session == null:
		return false
	var session_changed: bool = _run_session.reset()
	var reward_changed: bool = _run_reward.reset() if _run_reward != null else false
	var build_changed: bool = _run_build.reset() if _run_build != null else false
	_reward_choice_used = false
	if not session_changed and not reward_changed and not build_changed:
		return false
	_emit_run_state_changed()
	_emit_run_reward_changed()
	_emit_run_build_changed()
	return true


func add_run_xp(amount: int) -> bool:
	if _run_reward == null or amount <= 0:
		return false
	var leveled_up: bool = _run_reward.add_xp(amount)
	_emit_run_reward_changed()
	return leveled_up


func get_run_level() -> int:
	return _run_reward.get_level() if _run_reward != null else 1


func get_run_xp() -> int:
	return _run_reward.get_xp() if _run_reward != null else 0


func get_run_xp_to_next_level() -> int:
	return _run_reward.get_xp_to_next_level() if _run_reward != null else 100


func get_run_state() -> int:
	return _run_session.get_state() if _run_session != null else RUN_SESSION_MODEL_SCRIPT.State.IDLE


func get_floor_number() -> int:
	return _run_session.get_floor_number() if _run_session != null else 0


func is_run_idle() -> bool:
	return get_run_state() == RUN_SESSION_MODEL_SCRIPT.State.IDLE


func is_preparing_floor() -> bool:
	return get_run_state() == RUN_SESSION_MODEL_SCRIPT.State.PREPARING_FLOOR


func is_objective_complete() -> bool:
	return get_run_state() == RUN_SESSION_MODEL_SCRIPT.State.OBJECTIVE_COMPLETE \
		or get_run_state() == RUN_SESSION_MODEL_SCRIPT.State.FLOOR_CLEAR


func is_run_dead() -> bool:
	return get_run_state() == RUN_SESSION_MODEL_SCRIPT.State.DEAD


func _emit_run_state_changed() -> void:
	run_state_changed.emit(get_run_state(), get_floor_number())


func _emit_run_reward_changed() -> void:
	run_reward_changed.emit(get_run_level(), get_run_xp(), get_run_xp_to_next_level())


func _emit_run_build_changed() -> void:
	run_build_changed.emit(get_run_damage_multiplier(), get_run_move_speed_multiplier())


## 当前是否可以传送（供 TransitionZone 检查）
func can_transition() -> bool:
	return _transition_cooldown <= 0.0
