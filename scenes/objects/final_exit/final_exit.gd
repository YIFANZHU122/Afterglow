extends Area2D
class_name FinalExit


func interact() -> bool:
	return GameManager.complete_run()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		interact()
