extends WorldSceneController

## 慈航郊外连续荒野场景（5760×3240）。
## 场景加载时定位玩家出生点，并设置相机边界（由场景尺寸决定，而非硬编码在玩家场景中）。

const OBJECTIVE_TITLE: String = "区域目标  慈航郊外"
const OBJECTIVE_DESCRIPTION: String = "生存并探索荒野，寻找安全路线"

@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel


func _ready() -> void:
	super._ready()
	if GameManager.has_signal("run_state_changed"):
		GameManager.run_state_changed.connect(_on_run_state_changed)
	_update_objective_label()


func _on_run_state_changed(_state: int, _floor_number: int) -> void:
	_update_objective_label()


func _update_objective_label() -> void:
	if objective_label == null:
		return
	var floor_number: int = GameManager.get_floor_number()
	var phase_text: String = "夜晚，避开迷雾" if GameManager.is_floor_night() else "白天，搜集资源并前进"
	objective_label.text = "%s\n%s\n第 %d 层  %s" % [OBJECTIVE_TITLE, OBJECTIVE_DESCRIPTION, floor_number, phase_text]


func _get_world_size() -> Vector2:
	return Vector2(5760.0, 3240.0)
