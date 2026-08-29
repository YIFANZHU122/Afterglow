extends "res://scripts/presentation/actor_presenter.gd"
class_name AnimationTreeActorPresenter

## 将 ActorPresenter 语义事件映射到玩家场景中持久化的 AnimationTree 状态图。

const IDLE_STATE: StringName = &"Idle"
const MOVE_STATE: StringName = &"Move"
const ATTACK_STATE: StringName = &"Attack"
const HIT_STATE: StringName = &"Hit"
const DEAD_STATE: StringName = &"Dead"

@export_node_path("AnimationTree") var animation_tree_path: NodePath = NodePath("AnimationTree")
@export_node_path("AnimatedSprite2D") var visual_path: NodePath = NodePath("AnimatedSprite2D")
@export var down_animation: StringName = &"down"
@export var left_animation: StringName = &"left"
@export var right_animation: StringName = &"right"
@export var up_animation: StringName = &"up"
@export_range(0.01, 10.0, 0.01) var attack_duration: float = 0.15
@export_range(0.01, 10.0, 0.01) var hit_duration: float = 0.12

var _animation_tree: AnimationTree
var _playback: AnimationNodeStateMachinePlayback
var _visual: AnimatedSprite2D
var _facing_direction: Vector2 = Vector2.DOWN
var _moving: bool = false
var _dead: bool = false
var _current_state: StringName
var _transient_state: StringName
var _transient_generation: int = 0


func _ready() -> void:
	_animation_tree = get_node_or_null(animation_tree_path) as AnimationTree
	_visual = get_node_or_null(visual_path) as AnimatedSprite2D
	if _animation_tree == null or _visual == null:
		push_warning("[AnimationTreeActorPresenter] animation nodes are missing")
		return
	_playback = _animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	if _playback == null:
		push_warning("[AnimationTreeActorPresenter] state-machine playback is missing")
		return
	_animation_tree.active = true
	# AnimationTree 的 RESET/Dead 轨道可能在首帧先写入显隐；初始化时明确恢复存活视觉。
	_dead = false
	_visual.visible = true
	_visual.modulate = Color.WHITE
	_apply_facing_animation()
	_start_state(IDLE_STATE, true)
	call_deferred("_ensure_alive_visual")


func _ensure_alive_visual() -> void:
	if not _dead and is_instance_valid(_visual):
		_visual.visible = true
		_visual.modulate = Color.WHITE


func set_movement(direction: Vector2) -> void:
	if _dead:
		return
	_moving = direction != Vector2.ZERO
	if _moving:
		_facing_direction = _cardinal_direction(direction)
		_apply_facing_animation()
	if _transient_state != &"":
		return
	_start_state(MOVE_STATE if _moving else IDLE_STATE)


func play_attack(direction: Vector2) -> void:
	if _dead or _transient_state == HIT_STATE:
		return
	if direction != Vector2.ZERO:
		_facing_direction = _cardinal_direction(direction)
		_apply_facing_animation()
	_play_transient(ATTACK_STATE, attack_duration)


func play_hit() -> void:
	if _dead:
		return
	_play_transient(HIT_STATE, hit_duration)


func set_dead(dead: bool) -> void:
	# 允许幂等恢复：外部状态恢复或动画轨道可能先隐藏精灵，不能因状态值未变而跳过显隐修复。
	if _dead == dead and not dead:
		if _visual != null:
			_visual.visible = true
			_visual.modulate = Color.WHITE
		_apply_facing_animation()
		_start_state(IDLE_STATE, true)
		return
	if _dead == dead:
		return
	_dead = dead
	_transient_generation += 1
	_transient_state = &""
	if _dead:
		_start_state(DEAD_STATE, true)
		if _visual != null:
			_visual.visible = false
		return
	_moving = false
	_apply_facing_animation()
	_start_state(IDLE_STATE, true)
	if _visual != null:
		_visual.visible = true


func _play_transient(state_name: StringName, duration: float) -> void:
	if _playback == null:
		return
	_transient_generation += 1
	var generation: int = _transient_generation
	_transient_state = state_name
	_start_state(state_name, true)
	await get_tree().create_timer(duration).timeout
	if generation != _transient_generation or _dead or not is_inside_tree():
		return
	_transient_state = &""
	_start_state(MOVE_STATE if _moving else IDLE_STATE, true)


func _start_state(state_name: StringName, restart: bool = false) -> void:
	if _playback == null or (not restart and _current_state == state_name):
		return
	_current_state = state_name
	_playback.travel(state_name)
	_animation_tree.advance(0.0)


func _apply_facing_animation() -> void:
	if _visual == null:
		return
	if _facing_direction == Vector2.LEFT:
		_visual.animation = left_animation
	elif _facing_direction == Vector2.RIGHT:
		_visual.animation = right_animation
	elif _facing_direction == Vector2.UP:
		_visual.animation = up_animation
	else:
		_visual.animation = down_animation


func _cardinal_direction(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP
