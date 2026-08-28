extends "res://scripts/presentation/actor_presenter.gd"
class_name RiftAnimalPresenter

@export var visual_path: NodePath = NodePath("../Visual")

var _visual: CanvasItem
var _sprite: Sprite2D
var _actor: Node2D
var _dead: bool = false
var _pulse_time: float = 0.0
var _facing: Vector2 = Vector2.DOWN


func _ready() -> void:
	_visual = get_node_or_null(visual_path) as CanvasItem
	_sprite = get_node_or_null("RiftSprite") as Sprite2D
	_actor = get_parent() as Node2D
	if _sprite == null:
		push_warning("[RiftAnimalPresenter] RiftSprite is missing; polygon fallback remains active")
	else:
		_sprite.visible = true
	if _visual != null:
		# 保留灰盒节点作为碰撞/回退锚点，但让裂口动物贴图成为主视觉。
		_visual.modulate = Color(1.0, 1.0, 1.0, 0.0) if _sprite != null else Color(0.55, 0.22, 0.3, 1.0)


func _process(delta: float) -> void:
	if _dead or _sprite == null:
		return
	_pulse_time += delta
	var pulse: float = 1.0 + sin(_pulse_time * 5.0) * 0.045
	_sprite.scale = Vector2.ONE * pulse


func set_movement(direction: Vector2) -> void:
	if _dead:
		return
	if direction != Vector2.ZERO:
		_facing = direction.normalized()
		if _actor != null:
			_actor.rotation = _facing.angle() + PI * 0.5


func play_attack(direction: Vector2) -> void:
	if _dead:
		return
	if direction != Vector2.ZERO:
		_facing = direction.normalized()
	if _actor != null:
		_actor.rotation = _facing.angle() + PI * 0.5
	_pulse_time = 0.0
	if _sprite != null:
		var tween: Tween = create_tween()
		tween.tween_property(_sprite, "scale", Vector2.ONE * 1.22, 0.08)
		tween.tween_property(_sprite, "scale", Vector2.ONE, 0.12)


func play_hit() -> void:
	if _dead or _sprite == null:
		return
	_sprite.modulate = Color(1.0, 0.3, 0.35, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.16)


func set_dead(dead: bool) -> void:
	_dead = dead
	if _sprite != null:
		_sprite.visible = not dead
	if _visual != null:
		_visual.visible = not dead
