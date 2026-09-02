extends Area2D
class_name GatherableResource

const GATHERABLE_RESOURCE_MODEL_SCRIPT: Script = preload("res://scripts/world/gatherable_resource_model.gd")
const INTERACTION_INPUT_ADAPTER_SCRIPT: Script = preload("res://scripts/presentation/interaction_input_adapter.gd")
const NOISE_EVENT_MODEL_SCRIPT: Script = preload("res://scripts/combat/noise_event_model.gd")

@export var entity_id: StringName = &""
@export var resource_definition: Resource

@onready var presenter: Polygon2D = $Presenter
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _model: RefCounted
var _player_nearby: bool = false
var _interaction_input: RefCounted


func _ready() -> void:
	add_to_group("persistent_resource")
	_interaction_input = INTERACTION_INPUT_ADAPTER_SCRIPT.new()
	var resolved_id: StringName = entity_id if not entity_id.is_empty() else StringName(resource_definition.get("id"))
	if entity_id.is_empty():
		entity_id = resolved_id
	_model = GATHERABLE_RESOURCE_MODEL_SCRIPT.new(resource_definition, GameManager.get_run_difficulty(), resolved_id)
	if resource_definition != null:
		presenter.color = resource_definition.get("display_color")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_refresh_depleted_state()


func _process(_delta: float) -> void:
	if _interaction_input != null and _interaction_input.is_interact_pressed() and _has_player_in_range():
		_try_gather()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = false


func _has_player_in_range() -> bool:
	if _player_nearby:
		return true
	for body: Node2D in get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false


func _try_gather() -> bool:
	if _model == null or _model.is_depleted() or resource_definition == null:
		return false
	var amount: int = mini(resource_definition.get("gather_amount"), _model.get_remaining_units())
	var item: ItemData = resource_definition.get("output_item") as ItemData
	if amount <= 0 or item == null or not Inventory.can_add_quantity(item, amount):
		return false
	var gathered: int = _model.gather_once()
	if gathered <= 0 or not Inventory.add_quantity(item, gathered):
		return false
	GameManager.emit_noise_event(NOISE_EVENT_MODEL_SCRIPT.new(NOISE_EVENT_MODEL_SCRIPT.Kind.GATHER, global_position))
	_refresh_depleted_state()
	return true


func create_snapshot() -> Dictionary:
	return _model.create_snapshot() if _model != null else {"entity_id": String(entity_id), "remaining_units": 0, "depleted": true}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if _model == null or not _model.restore_snapshot(snapshot):
		return false
	_refresh_depleted_state()
	return true


func _refresh_depleted_state() -> void:
	var depleted: bool = _model != null and _model.is_depleted()
	presenter.visible = not depleted
	collision_shape.disabled = depleted
