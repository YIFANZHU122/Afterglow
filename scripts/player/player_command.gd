extends RefCounted
class_name PlayerCommand

## 单帧玩家外部意图。
## 该模型不保存节点、位置、生命或背包状态，只描述输入来源希望执行的动作。

const NO_SELECTED_SLOT: int = -1

var move_direction: Vector2
var sprint_requested: bool
var attack_pressed: bool
var cycle_delta: int
var selected_slot: int
var drop_pressed: bool
var use_pressed: bool
var vault_pressed: bool
var dig_pressed: bool


func _init(
	move_direction_value: Vector2 = Vector2.ZERO,
	sprint_requested_value: bool = false,
	attack_pressed_value: bool = false,
	cycle_delta_value: int = 0,
	selected_slot_value: int = NO_SELECTED_SLOT,
	drop_pressed_value: bool = false,
	use_pressed_value: bool = false,
	vault_pressed_value: bool = false,
	dig_pressed_value: bool = false
) -> void:
	move_direction = move_direction_value.limit_length(1.0)
	sprint_requested = sprint_requested_value
	attack_pressed = attack_pressed_value
	cycle_delta = clampi(cycle_delta_value, -1, 1)
	selected_slot = selected_slot_value if selected_slot_value >= 0 else NO_SELECTED_SLOT
	drop_pressed = drop_pressed_value
	use_pressed = use_pressed_value
	vault_pressed = vault_pressed_value
	dig_pressed = dig_pressed_value
