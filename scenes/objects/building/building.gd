extends StaticBody2D
class_name Building

const BUILDING_MODEL_SCRIPT: Script = preload("res://scripts/world/building_model.gd")

@export var entity_id: StringName = &""
@export var kind: BuildingModel.Kind = BuildingModel.Kind.WALL

@onready var visual: Polygon2D = $Visual
@onready var health_bar: ProgressBar = $HealthBar

var _model: RefCounted


func _ready() -> void:
	add_to_group("snapshot_building")
	_model = BUILDING_MODEL_SCRIPT.new(kind, global_position)
	_refresh_presentation()


func take_damage(amount: float) -> bool:
	var result: bool = _model.take_damage(amount)
	_refresh_presentation()
	return result


func is_rain_shelter() -> bool:
	return _model != null and _model.get_kind() == BUILDING_MODEL_SCRIPT.Kind.SHELTER


func is_destroyed() -> bool:
	return _model == null or _model.is_destroyed()


func get_health() -> float:
	return _model.get_health() if _model != null else 0.0


func create_snapshot() -> Dictionary:
	var snapshot: Dictionary = _model.create_snapshot() if _model != null else {}
	snapshot["entity_id"] = String(entity_id)
	if snapshot.get("position") is Vector2:
		var position: Vector2 = snapshot["position"]
		snapshot["position"] = [position.x, position.y]
	return snapshot


func restore_snapshot(snapshot: Dictionary) -> bool:
	if _model == null or String(snapshot.get("entity_id", "")) != String(entity_id):
		return false
	var normalized: Dictionary = snapshot.duplicate(true)
	if normalized.get("position") is Array and (normalized["position"] as Array).size() == 2:
		var encoded: Array = normalized["position"]
		normalized["position"] = Vector2(float(encoded[0]), float(encoded[1]))
	var result: bool = _model.restore_snapshot(normalized)
	if result:
		global_position = _model.get_position()
		_refresh_presentation()
	return result


func _refresh_presentation() -> void:
	if visual != null:
		visual.color = Color(0.2, 0.4, 0.25, 1.0) if is_rain_shelter() else Color(0.34, 0.22, 0.12, 1.0)
	if health_bar != null and _model != null:
		health_bar.max_value = 160.0 if is_rain_shelter() else 100.0
		health_bar.value = _model.get_health()
		health_bar.visible = not is_destroyed()
