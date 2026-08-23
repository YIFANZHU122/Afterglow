extends RefCounted
class_name ItemDropService

const ITEM_WORLD_SCENE: PackedScene = preload("res://scenes/objects/item_world/item_world.tscn")


func spawn_item(parent: Node, item: ItemData, position: Vector2) -> ItemWorld:
	if parent == null or item == null:
		return null
	var item_world: ItemWorld = ITEM_WORLD_SCENE.instantiate() as ItemWorld
	item_world.item_data = item
	parent.add_child(item_world)
	item_world.global_position = position
	return item_world
