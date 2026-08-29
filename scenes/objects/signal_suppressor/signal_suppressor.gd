extends Area2D
class_name SignalSuppressor

## 猎杀者灾难的唯一主应对设施；实际进度由 GameManager 的事件模型保存。

@export var disaster_kind: int = 9
var _player_nearby: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_process(true)


func _process(delta: float) -> void:
	if not _player_nearby or not Input.is_action_pressed(&"interact"):
		return
	interact(delta)


func interact(progress_delta: float) -> bool:
	return GameManager.advance_disaster_countermeasure(disaster_kind, progress_delta)


func interrupt() -> bool:
	return GameManager.advance_disaster_countermeasure(disaster_kind, 0.0, true)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		interrupt()
