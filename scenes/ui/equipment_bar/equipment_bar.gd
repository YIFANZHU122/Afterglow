extends Control

## 四槽装备操作条；只发出卸装意图，不直接修改角色构筑。

signal unequip_requested(slot: int)

const SLOT_NAMES: Array[String] = ["头", "甲", "裤", "包"]

@onready var slots: HBoxContainer = $Slots
@onready var status: Label = $Status

var _buttons: Array[Button] = []


func _ready() -> void:
	_build_slots()
	refresh(PackedStringArray(["", "", "", ""]), 0.0)


func _build_slots() -> void:
	for slot: int in SLOT_NAMES.size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(82.0, 46.0)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(func() -> void: unequip_requested.emit(slot))
		slots.add_child(button)
		_buttons.append(button)


func refresh(equipment_names: PackedStringArray, remaining_seconds: float) -> void:
	for slot: int in _buttons.size():
		var item_name: String = equipment_names[slot] if slot < equipment_names.size() else ""
		_buttons[slot].text = "%s\n%s" % [SLOT_NAMES[slot], item_name if not item_name.is_empty() else "空"]
		_buttons[slot].disabled = item_name.is_empty()
		_buttons[slot].tooltip_text = "点击并站定 2 秒卸下%s" % SLOT_NAMES[slot] if not item_name.is_empty() else "该槽位为空"
	if status != null:
		status.text = "换装中 %.1f 秒" % remaining_seconds if remaining_seconds > 0.0 else ""
