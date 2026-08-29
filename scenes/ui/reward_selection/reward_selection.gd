extends CanvasLayer
class_name RewardSelection

const UPGRADE_DEFINITION_SCRIPT: Script = preload("res://scripts/data/upgrade_definition.gd")
const QUALITY_COLORS: Array[Color] = [
	Color(0.78, 0.82, 0.84, 1.0),
	Color(0.45, 0.75, 1.0, 1.0),
	Color(0.82, 0.55, 1.0, 1.0),
	Color(1.0, 0.78, 0.32, 1.0),
]

@export var damage_upgrade: Resource
@export var move_speed_upgrade: Resource
@export var max_stamina_upgrade: Resource
@export var stamina_regen_upgrade: Resource
@export var survival_efficiency_upgrade: Resource
@export var luck_upgrade: Resource

@onready var candidate_buttons: Array[Button] = [
	$Panel/Candidate0,
	$Panel/Candidate1,
	$Panel/Candidate2,
	$Panel/Candidate3,
]
@onready var reroll_button: Button = $Panel/RerollButton
@onready var luck_label: Label = $Panel/LuckLabel
@onready var build_label: Label = $Panel/BuildLabel

var _choice_submitted: bool = false
var _candidates: Array[Dictionary] = []
var _resource_by_id: Dictionary = {}


func _ready() -> void:
	_resource_by_id = {
		&"damage": damage_upgrade,
		&"move_speed": move_speed_upgrade,
		&"max_stamina": max_stamina_upgrade,
		&"stamina_regen": stamina_regen_upgrade,
		&"survival_efficiency": survival_efficiency_upgrade,
		&"luck": luck_upgrade,
	}
	for index: int in candidate_buttons.size():
		candidate_buttons[index].pressed.connect(_on_candidate_pressed.bind(index))
	reroll_button.pressed.connect(_on_reroll_pressed)
	visible = false
	GameManager.run_state_changed.connect(_on_run_state_changed)
	GameManager.run_build_changed.connect(_on_run_build_changed)
	_on_run_state_changed(GameManager.get_run_state(), GameManager.get_floor_number())


func choose_upgrade(choice: StringName) -> bool:
	if _choice_submitted or not visible or not GameManager.is_objective_complete() or GameManager.is_floor_clear():
		return false
	var definition: Resource = _resource_by_id.get(choice) as Resource
	if definition == null or definition.get_script() != UPGRADE_DEFINITION_SCRIPT:
		return false
	var candidate: Dictionary = _find_candidate(choice)
	var quality_multiplier: float = float(candidate.get("multiplier", 1.0))
	var quality: int = int(candidate.get("quality", UPGRADE_DEFINITION_SCRIPT.Quality.COMMON))
	# Legacy callers can still choose a known resource directly; UI clicks always use a generated candidate.
	if candidate.is_empty():
		quality_multiplier = 1.0
		quality = UPGRADE_DEFINITION_SCRIPT.Quality.COMMON
	if not GameManager.apply_run_upgrade(definition, quality_multiplier, quality):
		return false
	_choice_submitted = true
	visible = false
	_candidates.clear()
	return true


func _on_candidate_pressed(index: int) -> void:
	if index < 0 or index >= _candidates.size():
		return
	choose_upgrade(StringName(_candidates[index].get("id", "")))


func _on_reroll_pressed() -> void:
	if _choice_submitted or not visible or not GameManager.consume_run_buff_reroll():
		return
	_generate_candidates()


func _on_run_state_changed(_state: int, _floor_number: int) -> void:
	if GameManager.is_preparing_floor():
		_choice_submitted = false
		_candidates.clear()
		visible = false
	if GameManager.is_objective_complete() and not GameManager.is_floor_clear() and not _choice_submitted:
		visible = true
		if _candidates.is_empty():
			_generate_candidates()


func _on_run_build_changed(_damage_multiplier: float, _move_speed_multiplier: float) -> void:
	_update_build_summary()


func _generate_candidates() -> void:
	var ids: Array[StringName] = []
	for raw_id: Variant in _resource_by_id.keys():
		var buff_id := StringName(raw_id)
		if _resource_by_id[raw_id] != null:
			ids.append(buff_id)
	_candidates = GameManager.refresh_run_buff_candidates(ids, candidate_buttons.size())
	for index: int in candidate_buttons.size():
		var button := candidate_buttons[index]
		button.disabled = index >= _candidates.size()
		button.text = ""
		button.remove_theme_color_override("font_color")
		if index >= _candidates.size():
			continue
		var candidate: Dictionary = _candidates[index]
		var buff_id := StringName(candidate.get("id", ""))
		var definition: Resource = _resource_by_id.get(buff_id) as Resource
		var quality: int = clampi(int(candidate.get("quality", 0)), 0, QUALITY_COLORS.size() - 1)
		var stack: int = GameManager.get_run_upgrade_stack(buff_id)
		button.text = "%s  %s\n%s\n%s  +%d" % [
			candidate.get("quality_name", "普通"),
			definition.get("display_name") if definition != null else String(buff_id),
			definition.get("description") if definition != null else "",
			"已有次数" if stack > 0 else "首次获得",
			stack + 1,
		]
		button.add_theme_color_override("font_color", QUALITY_COLORS[quality])
	_update_build_summary()


func _find_candidate(buff_id: StringName) -> Dictionary:
	for candidate: Dictionary in _candidates:
		if StringName(candidate.get("id", "")) == buff_id:
			return candidate
	return {}


func _update_build_summary() -> void:
	if luck_label != null:
		luck_label.text = "本局幸运 %.2f   可刷新 %d 次" % [GameManager.get_run_luck(), GameManager.get_run_reroll_charges()]
	if build_label != null:
		var summary_parts: Array[String] = []
		for item: Dictionary in GameManager.get_run_buff_summary():
			summary_parts.append("%s +%d" % [String(item.get("id", "")), int(item.get("stack", 0))])
		build_label.text = "当前构筑  " + ("、".join(summary_parts) if not summary_parts.is_empty() else "暂无")
	if reroll_button != null:
		reroll_button.disabled = GameManager.get_run_reroll_charges() <= 0
