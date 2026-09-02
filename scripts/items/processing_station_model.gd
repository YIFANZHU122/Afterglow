extends RefCounted
class_name ProcessingStationModel

## 篝火的双工位加工模型：烹饪与净水可同时存在，移动/受击/失效会中断。

enum JobState { IDLE, RUNNING, COMPLETE, INTERRUPTED }
const ITEM_CATALOG_SCRIPT: Script = preload("res://scripts/items/item_catalog.gd")

const COOKING_SECONDS: float = 8.0
const PURIFYING_SECONDS: float = 6.0

var _cooking_state: JobState = JobState.IDLE
var _cooking_remaining: float = 0.0
var _purifying_state: JobState = JobState.IDLE
var _purifying_remaining: float = 0.0
var _inventory: Object
var _cooking_slot: int = -1
var _purifying_slot: int = -1


func start_cooking(inventory: Object) -> bool:
	if _cooking_state == JobState.RUNNING or inventory == null:
		return false
	var selected: ItemData = inventory.get_selected_item()
	var catalog: RefCounted = ITEM_CATALOG_SCRIPT.new()
	var raw_meat: ItemData = catalog.get_item(&"raw_meat")
	var cooked_meat: ItemData = catalog.get_item(&"cooked_meat")
	if selected == null or raw_meat == null or cooked_meat == null or selected.id != raw_meat.id \
		or not inventory.can_add_quantity(cooked_meat, 1) or not inventory.remove_quantity(raw_meat, 1):
		return false
	_inventory = inventory
	_cooking_slot = inventory.get_selected_slot()
	_cooking_remaining = COOKING_SECONDS
	_cooking_state = JobState.RUNNING
	return true


func start_purifying(inventory: Object) -> bool:
	if _purifying_state == JobState.RUNNING or inventory == null:
		return false
	var selected_slot: int = inventory.get_selected_slot()
	var state: Dictionary = inventory.get_container_snapshot_at(selected_slot)
	if state.is_empty() or int(state.get("amount", 0)) <= 0 or bool(state.get("purified", false)):
		return false
	_inventory = inventory
	_purifying_slot = selected_slot
	_purifying_remaining = PURIFYING_SECONDS
	_purifying_state = JobState.RUNNING
	return true


func advance(delta: float, moving: bool, took_damage: bool, workstation_valid: bool) -> bool:
	if delta <= 0.0:
		return false
	var advanced: bool = false
	if _cooking_state == JobState.RUNNING:
		if moving or took_damage or not workstation_valid:
			_interrupt_cooking()
		else:
			advanced = true
			_cooking_remaining = maxf(_cooking_remaining - delta, 0.0)
			if is_zero_approx(_cooking_remaining):
				_finish_cooking()
	if _purifying_state == JobState.RUNNING:
		if moving or took_damage or not workstation_valid:
			_purifying_state = JobState.INTERRUPTED
			_purifying_remaining = 0.0
		else:
			advanced = true
			_purifying_remaining = maxf(_purifying_remaining - delta, 0.0)
			if is_zero_approx(_purifying_remaining):
				if _inventory.purify_container_at(_purifying_slot):
					_purifying_state = JobState.COMPLETE
				else:
					_purifying_state = JobState.INTERRUPTED
	return advanced


func is_cooking_complete() -> bool:
	return _cooking_state == JobState.COMPLETE


func is_cooking_interrupted() -> bool:
	return _cooking_state == JobState.INTERRUPTED


func is_purifying_complete() -> bool:
	return _purifying_state == JobState.COMPLETE


func is_purifying_interrupted() -> bool:
	return _purifying_state == JobState.INTERRUPTED


func get_cooking_state() -> JobState:
	return _cooking_state


func get_purifying_state() -> JobState:
	return _purifying_state


func create_snapshot() -> Dictionary:
	return {
		"format_version": 1,
		"cooking_state": int(_cooking_state),
		"cooking_remaining": _cooking_remaining,
		"cooking_slot": _cooking_slot,
		"purifying_state": int(_purifying_state),
		"purifying_remaining": _purifying_remaining,
		"purifying_slot": _purifying_slot,
	}


func restore_snapshot(snapshot: Dictionary, inventory: Object) -> bool:
	if inventory == null or int(snapshot.get("format_version", -1)) != 1:
		return false
	var cooking_state: int = int(snapshot.get("cooking_state", -1))
	var purifying_state: int = int(snapshot.get("purifying_state", -1))
	if cooking_state < JobState.IDLE or cooking_state > JobState.INTERRUPTED \
		or purifying_state < JobState.IDLE or purifying_state > JobState.INTERRUPTED:
		return false
	var cooking_remaining: float = float(snapshot.get("cooking_remaining", 0.0))
	var purifying_remaining: float = float(snapshot.get("purifying_remaining", 0.0))
	if not is_finite(cooking_remaining) or not is_finite(purifying_remaining) \
		or cooking_remaining < 0.0 or purifying_remaining < 0.0:
		return false
	var cooking_slot: int = int(snapshot.get("cooking_slot", -1))
	var purifying_slot: int = int(snapshot.get("purifying_slot", -1))
	if cooking_state == JobState.RUNNING and inventory.get_stack_at(cooking_slot) == null:
		return false
	if purifying_state == JobState.RUNNING and inventory.get_container_snapshot_at(purifying_slot).is_empty():
		return false
	_inventory = inventory
	_cooking_state = cooking_state as JobState
	_cooking_remaining = cooking_remaining
	_cooking_slot = cooking_slot
	_purifying_state = purifying_state as JobState
	_purifying_remaining = purifying_remaining
	_purifying_slot = purifying_slot
	return true


func _finish_cooking() -> void:
	var catalog: RefCounted = ITEM_CATALOG_SCRIPT.new()
	var cooked_meat: ItemData = catalog.get_item(&"cooked_meat")
	if _inventory.add_quantity(cooked_meat, 1):
		_cooking_state = JobState.COMPLETE
	else:
		_interrupt_cooking()
	_cooking_remaining = 0.0


func _interrupt_cooking() -> void:
	var catalog: RefCounted = ITEM_CATALOG_SCRIPT.new()
	var raw_meat: ItemData = catalog.get_item(&"raw_meat")
	_inventory.add_quantity(raw_meat, 1)
	_cooking_state = JobState.INTERRUPTED
	_cooking_remaining = 0.0
