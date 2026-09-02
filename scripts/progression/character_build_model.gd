extends RefCounted
class_name CharacterBuildModel

## 统一组合属性、装备、Buff 和负重的最终属性解析器。

const CHARACTER_ATTRIBUTES_MODEL_SCRIPT: Script = preload("res://scripts/progression/character_attributes_model.gd")
const EQUIPMENT_MODEL_SCRIPT: Script = preload("res://scripts/items/equipment_model.gd")
const ENCUMBRANCE_MODEL_SCRIPT: Script = preload("res://scripts/player/encumbrance_model.gd")

var attributes: RefCounted
var equipment: RefCounted
var encumbrance: RefCounted
var buffs: Object


func _init(attribute_model: RefCounted = null, equipment_model: RefCounted = null, buff_model: Object = null, encumbrance_model: RefCounted = null) -> void:
	attributes = attribute_model if attribute_model != null else CHARACTER_ATTRIBUTES_MODEL_SCRIPT.new()
	equipment = equipment_model if equipment_model != null else EQUIPMENT_MODEL_SCRIPT.new()
	buffs = buff_model
	encumbrance = encumbrance_model if encumbrance_model != null else ENCUMBRANCE_MODEL_SCRIPT.new()


func refresh_weight(current_weight: float) -> bool:
	if not encumbrance.set_bonus_capacity(attributes.get_carry_capacity_bonus() + equipment.get_carry_capacity_bonus()):
		return false
	return encumbrance.set_current_weight(current_weight)


func allocate_attribute(attribute: int, amount: int = 1) -> bool:
	return attributes.allocate(attribute, amount)


func confirm_attributes() -> bool:
	return attributes.confirm()


func get_attribute_points_remaining() -> int:
	return attributes.get_points_remaining()


func get_attribute_total_points() -> int:
	return attributes.get_total_points()


func get_attribute_value(attribute: int) -> int:
	return attributes.get_value(attribute)


func are_attributes_confirmed() -> bool:
	return attributes.is_confirmed()


func get_equipped_item_id(slot: int) -> StringName:
	var item: ItemData = equipment.get_equipped(slot)
	return item.id if item != null else StringName()


func get_max_health(base_value: float = 100.0) -> float:
	var value: float = base_value + attributes.get_max_health_bonus()
	if equipment.get_equipped(1) != null:
		var chest: ItemData = equipment.get_equipped(1)
		var raw_bonus: Variant = chest.equipment_definition.get("max_health_bonus")
		if raw_bonus != null:
			value += float(raw_bonus)
	return value * _buff_multiplier(&"get_max_health_multiplier")


func get_max_stamina(base_value: float = 100.0) -> float:
	return (base_value + attributes.get_max_stamina_bonus()) * _buff_multiplier(&"get_max_stamina_multiplier")


func get_melee_damage(base_value: float) -> float:
	return base_value * attributes.get_melee_damage_multiplier() * equipment.get_melee_damage_multiplier() * _buff_multiplier(&"get_damage_multiplier")


func get_move_speed_multiplier() -> float:
	return encumbrance.get_speed_multiplier() * equipment.get_move_speed_multiplier() * _buff_multiplier(&"get_move_speed_multiplier")


func get_stamina_cost_multiplier() -> float:
	return encumbrance.get_stamina_cost_multiplier() * equipment.get_stamina_cost_multiplier()


func get_stamina_regen_multiplier() -> float:
	return attributes.get_stamina_regen_multiplier() * _buff_multiplier(&"get_stamina_regen_multiplier")


func get_crafting_speed_multiplier() -> float:
	return attributes.get_crafting_speed_multiplier()


func get_inventory_slot_count() -> int:
	return equipment.get_inventory_slot_count()


func equip_item(item: ItemData, occupied_inventory_slots: int = 0) -> bool:
	return equipment.equip(item, occupied_inventory_slots)


func unequip_slot(slot: int, occupied_inventory_slots: int = 0) -> ItemData:
	return equipment.unequip(slot, occupied_inventory_slots)


func get_max_carry_capacity() -> float:
	return encumbrance.get_max_capacity()


func get_current_weight() -> float:
	return encumbrance.get_current_weight()


func can_run() -> bool:
	return encumbrance.can_run()


func can_high_intensity_action() -> bool:
	return encumbrance.can_high_intensity_action()


func create_snapshot() -> Dictionary:
	return {
		"format_version": 1,
		"attributes": attributes.create_snapshot(),
		"equipment": equipment.create_snapshot(),
		"encumbrance": encumbrance.create_snapshot(),
	}


func restore_snapshot(snapshot: Dictionary, catalog: RefCounted = null) -> bool:
	if int(snapshot.get("format_version", -1)) != 1:
		return false
	var raw_attributes: Variant = snapshot.get("attributes", null)
	var raw_equipment: Variant = snapshot.get("equipment", null)
	var raw_encumbrance: Variant = snapshot.get("encumbrance", null)
	if not raw_attributes is Dictionary or not raw_equipment is Dictionary or not raw_encumbrance is Dictionary:
		return false
	if not attributes.restore_snapshot(raw_attributes):
		return false
	if catalog == null or not equipment.restore_snapshot(raw_equipment, catalog):
		return false
	if not encumbrance.restore_snapshot(raw_encumbrance):
		return false
	return true


func _buff_multiplier(method_name: StringName) -> float:
	if buffs == null:
		return 1.0
	if buffs.has_method(method_name):
		return maxf(float(buffs.call(method_name)), 0.0)
	var suffix := String(method_name).trim_prefix("get_")
	var run_method := StringName("get_run_" + suffix)
	if buffs.has_method(run_method):
		return maxf(float(buffs.call(run_method)), 0.0)
	return 1.0
