extends Control
class_name StartScreen

const BASEMENT_SCENE_PATH: String = "res://scenes/world/basement/basement.tscn"

@onready var menu: VBoxContainer = $Menu
@onready var growth_panel: Panel = $GrowthPanel
@onready var difficulty_option: OptionButton = $Menu/DifficultyOption
@onready var start_button: Button = $Menu/StartButton
@onready var continue_button: Button = $Menu/ContinueButton
@onready var growth_button: Button = $Menu/GrowthButton
@onready var character_button: Button = $Menu/CharacterButton
@onready var quit_button: Button = $Menu/QuitButton
@onready var meta_label: Label = $GrowthPanel/MetaLabel
@onready var growth_status: Label = $GrowthPanel/Status
@onready var damage_growth_button: Button = $GrowthPanel/DamageGrowthButton
@onready var speed_growth_button: Button = $GrowthPanel/SpeedGrowthButton
@onready var stamina_growth_button: Button = $GrowthPanel/StaminaGrowthButton
@onready var regen_growth_button: Button = $GrowthPanel/RegenGrowthButton
@onready var survival_growth_button: Button = $GrowthPanel/SurvivalGrowthButton
@onready var luck_growth_button: Button = $GrowthPanel/LuckGrowthButton
@onready var reroll_growth_button: Button = $GrowthPanel/RerollGrowthButton
@onready var back_button: Button = $GrowthPanel/BackButton
@onready var character_panel: Panel = $CharacterPanel
@onready var attribute_label: Label = $CharacterPanel/AttributeLabel
@onready var intelligence_button: Button = $CharacterPanel/IntelligenceButton
@onready var strength_button: Button = $CharacterPanel/StrengthButton
@onready var vitality_button: Button = $CharacterPanel/VitalityButton
@onready var confirm_attributes_button: Button = $CharacterPanel/ConfirmButton
@onready var character_back_button: Button = $CharacterPanel/BackButton

var _selected_difficulty: int = 0


func _ready() -> void:
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	growth_button.pressed.connect(_show_growth)
	character_button.pressed.connect(_show_character)
	quit_button.pressed.connect(_on_quit_pressed)
	damage_growth_button.pressed.connect(_purchase_damage_growth)
	speed_growth_button.pressed.connect(_purchase_speed_growth)
	stamina_growth_button.pressed.connect(_purchase_stamina_growth)
	regen_growth_button.pressed.connect(_purchase_regen_growth)
	survival_growth_button.pressed.connect(_purchase_survival_growth)
	luck_growth_button.pressed.connect(_purchase_luck_growth)
	reroll_growth_button.pressed.connect(_purchase_reroll_growth)
	back_button.pressed.connect(_hide_growth)
	intelligence_button.pressed.connect(func() -> void: _allocate_character(0))
	strength_button.pressed.connect(func() -> void: _allocate_character(1))
	vitality_button.pressed.connect(func() -> void: _allocate_character(2))
	confirm_attributes_button.pressed.connect(_confirm_character)
	character_back_button.pressed.connect(_hide_character)
	GameManager.meta_progression_changed.connect(_on_meta_progression_changed)
	_refresh_menu()
	_hide_growth()
	_hide_character()


func _on_difficulty_selected(index: int) -> void:
	_selected_difficulty = clampi(index, 0, 2)
	GameManager.set_run_difficulty(_selected_difficulty)


func _on_start_pressed() -> void:
	if not GameManager.start_run(_selected_difficulty):
		_set_status("无法开始新局，请确认当前没有正在进行的运行。")
		return
	GameManager.change_scene(BASEMENT_SCENE_PATH, "PlayerSpawn")


func _on_continue_pressed() -> void:
	if not GameManager.has_valid_run_snapshot():
		_set_status("没有可继续的安全退出存档。")
		_refresh_menu()
		return
	if not GameManager.restore_safe_exit_to_scene():
		_set_status("安全退出存档无法恢复，已保留在主菜单。")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _show_growth() -> void:
	menu.visible = false
	character_panel.visible = false
	growth_panel.visible = true
	_refresh_growth()


func _hide_growth() -> void:
	growth_panel.visible = false
	menu.visible = true
	_refresh_menu()


func _show_character() -> void:
	menu.visible = false
	growth_panel.visible = false
	character_panel.visible = true
	_refresh_character()


func _hide_character() -> void:
	character_panel.visible = false
	menu.visible = true
	_refresh_menu()


func _allocate_character(attribute: int) -> void:
	if not GameManager.allocate_character_attribute(attribute, 1):
		_set_character_status("无法分配：点数不足、属性已达上限或已确认。")
	_refresh_character()


func _confirm_character() -> void:
	if not GameManager.confirm_character_attributes():
		_set_character_status("请先分配完全部属性点。")
	else:
		_set_character_status("本局属性已确认，进入地图后不可修改。")
	_refresh_character()


func _refresh_character() -> void:
	if not is_node_ready():
		return
	var intelligence: int = GameManager.get_character_attribute_value(0)
	var strength: int = GameManager.get_character_attribute_value(1)
	var vitality: int = GameManager.get_character_attribute_value(2)
	var remaining: int = GameManager.get_character_attribute_points_remaining()
	attribute_label.text = "结晶阶级 %d  (+%d点)\n剩余点数  %d\n智力  %d   力量  %d   体力  %d" % [
		GameManager.get_meta_crystal_tier(),
		GameManager.get_meta_attribute_point_bonus(),
		remaining,
		intelligence,
		strength,
		vitality,
	]
	var confirmed: bool = GameManager.are_character_attributes_confirmed()
	intelligence_button.disabled = confirmed or remaining <= 0
	strength_button.disabled = confirmed or remaining <= 0
	vitality_button.disabled = confirmed or remaining <= 0
	confirm_attributes_button.disabled = confirmed or remaining > 0


func _set_character_status(message: String) -> void:
	if character_panel != null:
		character_panel.get_node("Status").text = message


func _purchase_damage_growth() -> void:
	if not GameManager.purchase_initial_buff(&"damage", 10):
		_set_status("局外结晶不足。")
		return
	GameManager.equip_initial_buff(&"damage")
	_refresh_growth()


func _purchase_speed_growth() -> void:
	if not GameManager.purchase_initial_buff(&"move_speed", 10):
		_set_status("局外结晶不足。")
		return
	GameManager.equip_initial_buff(&"move_speed")
	_refresh_growth()


func _purchase_stamina_growth() -> void:
	_purchase_initial_buff(&"max_stamina")


func _purchase_regen_growth() -> void:
	_purchase_initial_buff(&"stamina_regen")


func _purchase_survival_growth() -> void:
	_purchase_initial_buff(&"survival_efficiency")


func _purchase_luck_growth() -> void:
	_purchase_initial_buff(&"luck")


func _purchase_initial_buff(buff_id: StringName) -> void:
	if not GameManager.purchase_initial_buff(buff_id, 10):
		_set_status("局外结晶不足。")
		return
	GameManager.equip_initial_buff(buff_id)
	_refresh_growth()


func _purchase_reroll_growth() -> void:
	if not GameManager.purchase_reroll_level(15):
		_set_status("局外结晶不足，或刷新能力已达到上限。")
		return
	_refresh_growth()


func _on_meta_progression_changed(_crystals: int, _equipped: StringName, _reroll_level: int) -> void:
	_refresh_growth()
	_refresh_menu()


func _refresh_menu() -> void:
	if not is_node_ready():
		return
	continue_button.disabled = not GameManager.has_valid_run_snapshot()
	if difficulty_option.selected != _selected_difficulty:
		difficulty_option.select(_selected_difficulty)


func _refresh_growth() -> void:
	if not is_node_ready():
		return
	var equipped := GameManager.get_equipped_initial_buff()
	var equipped_text := "未装备" if equipped.is_empty() else String(equipped)
	meta_label.text = "局外结晶  %d\n初始 Buff  %s\n刷新能力  Lv.%d/%d" % [
		GameManager.get_meta_crystals(),
		equipped_text,
		GameManager.get_meta_reroll_level(),
		5,
	]
	damage_growth_button.text = "强化 强袭  Lv.%d  (10结晶)" % GameManager.get_initial_buff_level(&"damage")
	speed_growth_button.text = "强化 疾行  Lv.%d  (10结晶)" % GameManager.get_initial_buff_level(&"move_speed")
	stamina_growth_button.text = "强化 活力  Lv.%d  (10结晶)" % GameManager.get_initial_buff_level(&"max_stamina")
	regen_growth_button.text = "强化 呼吸  Lv.%d  (10结晶)" % GameManager.get_initial_buff_level(&"stamina_regen")
	survival_growth_button.text = "强化 节制  Lv.%d  (10结晶)" % GameManager.get_initial_buff_level(&"survival_efficiency")
	luck_growth_button.text = "强化 幸运  Lv.%d  (10结晶)" % GameManager.get_initial_buff_level(&"luck")
	reroll_growth_button.text = "强化刷新  Lv.%d  (15结晶)" % GameManager.get_meta_reroll_level()


func _set_status(message: String) -> void:
	if growth_status != null:
		growth_status.text = message
