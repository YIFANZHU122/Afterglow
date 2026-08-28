extends Area2D
class_name SuppressionComponent

@export var component_index: int = 0


func collect() -> bool:
	var collected: bool = GameManager.collect_boss_component(component_index)
	if collected:
		visible = false
		set_process(false)
	return collected


func _ready() -> void:
	add_to_group("snapshot_suppression_component")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		collect()
