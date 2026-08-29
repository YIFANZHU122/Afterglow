extends "res://scripts/presentation/actor_presenter.gd"
class_name GrayboxActorPresenter

@export var visual_path: NodePath
@export var directional_animation: bool = false
@export var idle_frame: int = 1

var _visual: CanvasItem
var _animated_sprite: AnimatedSprite2D
var _animation_tree: AnimationTree
var _animation_playback: AnimationNodeStateMachinePlayback
var _facing_name: StringName = &"Down"
var _dead: bool = false
var _transient_serial: int = 0
var _transient_active: bool = false


func _ready() -> void:
	_visual = get_node_or_null(visual_path) as CanvasItem
	if _visual == null:
		push_warning("[GrayboxActorPresenter] visual node is missing")
		return
	_animated_sprite = _visual as AnimatedSprite2D
	_animation_tree = get_node_or_null("AnimationTree") as AnimationTree
	if _animation_tree != null:
		_setup_animation_tree()
	if directional_animation:
		set_movement(Vector2.ZERO)


func set_movement(direction: Vector2) -> void:
	if _dead or _transient_active or not directional_animation or _animated_sprite == null:
		return
	_transient_serial += 1
	if direction == Vector2.ZERO:
		_animated_sprite.stop()
		_animated_sprite.frame = idle_frame
		_travel(&"Idle" + _facing_name)
		return
	var animation_name: StringName
	if absf(direction.x) > absf(direction.y):
		if direction.x > 0.0:
			animation_name = &"right"
			_facing_name = &"Right"
		else:
			animation_name = &"left"
			_facing_name = &"Left"
	else:
		if direction.y > 0.0:
			animation_name = &"down"
			_facing_name = &"Down"
		else:
			animation_name = &"up"
			_facing_name = &"Up"
	if _animated_sprite.animation != animation_name or not _animated_sprite.is_playing():
		_animated_sprite.play(animation_name)
	_travel(&"Move" + _facing_name)


func play_attack(direction: Vector2) -> void:
	if _dead or _visual == null:
		return
	_update_facing(direction)
	_play_transient(&"Attack", 0.15)
	_visual.modulate = Color(2.0, 2.0, 2.0)
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "modulate", Color.WHITE, 0.15)


func play_hit() -> void:
	if _dead or _visual == null:
		return
	_play_transient(&"Hit", 0.12)
	_visual.modulate = Color(1.8, 0.35, 0.3)
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "modulate", Color.WHITE, 0.12)


func set_dead(dead: bool) -> void:
	_dead = dead
	_transient_serial += 1
	_transient_active = false
	if _visual == null:
		return
	_visual.visible = not dead
	if dead:
		_travel(&"Dead")
	else:
		_travel(&"Idle" + _facing_name)


func _setup_animation_tree() -> void:
	var state_machine := AnimationNodeStateMachine.new()
	for state_name in [
		&"IdleDown", &"IdleLeft", &"IdleRight", &"IdleUp",
		&"MoveDown", &"MoveLeft", &"MoveRight", &"MoveUp",
		&"Attack", &"Hit", &"Dead",
	]:
		state_machine.add_node(state_name, AnimationNodeAnimation.new())
	_animation_tree.tree_root = state_machine
	_animation_tree.active = true
	_animation_playback = _animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	_travel(&"IdleDown")


func _travel(state_name: StringName) -> void:
	if _animation_playback != null:
		_animation_playback.start(state_name)
		if _animation_tree != null:
			_animation_tree.advance(0.0)


func _update_facing(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	if absf(direction.x) > absf(direction.y):
		_facing_name = &"Right" if direction.x > 0.0 else &"Left"
	else:
		_facing_name = &"Down" if direction.y > 0.0 else &"Up"


func _play_transient(state_name: StringName, duration: float) -> void:
	_transient_serial += 1
	var serial: int = _transient_serial
	_transient_active = true
	_travel(state_name)
	_restore_after_transient(serial, duration)


func _restore_after_transient(serial: int, duration: float) -> void:
	await get_tree().create_timer(duration).timeout
	if _dead or serial != _transient_serial:
		return
	_transient_active = false
	_travel(&"Idle" + _facing_name)
