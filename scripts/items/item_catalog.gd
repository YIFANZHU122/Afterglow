extends RefCounted
class_name ItemCatalog

## Stable lookup for immutable item resources used by runtime restore.

const ITEM_DATA_SCRIPT: Script = preload("res://scripts/item_data.gd")
const ITEM_PATHS: PackedStringArray = [
	"res://assets/items/stone_sword.tres",
	"res://assets/items/wood.tres",
	"res://assets/items/stone.tres",
	"res://assets/items/wild_food.tres",
	"res://assets/items/scrap_parts.tres",
	"res://assets/items/small_food.tres",
	"res://assets/items/ration.tres",
	"res://assets/items/raw_meat.tres",
	"res://assets/items/cooked_meat.tres",
	"res://assets/items/empty_container.tres",
	"res://assets/items/medium_container.tres",
	"res://assets/items/large_container.tres",
	"res://assets/items/torch.tres",
	"res://assets/items/stone_knife.tres",
	"res://assets/items/simple_bandage.tres",
	"res://assets/items/temporary_container.tres",
	"res://assets/items/campfire_kit.tres",
	"res://assets/items/rain_shelter_kit.tres",
	"res://assets/items/wood_wall_kit.tres",
	"res://assets/items/handmade_pistol.tres",
	"res://assets/items/pistol_ammo.tres",
	"res://assets/items/crystal.tres",
	"res://assets/items/cloth_cap.tres",
	"res://assets/items/scrap_helmet.tres",
	"res://assets/items/canvas_jacket.tres",
	"res://assets/items/scrap_armor.tres",
	"res://assets/items/trail_pants.tres",
	"res://assets/items/reinforced_pants.tres",
	"res://assets/items/field_pack.tres",
	"res://assets/items/frame_pack.tres",
	"res://assets/items/shovel.tres",
]

var _items: Dictionary = {}
var _errors: PackedStringArray = PackedStringArray()


func _init(items: Array = []) -> void:
	if items.is_empty():
		for path: String in ITEM_PATHS:
			_register(load(path))
	else:
		for candidate: Variant in items:
			_register(candidate as Resource)


func get_item(item_id: StringName) -> ItemData:
	return _items.get(item_id, null) as ItemData


func get_all_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item: ItemData in _items.values():
		result.append(item)
	return result


func is_valid() -> bool:
	return _errors.is_empty()


func get_errors() -> PackedStringArray:
	return _errors.duplicate()


func _register(candidate: Resource) -> void:
	if candidate == null or candidate.get_script() != ITEM_DATA_SCRIPT:
		_errors.append("catalog contains a non-ItemData resource")
		return
	var item: ItemData = candidate as ItemData
	if item == null or not item.is_valid():
		_errors.append("catalog contains an invalid item")
		return
	if item.max_durability > 0 and item.max_stack != 1:
		_errors.append("durable items must not stack")
		return
	var seen_tags: Dictionary = {}
	for tag: String in item.tags:
		if tag.is_empty() or seen_tags.has(tag):
			_errors.append("item tags must be unique and non-empty")
			return
		seen_tags[tag] = true
	if _items.has(item.id):
		_errors.append("catalog contains duplicate item id: %s" % item.id)
		return
	_items[item.id] = item
