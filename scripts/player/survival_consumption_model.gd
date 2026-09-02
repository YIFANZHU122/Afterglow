extends RefCounted
class_name SurvivalConsumptionModel

## 食物、水和疾病状态的运行时规则，不依赖 Inventory 或 HUD。

const SURVIVAL_TUNING_SCRIPT: Script = preload("res://scripts/data/survival_tuning.gd")
const DISEASE_KIND: StringName = &"food_or_water"
const DISEASE_DURATION_SECONDS: float = 240.0

var _disease_remaining_seconds: float = 0.0


func consume_food(item: ItemData, vitals: RefCounted, disease_roll: float, disease_chance_override: float = -1.0) -> bool:
	if item == null or vitals == null or item.item_type != ItemData.ItemType.FOOD \
		or item.food_restore <= 0.0 or not is_finite(disease_roll) or disease_roll < 0.0 or disease_roll > 1.0:
		return false
	if not vitals.consume_food(item.food_restore):
		return false
	var disease_chance: float = item.disease_chance if disease_chance_override < 0.0 else disease_chance_override
	if item.is_raw_food and disease_roll < disease_chance:
		_disease_remaining_seconds = DISEASE_DURATION_SECONDS
	return true


func consume_water(amount: float, vitals: RefCounted, disease_roll: float, disease_chance: float = 0.0) -> bool:
	if vitals == null or not is_finite(amount) or amount <= 0.0 or not is_finite(disease_roll) \
		or disease_roll < 0.0 or disease_roll > 1.0 or not is_finite(disease_chance) \
		or disease_chance < 0.0 or disease_chance > 1.0:
		return false
	if not vitals.consume_water(amount):
		return false
	if disease_roll < disease_chance:
		_disease_remaining_seconds = DISEASE_DURATION_SECONDS
	return true


func tick(delta: float) -> void:
	if delta > 0.0:
		_disease_remaining_seconds = maxf(_disease_remaining_seconds - delta, 0.0)


func cure() -> bool:
	if not has_disease():
		return false
	_disease_remaining_seconds = 0.0
	return true


func has_disease() -> bool:
	return _disease_remaining_seconds > 0.0


func get_disease_remaining_seconds() -> float:
	return _disease_remaining_seconds


func get_consumption_multiplier() -> float:
	return 1.25 if has_disease() else 1.0


func get_stamina_recovery_multiplier() -> float:
	return 0.80 if has_disease() else 1.0


func create_snapshot() -> Dictionary:
	return {"disease_kind": String(DISEASE_KIND), "disease_remaining_seconds": _disease_remaining_seconds}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if snapshot.is_empty():
		_disease_remaining_seconds = 0.0
		return true
	if snapshot.size() != 2 or snapshot.get("disease_kind") != String(DISEASE_KIND) \
		or not (snapshot.get("disease_remaining_seconds") is int or snapshot.get("disease_remaining_seconds") is float):
		return false
	var remaining: float = float(snapshot["disease_remaining_seconds"])
	if not is_finite(remaining) or remaining < 0.0 or remaining > DISEASE_DURATION_SECONDS:
		return false
	_disease_remaining_seconds = remaining
	return true
