extends RefCounted
class_name InventoryModel

## 物品栏运行时规则，不依赖 Autoload、UI 或场景节点。

var _slot_count: int
var _items: Array[ItemData] = []
var _selected_slot: int = 0


func _init(slot_count: int = 5) -> void:
	_slot_count = maxi(slot_count, 0)
	_items.resize(_slot_count)
	_items.fill(null)


func add_item(item: ItemData) -> bool:
	if item == null:
		return false
	for slot_index in range(_slot_count):
		if _items[slot_index] == null:
			_items[slot_index] = item
			return true
	return false


func get_selected_item() -> ItemData:
	if _slot_count == 0:
		return null
	return _items[_selected_slot]


func get_selected_slot() -> int:
	return _selected_slot


func set_selected_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= _slot_count:
		return false
	if _selected_slot == slot_index:
		return false
	_selected_slot = slot_index
	return true


func cycle_selected(delta: int) -> bool:
	if _slot_count == 0 or delta == 0:
		return false
	var normalized_delta: int = clampi(delta, -1, 1)
	return set_selected_slot((_selected_slot + normalized_delta + _slot_count) % _slot_count)


func get_items() -> Array[ItemData]:
	return _items.duplicate()


func drop_selected() -> ItemData:
	if _slot_count == 0:
		return null
	var item: ItemData = _items[_selected_slot]
	if item == null:
		return null
	_items[_selected_slot] = null
	return item


func drop_all() -> Array[ItemData]:
	var dropped: Array[ItemData] = []
	for item in _items:
		if item != null:
			dropped.append(item)
	_items.fill(null)
	return dropped


func create_snapshot() -> Dictionary:
	var item_data: Array[Dictionary] = []
	for item: ItemData in _items:
		item_data.append({
			"id": String(item.id) if item != null else "",
			"display_name": item.display_name if item != null else "",
			"item_type": int(item.item_type) if item != null else 0,
			"attack_damage": item.attack_damage if item != null else 0.0,
		})
	return {"slot_count": _slot_count, "selected_slot": _selected_slot, "items": item_data}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if not snapshot.has("slot_count") or not snapshot.has("selected_slot") or not snapshot.has("items"):
		return false
	var slot_count: int = int(snapshot["slot_count"])
	var selected_slot: int = int(snapshot["selected_slot"])
	var items: Array = snapshot["items"] as Array
	if slot_count < 0 or selected_slot < 0 or (slot_count > 0 and selected_slot >= slot_count) or items.size() != slot_count:
		return false
	_slot_count = slot_count
	_selected_slot = selected_slot if slot_count > 0 else 0
	_items.clear()
	_items.resize(_slot_count)
	_items.fill(null)
	for index in range(items.size()):
		if not items[index] is Dictionary:
			return false
		var data: Dictionary = items[index]
		var id: String = String(data.get("id", ""))
		if id.is_empty():
			continue
		var item := ItemData.new()
		item.id = StringName(id)
		item.display_name = String(data.get("display_name", ""))
		item.item_type = int(data.get("item_type", 0)) as ItemData.ItemType
		item.attack_damage = float(data.get("attack_damage", 0.0))
		_items[index] = item
	return true
