extends RefCounted
class_name EquipmentTransactionModel

## 在库存与角色构筑之间执行可回滚的装备交易。


func equip_selected(inventory: Object, character_build: RefCounted, catalog: RefCounted) -> bool:
	if inventory == null or character_build == null or catalog == null \
		or not inventory.has_method(&"get_selected_item") or not inventory.has_method(&"create_snapshot") \
		or not inventory.has_method(&"restore_snapshot"):
		return false
	var selected: ItemData = inventory.call("get_selected_item") as ItemData
	if selected == null or selected.item_type != ItemData.ItemType.EQUIPMENT or selected.equipment_definition == null:
		return false
	var inventory_snapshot: Dictionary = inventory.call("create_snapshot") as Dictionary
	var build_snapshot: Dictionary = character_build.create_snapshot()
	var slot: int = int(selected.equipment_definition.slot)
	var previous_id: StringName = character_build.get_equipped_item_id(slot)
	if not inventory.call("consume_selected", 1):
		return false
	if not character_build.equip_item(selected, int(inventory.call("get_occupied_slot_count"))):
		_restore(inventory, character_build, catalog, inventory_snapshot, build_snapshot)
		return false
	if not inventory.call("configure_slot_count", character_build.get_inventory_slot_count()):
		_restore(inventory, character_build, catalog, inventory_snapshot, build_snapshot)
		return false
	if not previous_id.is_empty():
		var previous: ItemData = catalog.call("get_item", previous_id) as ItemData
		if previous == null or not inventory.call("add_item", previous):
			_restore(inventory, character_build, catalog, inventory_snapshot, build_snapshot)
			return false
	return true


func unequip_slot(inventory: Object, character_build: RefCounted, catalog: RefCounted, slot: int) -> bool:
	if inventory == null or character_build == null or catalog == null:
		return false
	var item_id: StringName = character_build.get_equipped_item_id(slot)
	if item_id.is_empty():
		return false
	var inventory_snapshot: Dictionary = inventory.call("create_snapshot") as Dictionary
	var build_snapshot: Dictionary = character_build.create_snapshot()
	if character_build.unequip_slot(slot, int(inventory.call("get_occupied_slot_count"))) == null:
		return false
	if not inventory.call("configure_slot_count", character_build.get_inventory_slot_count()):
		_restore(inventory, character_build, catalog, inventory_snapshot, build_snapshot)
		return false
	var item: ItemData = catalog.call("get_item", item_id) as ItemData
	if item == null or not inventory.call("add_item", item):
		_restore(inventory, character_build, catalog, inventory_snapshot, build_snapshot)
		return false
	return true


func _restore(inventory: Object, character_build: RefCounted, catalog: RefCounted, inventory_snapshot: Dictionary, build_snapshot: Dictionary) -> void:
	inventory.call("restore_snapshot", inventory_snapshot)
	character_build.restore_snapshot(build_snapshot, catalog)
