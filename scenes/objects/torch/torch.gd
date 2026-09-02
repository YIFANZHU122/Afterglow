extends Area2D
class_name Torch

const TORCH_MODEL_SCRIPT: Script = preload("res://scripts/items/torch_model.gd")
const INTERACTION_INPUT_ADAPTER_SCRIPT: Script = preload("res://scripts/presentation/interaction_input_adapter.gd")
const NOISE_EVENT_MODEL_SCRIPT: Script = preload("res://scripts/combat/noise_event_model.gd")

@export var entity_id: StringName = &""
@export_range(0.0, 600.0, 1.0) var starting_burn_seconds: float = 90.0

@onready var visual: Polygon2D = $Visual
@onready var light: PointLight2D = $PointLight2D

var _model: RefCounted
var _interaction_input: RefCounted
var _player_nearby: bool = false


func _ready() -> void:
	add_to_group("snapshot_torch")
	_model = TORCH_MODEL_SCRIPT.new(starting_burn_seconds)
	_interaction_input = INTERACTION_INPUT_ADAPTER_SCRIPT.new()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_refresh_presentation()


func _process(_delta: float) -> void:
	if _interaction_input != null and _interaction_input.is_interact_pressed() and _has_player_in_range():
		ignite_with_lighter()


func ignite_with_lighter() -> bool:
	var result: bool = _model.ignite_with_lighter()
	if result:
		GameManager.emit_noise_event(NOISE_EVENT_MODEL_SCRIPT.new(NOISE_EVENT_MODEL_SCRIPT.Kind.BUILD, global_position, 0.5))
	_refresh_presentation()
	return result


func ignite_from_campfire() -> bool:
	var result: bool = _model.ignite_from_campfire()
	_refresh_presentation()
	return result


func extinguish() -> bool:
	var result: bool = _model.extinguish()
	_refresh_presentation()
	return result


func advance_burning(delta: float) -> bool:
	var result: bool = _model.advance(delta)
	_refresh_presentation()
	return result


func is_lit() -> bool:
	return _model != null and _model.is_lit()


func get_remaining_seconds() -> float:
	return _model.get_remaining_seconds() if _model != null else 0.0


func get_light_radius() -> float:
	return _model.get_light_radius() if _model != null else 0.0


func create_snapshot() -> Dictionary:
	var snapshot: Dictionary = _model.create_snapshot() if _model != null else {}
	snapshot["entity_id"] = String(entity_id)
	return snapshot


func restore_snapshot(snapshot: Dictionary) -> bool:
	if _model == null or String(snapshot.get("entity_id", "")) != String(entity_id):
		return false
	var result: bool = _model.restore_snapshot(snapshot)
	if result:
		_refresh_presentation()
	return result


func _refresh_presentation() -> void:
	var lit: bool = _model != null and _model.is_lit()
	if visual != null:
		visual.color = Color(1.0, 0.52, 0.12, 1.0) if lit else Color(0.35, 0.2, 0.1, 1.0)
	if light != null:
		light.enabled = lit


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = false


func _has_player_in_range() -> bool:
	if _player_nearby:
		return true
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player != null and global_position.distance_to(player.global_position) <= 96.0:
		return true
	for body: Node2D in get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false
