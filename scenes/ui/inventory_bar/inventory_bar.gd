extends Control

## 5 格物品栏 UI
## 监听 Inventory 信号动态刷新，选中槽位用 modulate 高亮

const SLOT_SIZE: Vector2 = Vector2(64, 64)
const UNSELECTED_MODULATE: Color = Color(0.55, 0.55, 0.55, 1.0)
const SELECTED_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)

@onready var slots_container: HBoxContainer = $Slots

var _slots: Array[Panel] = []
var _icons: Array[TextureRect] = []


func _ready() -> void:
	_build_slots()
	Inventory.inventory_changed.connect(_on_inventory_changed)
	Inventory.selected_slot_changed.connect(_on_selected_changed)
	# 初始化 UI
	_on_inventory_changed(Inventory.get_items())
	_on_selected_changed(Inventory.get_selected_slot())


func _build_slots() -> void:
	for i in range(Inventory.SLOT_COUNT):
		var slot := Panel.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# 槽位编号（左上角小标签）
		var label := Label.new()
		label.text = str(i + 1)
		label.position = Vector2(4, 0)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 12)
		slot.add_child(label)

		# 物品图标
		var icon := TextureRect.new()
		icon.anchor_right = 1.0
		icon.anchor_bottom = 1.0
		icon.offset_left = 4.0
		icon.offset_top = 4.0
		icon.offset_right = -4.0
		icon.offset_bottom = -4.0
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)

		slots_container.add_child(slot)
		_slots.append(slot)
		_icons.append(icon)


func _on_inventory_changed(items: Array) -> void:
	for i in range(Inventory.SLOT_COUNT):
		var item: ItemData = items[i] if i < items.size() else null
		var icon: TextureRect = _icons[i]
		if item != null and item.icon != null:
			icon.texture = item.icon
			icon.visible = true
		else:
			icon.texture = null
			icon.visible = false


func _on_selected_changed(slot_index: int) -> void:
	for i in range(Inventory.SLOT_COUNT):
		_slots[i].modulate = SELECTED_MODULATE if i == slot_index else UNSELECTED_MODULATE