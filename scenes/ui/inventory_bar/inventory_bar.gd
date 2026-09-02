extends Control

## 8 格物品栏 UI
## 监听 Inventory 信号动态刷新，选中槽位用 modulate 高亮

const SLOT_SIZE: Vector2 = Vector2(64, 64)
const UNSELECTED_MODULATE: Color = Color(0.55, 0.55, 0.55, 1.0)
const SELECTED_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)

@onready var slots_container: HBoxContainer = $Slots
@onready var weight_label: Label = $Weight

var _slots: Array[Panel] = []
var _icons: Array[TextureRect] = []
var _quantities: Array[Label] = []


func _ready() -> void:
	_build_slots()
	Inventory.inventory_changed.connect(_on_inventory_changed)
	Inventory.selected_slot_changed.connect(_on_selected_changed)
	# 初始化 UI
	_on_inventory_changed(Inventory.get_stacks())
	_on_selected_changed(Inventory.get_selected_slot())


func _build_slots() -> void:
	for i in range(Inventory.get_slot_count()):
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

		var quantity := Label.new()
		quantity.anchor_left = 1.0
		quantity.anchor_top = 1.0
		quantity.anchor_right = 1.0
		quantity.anchor_bottom = 1.0
		quantity.offset_left = -28.0
		quantity.offset_top = -22.0
		quantity.offset_right = -4.0
		quantity.offset_bottom = -2.0
		quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quantity.add_theme_font_size_override("font_size", 14)
		quantity.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(quantity)

		slots_container.add_child(slot)
		_slots.append(slot)
		_icons.append(icon)
		_quantities.append(quantity)


func _on_inventory_changed(stacks: Array) -> void:
	_sync_slots()
	for i in range(Inventory.get_slot_count()):
		var stack: RefCounted = stacks[i] if i < stacks.size() else null
		var item: ItemData = stack.get_definition() if stack != null else null
		var icon: TextureRect = _icons[i]
		if item != null and item.icon != null:
			icon.texture = item.icon
			icon.visible = true
		else:
			icon.texture = null
			icon.visible = false
		_quantities[i].text = str(stack.get_quantity()) if stack != null and stack.get_quantity() > 1 else ""
	if weight_label != null:
		weight_label.text = "重量 %.1f" % Inventory.get_total_weight()


func _sync_slots() -> void:
	var slot_count: int = Inventory.get_slot_count()
	if slot_count == _slots.size():
		return
	for child: Node in slots_container.get_children():
		slots_container.remove_child(child)
		child.free()
	_slots.clear()
	_icons.clear()
	_quantities.clear()
	_build_slots()


func _on_selected_changed(slot_index: int) -> void:
	for i in range(_slots.size()):
		_slots[i].modulate = SELECTED_MODULATE if i == slot_index else UNSELECTED_MODULATE
