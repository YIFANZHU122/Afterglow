extends Area2D
class_name Campfire

const CAMPFIRE_MODEL_SCRIPT: Script = preload("res://scripts/world/campfire_model.gd")
const PROCESSING_STATION_MODEL_SCRIPT: Script = preload("res://scripts/items/processing_station_model.gd")
const WOOD_ITEM: ItemData = preload("res://assets/items/wood.tres")
const INTERACTION_INPUT_ADAPTER_SCRIPT: Script = preload("res://scripts/presentation/interaction_input_adapter.gd")
const NOISE_EVENT_MODEL_SCRIPT: Script = preload("res://scripts/combat/noise_event_model.gd")

@export var entity_id: StringName = &""
@export_range(0.0, 3600.0, 1.0) var starting_fuel_seconds: float = 0.0

@onready var visual: Polygon2D = $Visual
@onready var light: PointLight2D = $PointLight2D

var _model: RefCounted
var _processing: RefCounted
var _player_nearby: bool = false
var _interaction_input: RefCounted


func _ready() -> void:
	add_to_group("snapshot_campfire")
	_model = CAMPFIRE_MODEL_SCRIPT.new()
	_processing = PROCESSING_STATION_MODEL_SCRIPT.new()
	if starting_fuel_seconds > 0.0:
		_model.add_fuel(starting_fuel_seconds)
	_interaction_input = INTERACTION_INPUT_ADAPTER_SCRIPT.new()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_refresh_presentation()


func _process(_delta: float) -> void:
	if _processing != null and is_lit():
		_processing.advance(_delta, false, false, _has_player_in_range())
	if _interaction_input != null and _interaction_input.is_interact_pressed() and _has_player_in_range():
		_try_add_fuel()


func start_cooking() -> bool:
	if not is_lit() or not _has_player_in_range():
		return false
	return _processing.start_cooking(Inventory)


func start_purifying() -> bool:
	if not is_lit() or not _has_player_in_range():
		return false
	return _processing.start_purifying(Inventory)


func advance_processing(delta: float, moving: bool = false, took_damage: bool = false, workstation_valid: bool = true) -> bool:
	return _processing != null and _processing.advance(delta, moving, took_damage, workstation_valid)


func is_cooking_complete() -> bool:
	return _processing != null and _processing.is_cooking_complete()


func is_purifying_complete() -> bool:
	return _processing != null and _processing.is_purifying_complete()


func add_fuel_from_inventory(seconds_per_wood: float = 60.0) -> bool:
	if not is_finite(seconds_per_wood) or seconds_per_wood <= 0.0 or Inventory.get_selected_item() != WOOD_ITEM:
		return false
	if not Inventory.remove_quantity(WOOD_ITEM, 1):
		return false
	if not _model.add_fuel(seconds_per_wood):
		Inventory.add_item(WOOD_ITEM)
		return false
	GameManager.emit_noise_event(NOISE_EVENT_MODEL_SCRIPT.new(NOISE_EVENT_MODEL_SCRIPT.Kind.BUILD, global_position))
	_refresh_presentation()
	return true


func ignite_with_lighter() -> bool:
	var result: bool = _model.ignite(CAMPFIRE_MODEL_SCRIPT.IgnitionMethod.LIGHTER, 1.0)
	if result:
		GameManager.emit_noise_event(NOISE_EVENT_MODEL_SCRIPT.new(NOISE_EVENT_MODEL_SCRIPT.Kind.BUILD, global_position, 0.5))
	_refresh_presentation()
	return result


func ignite_with_stones(roll: float) -> bool:
	var result: bool = _model.ignite(CAMPFIRE_MODEL_SCRIPT.IgnitionMethod.STONE, roll)
	_refresh_presentation()
	return result


func extinguish() -> bool:
	var result: bool = _model.extinguish()
	_refresh_presentation()
	return result


func take_damage(amount: float) -> bool:
	var result: bool = _model.take_damage(amount)
	if result and _processing != null:
		_processing.advance(0.001, false, true, true)
	_refresh_presentation()
	return result


func advance_burning(delta: float, weather: CampfireModel.Weather = CampfireModel.Weather.CLEAR, sheltered: bool = false) -> bool:
	var result: bool = _model.advance(delta, weather, sheltered)
	_refresh_presentation()
	return result


func is_lit() -> bool:
	return _model != null and _model.is_lit()


func get_fuel_seconds() -> float:
	return _model.get_fuel_seconds() if _model != null else 0.0


func get_stability() -> float:
	return _model.get_stability() if _model != null else 0.0


func get_light_radius() -> float:
	return _model.get_light_radius() if _model != null else 0.0


func create_snapshot() -> Dictionary:
	var snapshot: Dictionary = _model.create_snapshot() if _model != null else {}
	snapshot["entity_id"] = String(entity_id)
	snapshot["processing_state"] = _processing.create_snapshot() if _processing != null else {}
	return snapshot


func restore_snapshot(snapshot: Dictionary) -> bool:
	if _model == null or String(snapshot.get("entity_id", "")) != String(entity_id):
		return false
	var result: bool = _model.restore_snapshot(snapshot)
	if result:
		var processing_state: Variant = snapshot.get("processing_state", {})
		if _processing != null and processing_state is Dictionary and not (processing_state as Dictionary).is_empty():
			if not _processing.restore_snapshot(processing_state, Inventory):
				return false
		_refresh_presentation()
	return result


func _try_add_fuel() -> bool:
	return add_fuel_from_inventory()


func _refresh_presentation() -> void:
	var lit: bool = _model != null and _model.is_lit()
	if visual != null:
		visual.color = Color(1.0, 0.38, 0.08, 1.0) if lit else Color(0.25, 0.18, 0.14, 1.0)
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
