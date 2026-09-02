extends RefCounted
class_name DropBudgetModel

## 单张地图奖励预算：食物保底、材料上限和结晶上限。

const FORMAT_VERSION: int = 1
const FOOD_PITY_MISSES: int = 3

var _food_budget: int = 0
var _material_budget: int = 0
var _crystal_budget: int = 0
var _food_misses: int = 0
var _material_spent: int = 0
var _crystal_spent: int = 0


func _init(food_budget: int = 3, material_budget: int = 8, crystal_budget: int = 2) -> void:
	_food_budget = maxi(food_budget, 0)
	_material_budget = maxi(material_budget, 0)
	_crystal_budget = maxi(crystal_budget, 0)


func should_force_food() -> bool:
	return _food_budget > 0 and _food_misses >= FOOD_PITY_MISSES


func register_kill(dropped_food: bool, food_eligible: bool = true) -> bool:
	if not food_eligible:
		return true
	if dropped_food:
		_food_misses = 0
		_food_budget = maxi(_food_budget - 1, 0)
	else:
		_food_misses += 1
	return true


func get_material_remaining() -> int:
	return maxi(_material_budget - _material_spent, 0)


func get_crystal_remaining() -> int:
	return maxi(_crystal_budget - _crystal_spent, 0)


func try_spend_material_budget(amount: int) -> bool:
	if amount <= 0 or _material_spent + amount > _material_budget:
		return false
	_material_spent += amount
	return true


func try_spend_crystal_budget(amount: int = 1) -> bool:
	if amount <= 0 or _crystal_spent + amount > _crystal_budget:
		return false
	_crystal_spent += amount
	return true


func get_food_budget() -> int:
	return _food_budget


func get_food_misses() -> int:
	return _food_misses


func get_material_spent() -> int:
	return _material_spent


func get_crystal_spent() -> int:
	return _crystal_spent


func create_snapshot() -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"food_budget": _food_budget,
		"material_budget": _material_budget,
		"crystal_budget": _crystal_budget,
		"food_misses": _food_misses,
		"material_spent": _material_spent,
		"crystal_spent": _crystal_spent,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["format_version", "food_budget", "material_budget", "crystal_budget", "food_misses", "material_spent", "crystal_spent"]:
		if not snapshot.has(key):
			return false
	var food_budget: int = int(snapshot["food_budget"])
	var material_budget: int = int(snapshot["material_budget"])
	var crystal_budget: int = int(snapshot["crystal_budget"])
	var food_misses: int = int(snapshot["food_misses"])
	var material_spent: int = int(snapshot["material_spent"])
	var crystal_spent: int = int(snapshot["crystal_spent"])
	if int(snapshot["format_version"]) != FORMAT_VERSION or food_budget < 0 or material_budget < 0 or crystal_budget < 0 \
		or food_misses < 0 or material_spent < 0 or material_spent > material_budget or crystal_spent < 0 or crystal_spent > crystal_budget:
		return false
	_food_budget = food_budget
	_material_budget = material_budget
	_crystal_budget = crystal_budget
	_food_misses = food_misses
	_material_spent = material_spent
	_crystal_spent = crystal_spent
	return true
