extends WorldSceneController

## 地下室场景（1280×720）。遭遇由区域配置和 EncounterController 组装。

@export var area_config: Resource

@onready var encounter_controller: Node = $EncounterController
@onready var content_root: Node2D = $ContentRoot
@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel


func _ready() -> void:
	super._ready()
	if area_config == null:
		push_warning("[Basement] area_config is missing")
		return
	encounter_controller.progress_changed.connect(_on_progress_changed)
	encounter_controller.reward_earned.connect(_on_reward_earned)
	encounter_controller.completed.connect(_on_encounter_completed)
	GameManager.run_state_changed.connect(_on_run_state_changed)
	encounter_controller.start(area_config.get("encounter"), content_root)
	_update_objective_label(0, encounter_controller.get_target_count())


func _on_reward_earned(reward_xp: int) -> void:
	GameManager.add_run_xp(reward_xp)
	_update_objective_label(encounter_controller.get_completed_count(), encounter_controller.get_target_count())


func _on_progress_changed(completed_count: int, target_count: int) -> void:
	_update_objective_label(completed_count, target_count)


func _on_encounter_completed() -> void:
	GameManager.complete_objective()
	_update_objective_label(encounter_controller.get_completed_count(), encounter_controller.get_target_count())


func _on_run_state_changed(_state: int, _floor_number: int) -> void:
	_update_objective_label(encounter_controller.get_completed_count(), encounter_controller.get_target_count())


func _update_objective_label(completed_count: int, target_count: int) -> void:
	if objective_label == null:
		return
	var is_complete: bool = completed_count >= target_count
	var is_floor_clear: bool = GameManager.is_floor_clear()
	var status: String = "可前往出口" if is_floor_clear else "选择强化" if is_complete else "击败全部敌人"
	objective_label.text = "区域目标  %d/%d  %s\n本局等级 %d  XP %d  距升级 %d" % [
		completed_count,
		target_count,
		status,
		GameManager.get_run_level(),
		GameManager.get_run_xp(),
		GameManager.get_run_xp_to_next_level(),
	]

func _get_world_size() -> Vector2:
	return Vector2(1280.0, 720.0)
