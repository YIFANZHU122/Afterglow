extends Area2D
class_name ItemWorld

## 世界中可拾取的完整物品栈。

const ITEM_STACK_MODEL_SCRIPT: Script = preload("res://scripts/items/item_stack_model.gd")

@export var item_data: ItemData

@onready var sprite: Sprite2D = $Sprite2D
@onready var quantity_label: Label = $Quantity

var _stack: RefCounted
var _player_nearby: bool = false


func set_stack(stack: RefCounted) -> void:
	_stack = stack
	if stack != null:
		item_data = stack.get_definition()


func get_stack() -> RefCounted:
	return _stack


func _ready() -> void:
	if _stack == null and item_data != null:
		_stack = ITEM_STACK_MODEL_SCRIPT.new()
		if not _stack.setup(item_data, 1):
			_stack = null
	_update_presentation()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _update_presentation() -> void:
	var definition: ItemData = _stack.get_definition() if _stack != null else item_data
	if definition != null and definition.icon != null:
		sprite.texture = definition.icon
	if quantity_label != null:
		var quantity: int = _stack.get_quantity() if _stack != null else 1
		quantity_label.text = str(quantity) if quantity > 1 else ""


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


func _try_pickup() -> bool:
	if _stack == null:
		return false
	var definition: ItemData = _stack.get_definition()
	var quantity: int = _stack.get_quantity()
	if definition == null or quantity <= 0 or not Inventory.can_add_quantity(definition, quantity):
		return false
	if not Inventory.add_quantity(definition, quantity):
		return false
	queue_free()
	return true
