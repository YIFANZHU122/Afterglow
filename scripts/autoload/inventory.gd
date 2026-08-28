extends Node

const ITEM_DATA_SCRIPT: Script = preload("res://scripts/item_data.gd")
const INVENTORY_MODEL_SCRIPT: Script = preload("res://scripts/items/inventory_model.gd")

## 全局物品栏系统（Autoload 单例）
## 5 格物品栏，跨场景持久；提供 add/select/cycle API，并通过信号通知 UI 更新

const SLOT_COUNT: int = 5

## 物品栏变化信号（items: 当前所有物品数组，空位为 null）
signal inventory_changed(items: Array)
## 选中槽位变化信号（slot_index: 0~SLOT_COUNT-1）
signal selected_slot_changed(slot_index: int)

# 物品数组（null 表示空槽位）
var _model: InventoryModel


func _ready() -> void:
	_model = INVENTORY_MODEL_SCRIPT.new(SLOT_COUNT)


## 添加物品到第一个空槽位；返回 true 表示添加成功，false 表示物品栏已满
func add_item(item: ItemData) -> bool:
	if _model == null or not _model.add_item(item):
		return false
	inventory_changed.emit(_model.get_items())
	return true


## 当前选中的物品（没有选中物品或选中槽为空时返回 null）
func get_selected_item() -> ItemData:
	return _model.get_selected_item()


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


## 移除选中槽位的物品并返回（丢弃用）；空槽返回 null
func drop_selected() -> ItemData:
	if _model == null:
		return null
	var item: ItemData = _model.drop_selected()
	if item == null:
		return null
	inventory_changed.emit(_model.get_items())
	return item


## 清空物品栏，返回所有被移除的物品列表（死亡掉落用）
func drop_all() -> Array:
	if _model == null:
		return []
	var dropped: Array = _model.drop_all()
	inventory_changed.emit(_model.get_items())
	return dropped


func create_snapshot() -> Dictionary:
	return _model.create_snapshot() if _model != null else {}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if _model == null or not _model.restore_snapshot(snapshot):
		return false
	inventory_changed.emit(_model.get_items())
	selected_slot_changed.emit(_model.get_selected_slot())
	return true
