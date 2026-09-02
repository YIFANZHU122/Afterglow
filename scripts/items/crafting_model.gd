extends RefCounted
class_name CraftingModel

## 可中断制作任务；开始时扣除材料，取消时返还，完成时加入产物。

enum State { IDLE, RUNNING, COMPLETE, INTERRUPTED }
const RECIPE_DEFINITION_SCRIPT: Script = preload("res://scripts/data/recipe_definition.gd")

var _state: State = State.IDLE
var _recipe: Resource
var _inventory: RefCounted
var _remaining_seconds: float = 0.0
var _reserved_ingredients: Array[Resource] = []


func begin(recipe: Resource, inventory: RefCounted, intelligence: int = 0, station_type: int = 0) -> bool:
	if _state == State.RUNNING or _state == State.COMPLETE or recipe == null or recipe.get_script() != RECIPE_DEFINITION_SCRIPT \
		or inventory == null:
		return false
	var typed_recipe: Resource = recipe
	if not typed_recipe.is_valid() or intelligence < typed_recipe.required_intelligence or station_type != typed_recipe.station_type:
		return false
	if not inventory.can_craft(typed_recipe) or not inventory.can_add_quantity(typed_recipe.output_item, typed_recipe.output_quantity):
		return false
	for raw: Resource in typed_recipe.ingredients:
		var ingredient: Resource = raw
		if not inventory.remove_quantity(ingredient.item, ingredient.quantity):
			_refund_ingredients()
			return false
		_reserved_ingredients.append(ingredient)
	_recipe = typed_recipe
	_inventory = inventory
	_remaining_seconds = typed_recipe.craft_time_seconds
	_state = State.RUNNING
	return true


func advance(delta: float, moving: bool, took_damage: bool, workstation_valid: bool) -> bool:
	if _state != State.RUNNING or delta <= 0.0:
		return false
	if moving or took_damage or not workstation_valid:
		_interrupt()
		return false
	_remaining_seconds = maxf(_remaining_seconds - delta, 0.0)
	if is_zero_approx(_remaining_seconds):
		if not _inventory.add_quantity(_recipe.output_item, _recipe.output_quantity):
			_interrupt()
			return false
		_reserved_ingredients.clear()
		_state = State.COMPLETE
	return true


func interrupt() -> bool:
	if _state != State.RUNNING:
		return false
	_interrupt()
	return true


func get_state() -> State:
	return _state


func is_complete() -> bool:
	return _state == State.COMPLETE


func is_interrupted() -> bool:
	return _state == State.INTERRUPTED


func get_remaining_seconds() -> float:
	return _remaining_seconds


func _interrupt() -> void:
	_refund_ingredients()
	_remaining_seconds = 0.0
	_state = State.INTERRUPTED


func _refund_ingredients() -> void:
	if _inventory == null:
		_reserved_ingredients.clear()
		return
	for ingredient: Resource in _reserved_ingredients:
		_inventory.add_quantity(ingredient.item, ingredient.quantity)
	_reserved_ingredients.clear()
