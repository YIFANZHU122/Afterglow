extends RefCounted
class_name InventoryModel

## 物品栏运行时规则，不依赖 Autoload、UI 或场景节点。

const FORMAT_VERSION: int = 2
const ITEM_STACK_MODEL_SCRIPT: Script = preload("res://scripts/items/item_stack_model.gd")
const WATER_CONTAINER_MODEL_SCRIPT: Script = preload("res://scripts/items/water_container_model.gd")

var _slot_count: int
var _catalog: RefCounted
var _stacks: Array[RefCounted] = []
var _selected_slot: int = 0


func _init(slot_count: int = 8, catalog: RefCounted = null) -> void:
	_slot_count = maxi(slot_count, 0)
	_catalog = catalog
	_stacks.resize(_slot_count)
	_stacks.fill(null)


func get_slot_count() -> int:
	return _slot_count


## 调整容量；缩容时若被移除槽位仍有物品则拒绝，保证不会静默丢失资源。
func configure_slot_count(slot_count: int) -> bool:
	if slot_count < 0:
		return false
	if slot_count == _slot_count:
		return true
	if slot_count < _slot_count:
		for index: int in range(slot_count, _slot_count):
			if _stacks[index] != null:
				return false
		_stacks.resize(slot_count)
	else:
		var previous_count := _slot_count
		_stacks.resize(slot_count)
		for index: int in range(previous_count, slot_count):
			_stacks[index] = null
	_slot_count = slot_count
	if _slot_count == 0:
		_selected_slot = 0
	else:
		_selected_slot = clampi(_selected_slot, 0, _slot_count - 1)
	return true


func add_item(item: ItemData) -> bool:
	return add_quantity(item, 1)


func can_add_quantity(item: ItemData, quantity: int) -> bool:
	if item == null or not item.is_valid() or quantity <= 0:
		return false
	var remaining: int = quantity
	for stack: RefCounted in _stacks:
		if _is_compatible(stack, item):
			remaining -= stack.get_available_capacity()
	for stack: RefCounted in _stacks:
		if stack == null:
			remaining -= item.max_stack
	return remaining <= 0


func add_quantity(item: ItemData, quantity: int) -> bool:
	if not can_add_quantity(item, quantity):
		return false
	var remaining: int = quantity
	for stack: RefCounted in _stacks:
		if remaining <= 0:
			break
		if _is_compatible(stack, item):
			var accepted: int = mini(remaining, stack.get_available_capacity())
			if accepted > 0:
				stack.add_quantity(accepted)
				remaining -= accepted
	for index: int in _stacks.size():
		if remaining <= 0:
			break
		if _stacks[index] == null:
			var stack: RefCounted = ITEM_STACK_MODEL_SCRIPT.new()
			var accepted: int = mini(remaining, item.max_stack)
			var initial_durability: int = item.max_durability if item.max_durability > 0 else -1
			if not stack.setup(item, accepted, initial_durability):
				return false
			_stacks[index] = stack
			remaining -= accepted
	return remaining == 0


func damage_selected_durability(amount: int = 1) -> bool:
	if _slot_count == 0 or _stacks[_selected_slot] == null:
		return false
	var stack: RefCounted = _stacks[_selected_slot]
	if not stack.damage_durability(amount):
		return false
	if stack.get_durability() == 0:
		_stacks[_selected_slot] = null
	return true


func can_craft(recipe: Resource) -> bool:
	if recipe == null or not recipe.has_method("is_valid") or not recipe.is_valid():
		return false
	for raw: Resource in recipe.ingredients:
		var ingredient: Resource = raw
		if ingredient == null or not _has_quantity(ingredient.item, ingredient.quantity):
			return false
	return true


func remove_quantity(item: ItemData, quantity: int) -> bool:
	if item == null or quantity <= 0 or not _has_quantity(item, quantity):
		return false
	var remaining: int = quantity
	for stack: RefCounted in _stacks:
		if remaining <= 0:
			break
		if not _is_compatible(stack, item):
			continue
		var removed: int = mini(remaining, stack.get_quantity())
		stack.remove_quantity(removed)
		remaining -= removed
	for index: int in range(_stacks.size() - 1, -1, -1):
		if _stacks[index] != null and _stacks[index].get_quantity() == 0:
			_stacks[index] = null
	return remaining == 0


func get_selected_item() -> ItemData:
	if _slot_count == 0 or _stacks[_selected_slot] == null:
		return null
	return _stacks[_selected_slot].get_definition()


func get_selected_stack() -> RefCounted:
	if _slot_count == 0 or _stacks[_selected_slot] == null:
		return null
	return _stacks[_selected_slot].duplicate_stack()


func get_stack_at(slot_index: int) -> RefCounted:
	if slot_index < 0 or slot_index >= _slot_count or _stacks[slot_index] == null:
		return null
	return _stacks[slot_index].duplicate_stack()


func get_selected_container_snapshot() -> Dictionary:
	if _slot_count == 0 or _stacks[_selected_slot] == null:
		return {}
	return _stacks[_selected_slot].get_container_snapshot()


func get_container_snapshot_at(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= _slot_count or _stacks[slot_index] == null:
		return {}
	return _stacks[slot_index].get_container_snapshot()


func fill_selected_container(source: int, amount: int = 1, purified: bool = false) -> bool:
	if _slot_count == 0 or _stacks[_selected_slot] == null or amount <= 0:
		return false
	return _stacks[_selected_slot].fill_container(source, amount, purified)


func consume_selected_water(amount: int = 1) -> bool:
	if _slot_count == 0 or _stacks[_selected_slot] == null:
		return false
	return _stacks[_selected_slot].consume_container(amount)


func purify_selected_container() -> bool:
	if _slot_count == 0 or _stacks[_selected_slot] == null:
		return false
	return _stacks[_selected_slot].purify_container()


func purify_container_at(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= _slot_count or _stacks[slot_index] == null:
		return false
	return _stacks[slot_index].purify_container()


func transfer_water(source_slot: int, target_slot: int, amount: int = 1) -> bool:
	if source_slot < 0 or source_slot >= _slot_count or target_slot < 0 or target_slot >= _slot_count \
		or source_slot == target_slot or amount <= 0:
		return false
	var source: RefCounted = _stacks[source_slot]
	var target: RefCounted = _stacks[target_slot]
	if source == null or target == null:
		return false
	var source_state: Dictionary = source.get_container_snapshot()
	var target_state: Dictionary = target.get_container_snapshot()
	if source_state.is_empty() or target_state.is_empty() or int(source_state.get("amount", 0)) < amount:
		return false
	var source_type: int = int(source_state.get("source", WATER_CONTAINER_MODEL_SCRIPT.Source.EMPTY))
	var purified: bool = bool(source_state.get("purified", false))
	if not target.can_receive_container(amount, source_type, purified):
		return false
	if not target.fill_container(source_type, amount, purified) or not source.consume_container(amount):
		source.restore_container_snapshot(source_state)
		target.restore_container_snapshot(target_state)
		return false
	return true


func get_selected_slot() -> int:
	return _selected_slot


func set_selected_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= _slot_count or _selected_slot == slot_index:
		return false
	_selected_slot = slot_index
	return true


func cycle_selected(delta: int) -> bool:
	if _slot_count == 0 or delta == 0:
		return false
	var normalized_delta: int = clampi(delta, -1, 1)
	return set_selected_slot((_selected_slot + normalized_delta + _slot_count) % _slot_count)


func get_stacks() -> Array[RefCounted]:
	var result: Array[RefCounted] = []
	for stack: RefCounted in _stacks:
		result.append(stack.duplicate_stack() if stack != null else null)
	return result


func get_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for stack: RefCounted in _stacks:
		result.append(stack.get_definition() if stack != null else null)
	return result


func get_total_weight() -> float:
	var total: float = 0.0
	for stack: RefCounted in _stacks:
		if stack != null:
			total += stack.get_total_weight()
	return total


func get_occupied_slot_count() -> int:
	var occupied := 0
	for stack: RefCounted in _stacks:
		if stack != null:
			occupied += 1
	return occupied


func consume_selected(quantity: int = 1) -> bool:
	if _slot_count == 0 or _stacks[_selected_slot] == null:
		return false
	var stack: RefCounted = _stacks[_selected_slot]
	if not stack.remove_quantity(quantity):
		return false
	if stack.get_quantity() == 0:
		_stacks[_selected_slot] = null
	return true


func drop_selected() -> RefCounted:
	if _slot_count == 0 or _stacks[_selected_slot] == null:
		return null
	var dropped: RefCounted = _stacks[_selected_slot]
	_stacks[_selected_slot] = null
	return dropped


func drop_all() -> Array[RefCounted]:
	var dropped: Array[RefCounted] = []
	for stack: RefCounted in _stacks:
		if stack != null:
			dropped.append(stack)
	_stacks.fill(null)
	return dropped


func clear() -> void:
	_stacks.fill(null)
	_selected_slot = 0


func create_snapshot() -> Dictionary:
	var stacks: Array[Dictionary] = []
	for stack: RefCounted in _stacks:
		stacks.append(stack.create_snapshot() if stack != null else {})
	return {"format_version": FORMAT_VERSION, "slot_count": _slot_count, "selected_slot": _selected_slot, "stacks": stacks}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if snapshot.has("format_version"):
		return _restore_current_snapshot(snapshot)
	return _restore_legacy_snapshot(snapshot)


func _restore_current_snapshot(snapshot: Dictionary) -> bool:
	if _to_integral(snapshot.get("format_version")) != FORMAT_VERSION or not snapshot.get("stacks") is Array:
		return false
	var slot_count: int = _to_integral(snapshot.get("slot_count"))
	var selected_slot: int = _to_integral(snapshot.get("selected_slot"))
	var raw_stacks: Array = snapshot["stacks"]
	if slot_count < 0 or (slot_count > 0 and (selected_slot < 0 or selected_slot >= slot_count)) \
		or (slot_count == 0 and selected_slot != 0) or raw_stacks.size() != slot_count:
		return false
	var restored: Array[RefCounted] = []
	for raw: Variant in raw_stacks:
		if not raw is Dictionary:
			return false
		if (raw as Dictionary).is_empty():
			restored.append(null)
			continue
		var stack: RefCounted = ITEM_STACK_MODEL_SCRIPT.new()
		if _catalog == null or not stack.restore_snapshot(raw, _catalog):
			return false
		restored.append(stack)
	_stacks = restored
	_slot_count = slot_count
	_selected_slot = selected_slot
	return true


func _restore_legacy_snapshot(snapshot: Dictionary) -> bool:
	if not snapshot.get("items") is Array:
		return false
	var slot_count: int = _to_integral(snapshot.get("slot_count"))
	var selected_slot: int = _to_integral(snapshot.get("selected_slot"))
	var items: Array = snapshot["items"]
	if slot_count < 0 or (slot_count > 0 and (selected_slot < 0 or selected_slot >= slot_count)) \
		or (slot_count == 0 and selected_slot != 0) or items.size() != slot_count:
		return false
	var restored: Array[RefCounted] = []
	for raw: Variant in items:
		if not raw is Dictionary:
			return false
		var data: Dictionary = raw
		var id: String = String(data.get("id", ""))
		if id.is_empty():
			restored.append(null)
			continue
		if _catalog == null:
			return false
		var item: ItemData = _catalog.get_item(StringName(id))
		var stack: RefCounted = ITEM_STACK_MODEL_SCRIPT.new()
		if item == null or not stack.setup(item, 1):
			return false
		restored.append(stack)
	_stacks = restored
	_slot_count = slot_count
	_selected_slot = selected_slot
	return true


func _is_compatible(stack: RefCounted, item: ItemData) -> bool:
	return stack != null and stack.get_definition() != null \
		and stack.get_definition().id == item.id and item.max_durability == 0


func _has_quantity(item: ItemData, quantity: int) -> bool:
	if item == null or quantity <= 0:
		return false
	var available: int = 0
	for stack: RefCounted in _stacks:
		if _is_compatible(stack, item):
			available += stack.get_quantity()
	return available >= quantity


func _to_integral(value: Variant) -> int:
	if value is int:
		return value
	if value is float and is_finite(value) and is_equal_approx(value, floor(value)):
		return int(value)
	return -1
