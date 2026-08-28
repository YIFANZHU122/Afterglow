extends WorldSceneController

## 第六层终局核心灰盒：场景负责组装 Boss、环境装置、HUD 和最终出口。

@onready var boss_label: Label = $BossHUD/BossLabel


func _ready() -> void:
	super._ready()
	if not GameManager.boss_progress_changed.is_connected(_on_boss_progress_changed):
		GameManager.boss_progress_changed.connect(_on_boss_progress_changed)
	var boss: Node = get_node_or_null("BossCore")
	if boss != null and boss.has_method("sync_health_from_game_manager"):
		boss.call("sync_health_from_game_manager")
	_update_boss_label()


func _on_boss_progress_changed(
	_phase: int,
	_health: float,
	_completion_route: int,
	_components: int,
	_devices: int
) -> void:
	_update_boss_label()


func _update_boss_label() -> void:
	if boss_label == null:
		return
	var phase: int = GameManager.get_boss_phase()
	var route: int = GameManager.get_boss_completion_route()
	var route_text: String = "战斗" if route == 1 else "环境" if route == 2 else "未结算"
	boss_label.text = "终局核心  阶段 %d  生命 %.0f\n环境组件 %d/3  装置 %d/3  路线 %s" % [
		phase + 1,
		GameManager.get_boss_health(),
		GameManager.get_boss_collected_component_count(),
		GameManager.get_boss_activated_device_count(),
		route_text,
	]


func _get_world_size() -> Vector2:
	return Vector2(2560.0, 1440.0)
