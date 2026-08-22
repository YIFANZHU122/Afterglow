extends RefCounted
class_name PlayerInputAdapter

const PLAYER_COMMAND_SCRIPT: Script = preload("res://scripts/player/player_command.gd")

const MOVE_LEFT_ACTION: StringName = &"move_left"
const MOVE_RIGHT_ACTION: StringName = &"move_right"
const MOVE_UP_ACTION: StringName = &"move_up"
const MOVE_DOWN_ACTION: StringName = &"move_down"
const SPRINT_ACTION: StringName = &"sprint"
const ATTACK_ACTION: StringName = &"attack"
const CYCLE_PREV_ACTION: StringName = &"cycle_prev"
const CYCLE_NEXT_ACTION: StringName = &"cycle_next"
const DROP_ACTION: StringName = &"drop"


func collect_command() -> PlayerCommand:
	var cycle_delta: int = 0
	var previous_pressed: bool = Input.is_action_just_pressed(CYCLE_PREV_ACTION)
	var next_pressed: bool = Input.is_action_just_pressed(CYCLE_NEXT_ACTION)
	if previous_pressed != next_pressed:
		cycle_delta = -1 if previous_pressed else 1

	return PLAYER_COMMAND_SCRIPT.new(
		Input.get_vector(MOVE_LEFT_ACTION, MOVE_RIGHT_ACTION, MOVE_UP_ACTION, MOVE_DOWN_ACTION),
		Input.is_action_pressed(SPRINT_ACTION),
		Input.is_action_just_pressed(ATTACK_ACTION),
		cycle_delta,
		_get_selected_slot(),
		Input.is_action_just_pressed(DROP_ACTION)
	)


func _get_selected_slot() -> int:
	for slot_index in range(5):
		if Input.is_action_just_pressed(&"slot_%d" % (slot_index + 1)):
			return slot_index
	return PlayerCommand.NO_SELECTED_SLOT
