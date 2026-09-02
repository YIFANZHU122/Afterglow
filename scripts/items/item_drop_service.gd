extends RefCounted
class_name ItemDropService

const ITEM_WORLD_SCENE: PackedScene = preload("res://scenes/objects/item_world/item_world.tscn")
const ITEM_STACK_MODEL_SCRIPT: Script = preload("res://scripts/items/item_stack_model.gd")


func spawn_stack(parent: Node, stack: RefCounted, position: Vector2) -> ItemWorld:
	if parent == null or stack == null or stack.get_definition() == null or stack.get_quantity() <= 0:
		return null
	var item_world: ItemWorld = ITEM_WORLD_SCENE.instantiate() as ItemWorld
	item_world.set_stack(stack)
	parent.add_child(item_world)
	item_world.global_position = position
	return item_world


func spawn_item(parent: Node, item: ItemData, position: Vector2) -> ItemWorld:
	if parent == null or item == null:
		return null
	var stack: RefCounted = ITEM_STACK_MODEL_SCRIPT.new()
	if not stack.setup(item, 1):
		return null
	return spawn_stack(parent, stack, position)
