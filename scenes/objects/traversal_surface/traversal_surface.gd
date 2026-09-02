extends Area2D

## 将局部地形上下文注入玩家；规则仍由玩家领域模型决定。

@export var vault_height_steps: int = 0
@export var terrain_kind: int = 0
@export var terrain_depth_steps: int = 0
@export var water_depth_steps: int = 0
@export var has_high_vault: bool = false


func _ready() -> void:
	var blocker: StaticBody2D = get_node_or_null("Blocker") as StaticBody2D
	if blocker != null:
		blocker.collision_layer = 2 if vault_height_steps > 0 else 0
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	_apply_context(body)


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("set_traversal_context"):
		body.call("set_traversal_context", 0, 0, 0, 0, false)


func _apply_context(body: Node2D) -> void:
	if body.has_method("set_traversal_context"):
		body.call("set_traversal_context", vault_height_steps, terrain_kind, terrain_depth_steps, water_depth_steps, has_high_vault)
