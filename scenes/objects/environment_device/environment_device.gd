extends Area2D
class_name EnvironmentDevice

@export var device_index: int = 0


func activate() -> bool:
	var activated: bool = GameManager.activate_boss_device(device_index)
	if activated:
		modulate = Color(0.35, 1.0, 0.65, 1.0)
	return activated


func _ready() -> void:
	add_to_group("snapshot_environment_device")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and Input.is_action_pressed(&"interact"):
		activate()
