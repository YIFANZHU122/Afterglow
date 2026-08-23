extends CanvasLayer
class_name RewardSelection

const UPGRADE_DEFINITION_SCRIPT: Script = preload("res://scripts/data/upgrade_definition.gd")

@export var damage_upgrade: Resource
@export var move_speed_upgrade: Resource

@onready var panel: Control = $Panel
@onready var damage_button: Button = $Panel/DamageButton
@onready var move_speed_button: Button = $Panel/MoveSpeedButton

var _choice_submitted: bool = false


func _ready() -> void:
	damage_button.pressed.connect(func() -> void: choose_upgrade(&"damage"))
	move_speed_button.pressed.connect(func() -> void: choose_upgrade(&"move_speed"))
	visible = false
	GameManager.run_state_changed.connect(_on_run_state_changed)
	_on_run_state_changed(GameManager.get_run_state(), GameManager.get_floor_number())


func choose_upgrade(choice: StringName) -> bool:
	if _choice_submitted or not visible or not GameManager.is_objective_complete() or GameManager.is_floor_clear():
		return false
	var definition: Resource
	match choice:
		&"damage":
			definition = damage_upgrade
		&"move_speed":
			definition = move_speed_upgrade
		_:
			return false
	if definition == null or definition.get_script() != UPGRADE_DEFINITION_SCRIPT:
		return false
	if not GameManager.apply_run_upgrade(definition):
		return false
	_choice_submitted = true
	visible = false
	return true


func _on_run_state_changed(_state: int, _floor_number: int) -> void:
	if GameManager.is_preparing_floor():
		_choice_submitted = false
		visible = false
	if GameManager.is_objective_complete() and not GameManager.is_floor_clear() and not _choice_submitted:
		visible = true
