extends RefCounted
class_name InteractionInputAdapter

const INTERACT_ACTION: StringName = &"interact"


func is_interact_pressed() -> bool:
	return Input.is_action_just_pressed(INTERACT_ACTION)
