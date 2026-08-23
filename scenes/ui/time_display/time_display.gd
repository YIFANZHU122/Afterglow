extends PanelContainer

## 右上角时间与季节显示面板

@onready var time_label: Label = $Margin/VBox/TimeLabel
@onready var date_label: Label = $Margin/VBox/DateLabel


func _ready() -> void:
	TimeManager.time_changed.connect(_on_time_changed)
	_refresh()


func _exit_tree() -> void:
	if TimeManager.time_changed.is_connected(_on_time_changed):
		TimeManager.time_changed.disconnect(_on_time_changed)


func _on_time_changed(_hour: int, _minute: int, _day: int, _season: TimeManager.Season) -> void:
	_refresh()


func _refresh() -> void:
	time_label.text = TimeManager.get_time_text()
	date_label.text = TimeManager.get_date_text()
