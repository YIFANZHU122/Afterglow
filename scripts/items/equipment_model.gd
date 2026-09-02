extends RefCounted
class_name EquipmentModel

## 四装备槽运行时关系；装备定义来自 ItemData.equipment_definition。

const FORMAT_VERSION: int = 1
const BASE_INVENTORY_SLOTS: int = 8
const ITEM_DATA_SCRIPT: Script = preload("res://scripts/item_data.gd")
const EQUIPMENT_DEFINITION_SCRIPT: Script = preload("res://scripts/data/equipment_definition.gd")

var _slots: Dictionary = {}
var _catalog: RefCounted


func _init(catalog: RefCounted = null) -> void:
	_catalog = catalog
	for slot: int in range(EQUIPMENT_DEFINITION_SCRIPT.Slot.HEAD, EQUIPMENT_DEFINITION_SCRIPT.Slot.BACKPACK + 1):
		_slots[slot] = null


func can_equip(item: ItemData, occupied_inventory_slots: int = 0) -> bool:
	if not _is_valid_item(item):
		return false
	var definition: Resource = item.equipment_definition
	var slot: int = int(definition.slot)
	if slot == EQUIPMENT_DEFINITION_SCRIPT.Slot.BACKPACK:
		if occupied_inventory_slots > BASE_INVENTORY_SLOTS + int(definition.inventory_slot_bonus):
			return false
	return true


func equip(item: ItemData, occupied_inventory_slots: int = 0) -> bool:
	if not can_equip(item, occupied_inventory_slots):
		return false
	_slots[int(item.equipment_definition.slot)] = item
	return true


func can_unequip(slot: int, occupied_inventory_slots: int = 0) -> bool:
	if not _is_valid_slot(slot) or _slots.get(slot) == null:
		return false
	var resulting_bonus: int = 0
	if slot == EQUIPMENT_DEFINITION_SCRIPT.Slot.BACKPACK:
		if occupied_inventory_slots > BASE_INVENTORY_SLOTS:
			return false
	return true


func unequip(slot: int, occupied_inventory_slots: int = 0) -> ItemData:
	if not can_unequip(slot, occupied_inventory_slots):
		return null
	var item: ItemData = _slots[slot]
	_slots[slot] = null
	return item


func get_equipped(slot: int) -> ItemData:
	return _slots.get(slot)


func get_inventory_slot_count(base_slots: int = BASE_INVENTORY_SLOTS) -> int:
	var count := maxi(base_slots, 0)
	var backpack: ItemData = _slots.get(EQUIPMENT_DEFINITION_SCRIPT.Slot.BACKPACK)
	if backpack != null and backpack.equipment_definition != null:
		count += backpack.equipment_definition.inventory_slot_bonus
	return count


func get_carry_capacity_bonus() -> float:
	var total := 0.0
	for item: ItemData in _slots.values():
		if item != null and item.equipment_definition != null:
			total += item.equipment_definition.carry_capacity_bonus
	return total


func get_move_speed_multiplier() -> float:
	var bonus := 0.0
	for item: ItemData in _slots.values():
		if item != null and item.equipment_definition != null:
			bonus += item.equipment_definition.move_speed_multiplier - 1.0
	return maxf(0.1, 1.0 + bonus)


func get_stamina_cost_multiplier() -> float:
	var bonus := 0.0
	for item: ItemData in _slots.values():
		if item != null and item.equipment_definition != null:
			bonus += item.equipment_definition.stamina_cost_multiplier - 1.0
	return maxf(0.1, 1.0 + bonus)


func get_melee_damage_multiplier() -> float:
	var bonus := 0.0
	for item: ItemData in _slots.values():
		if item != null and item.equipment_definition != null:
			bonus += item.equipment_definition.melee_damage_multiplier - 1.0
	return maxf(0.1, 1.0 + bonus)


func get_damage_reduction() -> float:
	var total := 0.0
	for item: ItemData in _slots.values():
		if item != null and item.equipment_definition != null:
			total = minf(total + item.equipment_definition.damage_reduction, 0.75)
	return total


func create_snapshot() -> Dictionary:
	var equipped: Dictionary = {}
	for slot: int in _slots:
		var item: ItemData = _slots[slot]
		equipped[str(slot)] = String(item.id) if item != null else ""
	return {"format_version": FORMAT_VERSION, "equipped": equipped}


func restore_snapshot(snapshot: Dictionary, catalog: RefCounted = _catalog) -> bool:
	if snapshot.is_empty() or int(snapshot.get("format_version", -1)) != FORMAT_VERSION:
		return false
	var raw: Variant = snapshot.get("equipped", null)
	if not raw is Dictionary or catalog == null:
		return false
	var restored: Dictionary = {}
	for slot: int in range(EQUIPMENT_DEFINITION_SCRIPT.Slot.HEAD, EQUIPMENT_DEFINITION_SCRIPT.Slot.BACKPACK + 1):
		var raw_id: Variant = (raw as Dictionary).get(str(slot), "")
		if typeof(raw_id) != TYPE_STRING and typeof(raw_id) != TYPE_STRING_NAME:
			return false
		if String(raw_id).is_empty():
			restored[slot] = null
			continue
		var item: ItemData = catalog.get_item(StringName(raw_id))
		if not _is_valid_item(item) or int(item.equipment_definition.slot) != slot:
			return false
		restored[slot] = item
	_slots = restored
	return true


func _is_valid_slot(slot: int) -> bool:
	return slot >= EQUIPMENT_DEFINITION_SCRIPT.Slot.HEAD and slot <= EQUIPMENT_DEFINITION_SCRIPT.Slot.BACKPACK


func _is_valid_item(item: ItemData) -> bool:
	return item != null and item.get_script() == ITEM_DATA_SCRIPT and item.item_type == ITEM_DATA_SCRIPT.ItemType.EQUIPMENT \
		and item.equipment_definition != null and item.equipment_definition.get_script() == EQUIPMENT_DEFINITION_SCRIPT \
		and item.equipment_definition.is_valid()
