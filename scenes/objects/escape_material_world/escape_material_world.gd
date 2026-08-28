extends Area2D
class_name EscapeMaterialWorld

## 独立于 Inventory 的地图逃生物资拾取点。

@export_enum("Parts", "Fuel", "Cloth", "Key") var material_type: int = 0

var _player_nearby: bool = false


func _ready() -> void:
	add_to_group("snapshot_escape_material")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and _has_player_in_range():
		_try_pickup()


func _has_player_in_range() -> bool:
	if _player_nearby:
		return true
	for body: Node2D in get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false


func _try_pickup() -> void:
	if GameManager.collect_escape_material(material_type):
		GameManager.record_escape_material_entity(name)
		queue_free()
