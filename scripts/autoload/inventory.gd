extends Node

const ITEM_DATA_SCRIPT: Script = preload("res://scripts/item_data.gd")
const INVENTORY_MODEL_SCRIPT: Script = preload("res://scripts/items/inventory_model.gd")
const ITEM_CATALOG_SCRIPT: Script = preload("res://scripts/items/item_catalog.gd")

## 全局物品栏系统（Autoload 单例）
## 8 格物品栏，跨场景持久；提供 add/select/cycle API，并通过信号通知 UI 更新

const SLOT_COUNT: int = 8

## 物品栏变化信号（items: 当前所有物品数组，空位为 null）
signal inventory_changed(stacks: Array)
## 选中槽位变化信号（slot_index: 0~SLOT_COUNT-1）
signal selected_slot_changed(slot_index: int)

# 物品数组（null 表示空槽位）
var _model: InventoryModel


func _ready() -> void:
	_model = INVENTORY_MODEL_SCRIPT.new(SLOT_COUNT, ITEM_CATALOG_SCRIPT.new())


## 添加物品到第一个空槽位；返回 true 表示添加成功，false 表示物品栏已满
func add_item(item: ItemData) -> bool:
	if _model == null or not _model.add_item(item):
		return false
	inventory_changed.emit(_model.get_stacks())
	return true


func add_quantity(item: ItemData, quantity: int) -> bool:
	if _model == null or not _model.add_quantity(item, quantity):
		return false
	inventory_changed.emit(_model.get_stacks())
	return true


func can_craft(recipe: Resource) -> bool:
	return _model != null and _model.can_craft(recipe)


func remove_quantity(item: ItemData, quantity: int) -> bool:
	if _model == null or not _model.remove_quantity(item, quantity):
		return false
	inventory_changed.emit(_model.get_stacks())
	return true


func damage_selected_durability(amount: int = 1) -> bool:
	if _model == null or not _model.damage_selected_durability(amount):
		return false
	inventory_changed.emit(_model.get_stacks())
	return true


func can_add_quantity(item: ItemData, quantity: int) -> bool:
	return _model != null and _model.can_add_quantity(item, quantity)


func consume_selected(quantity: int = 1) -> bool:
	if _model == null or not _model.consume_selected(quantity):
		return false
	inventory_changed.emit(_model.get_stacks())
	return true


func get_selected_container_snapshot() -> Dictionary:
	return _model.get_selected_container_snapshot() if _model != null else {}


func get_container_snapshot_at(slot_index: int) -> Dictionary:
	return _model.get_container_snapshot_at(slot_index) if _model != null else {}


func fill_selected_container(source: int, amount: int = 1, purified: bool = false) -> bool:
	if _model == null or not _model.fill_selected_container(source, amount, purified):
		return false
	inventory_changed.emit(_model.get_stacks())
	return true


func consume_selected_water(amount: int = 1) -> bool:
	if _model == null or not _model.consume_selected_water(amount):
		return false
	inventory_changed.emit(_model.get_stacks())
	return true


func purify_selected_container() -> bool:
	if _model == null or not _model.purify_selected_container():
		return false
	inventory_changed.emit(_model.get_stacks())
	return true


func purify_container_at(slot_index: int) -> bool:
	if _model == null or not _model.purify_container_at(slot_index):
		return false
	inventory_changed.emit(_model.get_stacks())
	return true


func transfer_water(source_slot: int, target_slot: int, amount: int = 1) -> bool:
	if _model == null or not _model.transfer_water(source_slot, target_slot, amount):
		return false
	inventory_changed.emit(_model.get_stacks())
	return true


## 当前选中的物品（没有选中物品或选中槽为空时返回 null）
func get_selected_item() -> ItemData:
	return _model.get_selected_item()


func get_selected_stack() -> RefCounted:
	return _model.get_selected_stack() if _model != null else null


## 当前选中槽位索引（0~SLOT_COUNT-1）
func get_selected_slot() -> int:
	return _model.get_selected_slot()


## 通过索引直接选中某个槽位
func set_selected_slot(slot_index: int) -> void:
	if _model != null and _model.set_selected_slot(slot_index):
		selected_slot_changed.emit(_model.get_selected_slot())


## 滚轮切换（delta: +1 向后，-1 向前，循环）
func cycle_selected(delta: int) -> void:
	if _model != null and _model.cycle_selected(delta):
		selected_slot_changed.emit(_model.get_selected_slot())


## 获取所有物品的副本（用于 UI 显示）
func get_items() -> Array:
	return _model.get_items()


func get_stacks() -> Array:
	return _model.get_stacks()


func get_slot_count() -> int:
	return _model.get_slot_count() if _model != null else SLOT_COUNT


func configure_slot_count(slot_count: int) -> bool:
	if _model == null or not _model.configure_slot_count(slot_count):
		return false
	inventory_changed.emit(_model.get_stacks())
	selected_slot_changed.emit(_model.get_selected_slot())
	return true


func get_total_weight() -> float:
	return _model.get_total_weight() if _model != null else 0.0


func get_occupied_slot_count() -> int:
	return _model.get_occupied_slot_count() if _model != null else 0


## 移除选中槽位的物品并返回（丢弃用）；空槽返回 null
func drop_selected() -> RefCounted:
	if _model == null:
		return null
	var stack: RefCounted = _model.drop_selected()
	if stack == null:
		return null
	inventory_changed.emit(_model.get_stacks())
	return stack


## 清空物品栏，返回所有被移除的物品列表（死亡掉落用）
func drop_all() -> Array:
	if _model == null:
		return []
	var dropped: Array = _model.drop_all()
	inventory_changed.emit(_model.get_stacks())
	return dropped


func reset_for_new_run() -> bool:
	_model = INVENTORY_MODEL_SCRIPT.new(SLOT_COUNT, ITEM_CATALOG_SCRIPT.new())
	inventory_changed.emit(_model.get_stacks())
	selected_slot_changed.emit(_model.get_selected_slot())
	return true


func create_snapshot() -> Dictionary:
	return _model.create_snapshot() if _model != null else {}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if _model == null or not _model.restore_snapshot(snapshot):
		return false
	inventory_changed.emit(_model.get_stacks())
	selected_slot_changed.emit(_model.get_selected_slot())
	return true
