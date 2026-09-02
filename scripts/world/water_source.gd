extends Area2D
class_name WaterSource

const WATER_CONTAINER_MODEL_SCRIPT: Script = preload("res://scripts/items/water_container_model.gd")
const INTERACTION_INPUT_ADAPTER_SCRIPT: Script = preload("res://scripts/presentation/interaction_input_adapter.gd")

@export var source_type: WaterContainerModel.Source = WaterContainerModel.Source.FLOWING
@export_range(0.0, 1.0, 0.01) var disease_chance: float = 0.20

var _player_nearby: bool = false
var _interaction_input: RefCounted


func _ready() -> void:
	_interaction_input = INTERACTION_INPUT_ADAPTER_SCRIPT.new()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _interaction_input != null and _interaction_input.is_interact_pressed() and _has_player_in_range():
		fill_selected_container()


func fill_container(container: RefCounted, amount: int = 1, purified: bool = false) -> bool:
	if container == null or not container.has_method("fill") or amount <= 0:
		return false
	return bool(container.fill(source_type, amount, purified))


func fill_selected_container(amount: int = 1) -> bool:
	if not is_instance_valid(GameManager):
		return false
	return GameManager.fill_selected_container_from_source(int(source_type), amount)


func get_disease_chance_for_difficulty(difficulty: int) -> float:
	var base: float = disease_chance
	match source_type:
		WATER_CONTAINER_MODEL_SCRIPT.Source.RAIN:
			base = 0.10
		WATER_CONTAINER_MODEL_SCRIPT.Source.FLOWING:
			base = 0.20
		WATER_CONTAINER_MODEL_SCRIPT.Source.PUDDLE:
			base = 0.35
	return clampf(base + 0.05 * float(clampi(difficulty, 0, 2)), 0.0, 1.0)


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
