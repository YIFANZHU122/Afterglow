extends RefCounted
class_name ItemStackModel

## 运行时物品栈。只持有静态定义引用和本次运行的数量/耐久。

const FORMAT_VERSION: int = 1
const RUNTIME_FORMAT_VERSION: int = 2
const WATER_CONTAINER_MODEL_SCRIPT: Script = preload("res://scripts/items/water_container_model.gd")

var _item: ItemData
var _quantity: int = 0
var _durability: int = -1
var _container: RefCounted


func setup(item: ItemData, quantity: int, durability: int = -1) -> bool:
	if not _is_valid_setup(item, quantity, durability):
		return false
	_item = item
	_quantity = quantity
	_durability = durability
	_container = WATER_CONTAINER_MODEL_SCRIPT.new(item.container_capacity) if item.item_type == ItemData.ItemType.CONTAINER and item.container_capacity > 0 else null
	return true


func get_definition() -> ItemData:
	return _item


func get_quantity() -> int:
	return _quantity


func get_durability() -> int:
	return _durability


func damage_durability(amount: int = 1) -> bool:
	if _item == null or _item.max_durability <= 0 or amount <= 0 or _durability < 0:
		return false
	_durability = maxi(_durability - amount, 0)
	return true


func get_available_capacity() -> int:
	return _item.max_stack - _quantity if _item != null else 0


func get_total_weight() -> float:
	return _item.unit_weight * _quantity if _item != null else 0.0


func get_container_snapshot() -> Dictionary:
	return _container.create_snapshot() if _container != null else {}


func fill_container(source: int, amount: int, purified: bool) -> bool:
	return _container != null and _container.fill(source, amount, purified)


func consume_container(amount: int = 1) -> bool:
	return _container != null and _container.consume(amount)


func purify_container() -> bool:
	return _container != null and _container.purify()


func restore_container_snapshot(snapshot: Dictionary) -> bool:
	return _container != null and _container.restore_snapshot(snapshot)


func can_receive_container(amount: int, source: int, purified: bool) -> bool:
	if _container == null:
		return false
	var snapshot: Dictionary = _container.create_snapshot()
	var accepted: bool = _container.fill(source, amount, purified)
	_container.restore_snapshot(snapshot)
	return accepted


func can_add_quantity(quantity: int) -> bool:
	return quantity > 0 and _item != null and _quantity + quantity <= _item.max_stack


func add_quantity(quantity: int) -> bool:
	if not can_add_quantity(quantity):
		return false
	_quantity += quantity
	return true


func remove_quantity(quantity: int) -> bool:
	if quantity <= 0 or quantity > _quantity:
		return false
	_quantity -= quantity
	return true


func duplicate_stack() -> RefCounted:
	var copy: RefCounted = get_script().new()
	copy.setup(_item, _quantity, _durability)
	if _container != null:
		copy._container.restore_snapshot(_container.create_snapshot())
	return copy


func create_snapshot() -> Dictionary:
	return {
		"format_version": RUNTIME_FORMAT_VERSION,
		"item_id": String(_item.id) if _item != null else "",
		"quantity": _quantity,
		"durability": _durability,
		"container_state": _container.create_snapshot() if _container != null else {},
	}


func restore_snapshot(snapshot: Dictionary, catalog: RefCounted) -> bool:
	if catalog == null or not snapshot is Dictionary:
		return false
	var format_version: int = _to_integral(snapshot.get("format_version"))
	if format_version != FORMAT_VERSION and format_version != RUNTIME_FORMAT_VERSION:
		return false
	if format_version == FORMAT_VERSION and not _has_legacy_fields(snapshot):
		return false
	if format_version == RUNTIME_FORMAT_VERSION and not _has_runtime_fields(snapshot):
		return false
	if snapshot["item_id"] is not String:
		return false
	if not _is_numeric(snapshot["format_version"]) or not _is_numeric(snapshot["quantity"]) \
		or not _is_numeric(snapshot["durability"]):
		return false
	var quantity: int = _to_integral(snapshot["quantity"])
	var durability: int = _to_integral(snapshot["durability"])
	if quantity < 0 or durability < -1:
		return false
	var item_id := StringName(snapshot["item_id"])
	if item_id.is_empty():
		return false
	var item: ItemData = catalog.get_item(item_id)
	if not _is_valid_setup(item, quantity, durability):
		return false
	var candidate_container: RefCounted = WATER_CONTAINER_MODEL_SCRIPT.new(item.container_capacity) if item.item_type == ItemData.ItemType.CONTAINER and item.container_capacity > 0 else null
	if format_version == RUNTIME_FORMAT_VERSION:
		var container_state: Variant = snapshot.get("container_state")
		if candidate_container != null:
			if not container_state is Dictionary or not candidate_container.restore_snapshot(container_state):
				return false
		elif container_state is not Dictionary or not (container_state as Dictionary).is_empty():
			return false
	_item = item
	_quantity = quantity
	_durability = durability
	_container = candidate_container
	return true


func _is_valid_setup(item: ItemData, quantity: int, durability: int) -> bool:
	if item == null or not item.is_valid() or quantity <= 0 or quantity > item.max_stack:
		return false
	if item.max_durability > 0:
		return quantity == 1 and durability >= 0 and durability <= item.max_durability
	return durability == -1


func _has_legacy_fields(snapshot: Dictionary) -> bool:
	if snapshot.size() != 4:
		return false
	for key: String in ["format_version", "item_id", "quantity", "durability"]:
		if not snapshot.has(key):
			return false
	return true


func _has_runtime_fields(snapshot: Dictionary) -> bool:
	if snapshot.size() != 5:
		return false
	for key: String in ["format_version", "item_id", "quantity", "durability", "container_state"]:
		if not snapshot.has(key):
			return false
	return true


func _to_integral(value: Variant) -> int:
	if value is int:
		return value
	if value is float and is_finite(value) and is_equal_approx(value, floor(value)):
		return int(value)
	return -1


func _is_numeric(value: Variant) -> bool:
	return value is int or value is float
