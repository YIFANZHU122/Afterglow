extends "res://scripts/presentation/actor_presenter.gd"
class_name GrayboxActorPresenter

@export var visual_path: NodePath
@export var directional_animation: bool = false
@export var idle_frame: int = 1

var _visual: CanvasItem
var _animated_sprite: AnimatedSprite2D


func _ready() -> void:
	_visual = get_node_or_null(visual_path) as CanvasItem
	if _visual == null:
		push_warning("[GrayboxActorPresenter] visual node is missing")
		return
	_animated_sprite = _visual as AnimatedSprite2D
	if directional_animation:
		set_movement(Vector2.ZERO)


func set_movement(direction: Vector2) -> void:
	if not directional_animation or _animated_sprite == null:
		return
	if direction == Vector2.ZERO:
		_animated_sprite.stop()
		_animated_sprite.frame = idle_frame
		return
	var animation_name: StringName
	if absf(direction.x) > absf(direction.y):
		animation_name = &"right" if direction.x > 0.0 else &"left"
	else:
		animation_name = &"down" if direction.y > 0.0 else &"up"
	if _animated_sprite.animation != animation_name or not _animated_sprite.is_playing():
		_animated_sprite.play(animation_name)


func play_attack(_direction: Vector2) -> void:
	if _visual == null:
		return
	_visual.modulate = Color(2.0, 2.0, 2.0)
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "modulate", Color.WHITE, 0.15)


func play_hit() -> void:
	if _visual == null:
		return
	_visual.modulate = Color(1.8, 0.35, 0.3)
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "modulate", Color.WHITE, 0.12)


func set_dead(dead: bool) -> void:
	if _visual != null:
		_visual.visible = not dead
