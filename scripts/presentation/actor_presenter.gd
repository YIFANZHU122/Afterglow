extends Node
class_name ActorPresenter

## 表现层语义契约。没有具体美术时，调用方仍可安全发出这些事件。

func set_movement(_direction: Vector2) -> void:
	pass


func play_attack(_direction: Vector2) -> void:
	pass


func play_hit() -> void:
	pass


func set_dead(_dead: bool) -> void:
	pass
