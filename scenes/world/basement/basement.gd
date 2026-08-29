extends WorldSceneController

## 地下室场景（2560×1440）。遭遇由区域配置和 EncounterController 组装。

@export var area_config: Resource

@onready var encounter_controller: Node = $EncounterController
@onready var content_root: Node2D = $ContentRoot
@onready var objective_label: Label = $ObjectiveHUD/ObjectiveStack/ObjectiveLabel
@onready var escape_label: Label = $ObjectiveHUD/ObjectiveStack/EscapeLabel
@onready var disaster_label: Label = $ObjectiveHUD/ObjectiveStack/DisasterLabel


func _ready() -> void:
	super._ready()
	if area_config == null:
		push_warning("[Basement] area_config is missing")
		return
	encounter_controller.progress_changed.connect(_on_progress_changed)
	encounter_controller.reward_earned.connect(_on_reward_earned)
	encounter_controller.completed.connect(_on_encounter_completed)
	GameManager.run_state_changed.connect(_on_run_state_changed)
	GameManager.escape_objective_changed.connect(_on_escape_objective_changed)
	GameManager.disaster_changed.connect(_on_disaster_changed)
	var allowed_disasters: Array[int] = [0, 1, 2, 3, 4, 5, 9]
	GameManager.configure_floor_disaster_kinds(allowed_disasters)
	_configure_encounter_protection()
	encounter_controller.start(area_config.get("encounter"), content_root)
	_update_objective_label(0, encounter_controller.get_target_count())
	_update_escape_label()
	_update_disaster_label()


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
	_update_escape_label()


func _on_escape_objective_changed(
	_parts: int,
	_fuel: int,
	_cloth: int,
	_key: int,
	_startup_seconds: float,
	_started: bool
) -> void:
	_update_escape_label()


func _on_disaster_changed(
	_kind: int,
	_phase: int,
	_remaining_seconds: float,
	_risk_level: int,
	_countermeasure_progress: float
) -> void:
	_update_disaster_label()


func _update_disaster_label() -> void:
	if disaster_label == null:
		return
	var kind: int = GameManager.get_primary_disaster_kind()
	if kind < 0:
		disaster_label.text = "灾难  无"
		return
	var phase: int = GameManager.get_primary_disaster_phase()
	var phase_text: String = "预警" if phase == 1 else "生效" if phase == 2 else "已解除"
	var name: String = _get_disaster_name(kind)
	var remaining: float = GameManager.get_primary_disaster_remaining_seconds()
	var progress: float = GameManager.get_primary_disaster_countermeasure_progress()
	var countermeasure_text: String = "主应对 %.1f/10.0  信号抑制器 @ 东侧维护区" % progress if kind >= 6 else "多种应对"
	disaster_label.text = "灾难  %s  %s  %.1f秒  风险%d  %s" % [
		name, phase_text, remaining, GameManager.get_primary_disaster_risk_level(), countermeasure_text
	]


func _get_disaster_name(kind: int) -> String:
	var names: Array[String] = ["暴雨", "烈日", "浓雾", "寒潮", "怪物狂潮", "刷新点迁移", "山洪决口", "毒雾封锁", "特殊怪入侵", "猎杀者"]
	return names[kind] if kind >= 0 and kind < names.size() else "未知灾难"


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


func _update_escape_label() -> void:
	if escape_label == null:
		return
	var parts: int = GameManager.get_escape_material_collected(0)
	var fuel: int = GameManager.get_escape_material_collected(1)
	var cloth: int = GameManager.get_escape_material_collected(2)
	var key: int = GameManager.get_escape_material_collected(3)
	var startup: float = GameManager.get_escape_startup_seconds()
	var status: String = "已启动" if GameManager.is_escape_exit_started() else "可启动" if GameManager.has_all_escape_materials() else "收集物资"
	escape_label.text = "逃生物资  零件 %d/2  燃料 %d/2  布料 %d/2  钥匙 %d/1\n出口启动 %.1f/10.0 秒  %s" % [
		parts, fuel, cloth, key, startup, status
	]

func _get_world_size() -> Vector2:
	return Vector2(2560.0, 1440.0)


func _configure_encounter_protection() -> void:
	var protected_points: Array[Vector2] = []
	for node_path: NodePath in [
		NodePath("PlayerSpawn"),
		NodePath("FromCihangSpawn"),
		NodePath("TransitionZone"),
		NodePath("EscapeParts0"),
		NodePath("EscapeParts4"),
		NodePath("EscapeFuel1"),
		NodePath("EscapeFuel5"),
		NodePath("EscapeCloth2"),
		NodePath("EscapeCloth6"),
		NodePath("EscapeKey3"),
		NodePath("SignalSuppressor"),
	]:
		var point_node: Node2D = get_node_or_null(node_path) as Node2D
		if point_node != null:
			protected_points.append(point_node.global_position / 40.0)
	encounter_controller.set_protected_points(protected_points)
