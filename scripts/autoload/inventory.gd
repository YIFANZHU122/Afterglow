extends Node

## 全局物品栏系统（Autoload 单例）
## 5 格物品栏，跨场景持久；提供 add/select/cycle API，并通过信号通知 UI 更新

const SLOT_COUNT: int = 5

## 物品栏变化信号（items: 当前所有物品数组，空位为 null）
signal inventory_changed(items: Array)
## 选中槽位变化信号（slot_index: 0~SLOT_COUNT-1）
signal selected_slot_changed(slot_index: int)

# 物品数组（null 表示空槽位）
var _items: Array = []
# 当前选中槽位（0 ~ SLOT_COUNT-1）
var _selected_slot: int = 0


func _ready() -> void:
	_items.resize(SLOT_COUNT)
	_items.fill(null)


## 添加物品到第一个空槽位；返回 true 表示添加成功，false 表示物品栏已满
func add_item(item: ItemData) -> bool:
	if item == null:
		return false
	for i in range(SLOT_COUNT):
		if _items[i] == null:
			_items[i] = item
			inventory_changed.emit(_items.duplicate())
			return true
	return false


## 当前选中的物品（没有选中物品或选中槽为空时返回 null）
func get_selected_item() -> ItemData:
	return _items[_selected_slot]


## 当前选中槽位索引（0~SLOT_COUNT-1）
func get_selected_slot() -> int:
	return _selected_slot


## 通过索引直接选中某个槽位
func set_selected_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return
	if _selected_slot == slot_index:
		return
	_selected_slot = slot_index
	selected_slot_changed.emit(_selected_slot)


## 滚轮切换（delta: +1 向后，-1 向前，循环）
func cycle_selected(delta: int) -> void:
	var new_slot: int = (_selected_slot + delta + SLOT_COUNT) % SLOT_COUNT
	set_selected_slot(new_slot)


## 获取所有物品的副本（用于 UI 显示）
func get_items() -> Array:
	return _items.duplicate()


## 移除选中槽位的物品并返回（丢弃用）；空槽返回 null
func drop_selected() -> ItemData:
	var item: ItemData = _items[_selected_slot]
	if item == null:
		return null
	_items[_selected_slot] = null
	inventory_changed.emit(_items.duplicate())
	return item


## 清空物品栏，返回所有被移除的物品列表（死亡掉落用）
func drop_all() -> Array:
	var dropped: Array = []
	for i in range(SLOT_COUNT):
		if _items[i] != null:
			dropped.append(_items[i])
			_items[i] = null
	inventory_changed.emit(_items.duplicate())
	return dropped