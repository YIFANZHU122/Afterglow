extends CanvasLayer
class_name DebugController

## F1 调试面板：只驱动表现预览，不写入正式规则或存档。

const CHASER_SCENE: PackedScene = preload("res://scenes/objects/chaser_enemy/chaser_enemy.tscn")
const ENVIRONMENT_PRESENTER_PATH: NodePath = NodePath("WorldEnvironmentPresenter")

var _panel: PanelContainer
var _status_label: Label
var _weather_option: OptionButton
var _weather_strength: HSlider
var _disaster_option: OptionButton
var _preview_root: Node2D
var _preview_monsters: Array[Node2D] = []


func _ready() -> void:
	_preview_root = Node2D.new()
	_preview_root.name = "DebugPreviewRoot"
	_preview_root.z_index = 20
	get_parent().call_deferred("add_child", _preview_root)
	_build_panel()
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F1:
		toggle_panel()
		get_viewport().set_input_as_handled()


func toggle_panel() -> void:
	if _panel != null:
		_panel.visible = not _panel.visible
		_update_status()


func spawn_preview_monsters(count: int = 1) -> int:
	if _preview_root == null:
		return 0
	var player := get_parent().get_node_or_null("Player") as Node2D
	var origin: Vector2 = player.global_position if player != null else Vector2(640.0, 360.0)
	var spawned: int = 0
	for index in range(clampi(count, 1, 8)):
		var monster := CHASER_SCENE.instantiate() as Node2D
		if monster == null:
			continue
		monster.name = "DebugRiftAnimal%d" % (_preview_monsters.size() + 1)
		_preview_root.add_child(monster)
		monster.global_position = origin + Vector2(150.0 + (index % 4) * 72.0, -90.0 + (index / 4) * 120.0)
		monster.set_physics_process(false)
		var collision_shape := monster.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision_shape != null:
			collision_shape.disabled = true
		_preview_monsters.append(monster)
		spawned += 1
	_update_status()
	return spawned


func clear_preview_monsters() -> void:
	for monster: Node2D in _preview_monsters:
		if is_instance_valid(monster):
			monster.queue_free()
	_preview_monsters.clear()
	_update_status()


func preview_weather(mode: StringName, strength: float) -> void:
	var presenter := _get_environment_presenter()
	if presenter != null and presenter.has_method("present_weather_override"):
		presenter.call("present_weather_override", mode, strength)
	_update_status()


func trigger_disaster(kind: int, active: bool = true) -> bool:
	if not GameManager.has_method("start_disaster"):
		return false
	var started: bool = bool(GameManager.call("start_disaster", kind))
	if started and active and GameManager.has_method("advance_disasters"):
		GameManager.call("advance_disasters", 10.0)
	_update_status()
	return started


func clear_disasters() -> void:
	if GameManager.has_method("advance_disasters"):
		GameManager.call("advance_disasters", 10000.0)
	_update_status()


func preview_anomaly(anomaly_kind: int, intensity: float) -> void:
	var presenter := _get_environment_presenter()
	if presenter != null and presenter.has_method("present_anomaly"):
		presenter.call("present_anomaly", anomaly_kind, intensity)
	_update_status()


func preview_san(sanity_ratio: float) -> void:
	var presenter := _get_environment_presenter()
	if presenter != null and presenter.has_method("present_san"):
		presenter.call("present_san", sanity_ratio)
	_update_status()


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.name = "DebugPanel"
	_panel.position = Vector2(22.0, 188.0)
	_panel.size = Vector2(392.0, 500.0)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)
	var title := Label.new()
	title.text = "调试控制器  F1"
	title.add_theme_font_size_override("font_size", 20)
	column.add_child(title)
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status_label)
	column.add_child(_make_separator())
	column.add_child(_make_section_label("怪物预览"))
	var monster_row := HBoxContainer.new()
	monster_row.add_child(_make_button("刷 1 个裂口动物", func() -> void: spawn_preview_monsters(1)))
	monster_row.add_child(_make_button("刷 5 个", func() -> void: spawn_preview_monsters(5)))
	monster_row.add_child(_make_button("清除", clear_preview_monsters))
	column.add_child(monster_row)
	column.add_child(_make_separator())
	column.add_child(_make_section_label("天气预览"))
	_weather_option = OptionButton.new()
	for entry in [["晴天", &"clear"], ["暴雨", &"rainstorm"], ["烈日", &"heatwave"], ["浓雾", &"dense_fog"], ["寒潮", &"cold_snap"]]:
		_weather_option.add_item(entry[0])
		_weather_option.set_item_metadata(_weather_option.item_count - 1, entry[1])
	_weather_option.item_selected.connect(_on_weather_selected)
	column.add_child(_weather_option)
	_weather_strength = HSlider.new()
	_weather_strength.min_value = 0.0
	_weather_strength.max_value = 1.0
	_weather_strength.step = 0.05
	_weather_strength.value = 1.0
	_weather_strength.tooltip_text = "天气表现强度"
	_weather_strength.value_changed.connect(_on_weather_strength_changed)
	column.add_child(_weather_strength)
	column.add_child(_make_button("清除天气", func() -> void: preview_weather(&"clear", 0.0)))
	column.add_child(_make_separator())
	column.add_child(_make_section_label("真实灾难事件"))
	_disaster_option = OptionButton.new()
	for entry in [["暴雨", 0], ["烈日", 1], ["浓雾", 2], ["寒潮", 3], ["怪物狂潮", 4], ["猎杀者", 9]]:
		_disaster_option.add_item(entry[0])
		_disaster_option.set_item_metadata(_disaster_option.item_count - 1, entry[1])
	column.add_child(_disaster_option)
	var disaster_row := HBoxContainer.new()
	disaster_row.add_child(_make_button("预警", func() -> void: _trigger_selected_disaster(false)))
	disaster_row.add_child(_make_button("立即生效", func() -> void: _trigger_selected_disaster(true)))
	disaster_row.add_child(_make_button("解除全部", clear_disasters))
	column.add_child(disaster_row)
	column.add_child(_make_separator())
	column.add_child(_make_section_label("异常天象 / SAN"))
	var anomaly_row := HBoxContainer.new()
	anomaly_row.add_child(_make_button("异常月相", func() -> void: preview_anomaly(1, 0.8)))
	anomaly_row.add_child(_make_button("污染天象", func() -> void: preview_anomaly(2, 0.8)))
	anomaly_row.add_child(_make_button("天象裂口", func() -> void: preview_anomaly(3, 0.8)))
	column.add_child(anomaly_row)
	var san_row := HBoxContainer.new()
	san_row.add_child(_make_button("SAN 25%", func() -> void: preview_san(0.25)))
	san_row.add_child(_make_button("恢复正常", func() -> void:
		preview_anomaly(0, 0.0)
		preview_san(1.0)
	))
	column.add_child(san_row)


func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 30.0)
	button.pressed.connect(callback)
	return button


func _make_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.38, 1.0))
	return label


func _make_separator() -> HSeparator:
	return HSeparator.new()


func _on_weather_selected(index: int) -> void:
	var mode: StringName = _weather_option.get_item_metadata(index) as StringName
	preview_weather(mode, _weather_strength.value)


func _on_weather_strength_changed(value: float) -> void:
	if _weather_option == null:
		return
	var mode: StringName = _weather_option.get_item_metadata(_weather_option.selected) as StringName
	preview_weather(mode, value)


func _trigger_selected_disaster(active: bool) -> void:
	var kind: int = int(_disaster_option.get_item_metadata(_disaster_option.selected))
	trigger_disaster(kind, active)


func _get_environment_presenter() -> Node:
	return get_parent().get_node_or_null(ENVIRONMENT_PRESENTER_PATH)


func _update_status() -> void:
	if _status_label == null:
		return
	var presenter := _get_environment_presenter()
	var weather: String = str(presenter.call("get_weather_mode")) if presenter != null and presenter.has_method("get_weather_mode") else "unknown"
	var strength: float = float(presenter.call("get_weather_strength")) if presenter != null and presenter.has_method("get_weather_strength") else 0.0
	var player := get_parent().get_node_or_null("Player") as Node2D
	var position_text: String = str(player.global_position.round()) if player != null else "n/a"
	_status_label.text = "玩家坐标 %s\n天气 %s  强度 %.2f\n预览裂口动物 %d" % [position_text, weather, strength, _preview_monsters.size()]
