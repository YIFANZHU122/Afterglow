extends RefCounted
class_name ResourceBudgetModel

## 单张普通地图的生存资源保底预算，不依赖场景生成方式。

const SURVIVAL_TUNING_SCRIPT: Script = preload("res://scripts/data/survival_tuning.gd")

const BASE_GUARANTEED_FOOD: int = 9
const BASE_GUARANTEED_WATER: int = 12
const EMERGENCY_RESERVE_RATIO: float = 0.20

var _guaranteed_food: int
var _guaranteed_water: int


func _init(difficulty: int = 0) -> void:
	var richness: float = SURVIVAL_TUNING_SCRIPT.difficulty_resource_richness(difficulty)
	_guaranteed_food = maxi(roundi(float(BASE_GUARANTEED_FOOD) * richness), 1)
	_guaranteed_water = maxi(roundi(float(BASE_GUARANTEED_WATER) * richness), 1)


func get_guaranteed_food() -> int:
	return _guaranteed_food


func get_guaranteed_water() -> int:
	return _guaranteed_water


func get_emergency_food() -> int:
	return ceili(float(_guaranteed_food) * EMERGENCY_RESERVE_RATIO)


func get_emergency_water() -> int:
	return ceili(float(_guaranteed_water) * EMERGENCY_RESERVE_RATIO)


func get_total_food() -> int:
	return _guaranteed_food + get_emergency_food()


func get_total_water() -> int:
	return _guaranteed_water + get_emergency_water()
