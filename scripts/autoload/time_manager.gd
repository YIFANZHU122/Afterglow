extends Node

## 全局时间、季节与昼夜管理器
## 运行时状态跨场景持久，并通过 ConfigFile 在游戏重启后恢复。

enum Season {
	SPRING,
	SUMMER,
	AUTUMN,
	WINTER,
}

signal time_changed(hour: int, minute: int, day: int, season: Season)
signal day_changed(day: int, season: Season)
signal season_changed(season: Season)
signal lighting_changed(color: Color)

const MINUTES_PER_HOUR: int = 60
const HOURS_PER_DAY: int = 24
const DAYS_PER_SEASON: int = 28
const SEASONS_PER_YEAR: int = 4
const SAVE_PATH: String = "user://time_state.cfg"
const SAVE_INTERVAL_SECONDS: float = 60.0
const DEFAULT_HOUR: int = 6
const DEFAULT_MINUTE: int = 0
const DEFAULT_DAY: int = 1
const DEFAULT_SEASON: Season = Season.SPRING

# 现实 1 秒推进的游戏分钟数；可由调试工具或后续设置直接调整。
@export var time_scale: float = 5.0

var minute: int = DEFAULT_MINUTE
var hour: int = DEFAULT_HOUR
var day: int = DEFAULT_DAY
var season: Season = DEFAULT_SEASON

var _minute_accumulator: float = 0.0
var _save_elapsed: float = 0.0
var _lighting_color: Color = Color.WHITE


func _ready() -> void:
	load_state()
	_lighting_color = get_lighting_color()
	get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("_apply_lighting_to_current_scene")


func _process(delta: float) -> void:
	if get_tree().paused:
		return

	var safe_time_scale := maxf(time_scale, 0.0)
	_minute_accumulator += delta * safe_time_scale
	_save_elapsed += delta

	var minutes_to_advance := int(_minute_accumulator)
	if minutes_to_advance > 0:
		_minute_accumulator -= minutes_to_advance
		_advance_minutes(minutes_to_advance)

	if _save_elapsed >= SAVE_INTERVAL_SECONDS:
		_save_elapsed = fmod(_save_elapsed, SAVE_INTERVAL_SECONDS)
		save_state()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_state()
		get_tree().quit()


func _advance_minutes(amount: int) -> void:
	if amount <= 0:
		return

	var total_minutes := hour * MINUTES_PER_HOUR + minute + amount
	var days_to_advance := total_minutes / (HOURS_PER_DAY * MINUTES_PER_HOUR)
	var new_day_minutes := total_minutes % (HOURS_PER_DAY * MINUTES_PER_HOUR)
	hour = new_day_minutes / MINUTES_PER_HOUR
	minute = new_day_minutes % MINUTES_PER_HOUR

	var old_season := season
	var old_day := day
	if days_to_advance > 0:
		var absolute_day := season * DAYS_PER_SEASON + (day - 1) + days_to_advance
		var total_days := DAYS_PER_SEASON * SEASONS_PER_YEAR
		absolute_day = absolute_day % total_days
		season = absolute_day / DAYS_PER_SEASON
		day = (absolute_day % DAYS_PER_SEASON) + 1

	if season != old_season:
		season_changed.emit(season)
	if day != old_day or season != old_season:
		day_changed.emit(day, season)

	_emit_time_changed()


func _emit_time_changed() -> void:
	time_changed.emit(hour, minute, day, season)
	var new_lighting_color := get_lighting_color()
	if not new_lighting_color.is_equal_approx(_lighting_color):
		_lighting_color = new_lighting_color
		lighting_changed.emit(_lighting_color)
		_apply_lighting_to_current_scene()


func _on_scene_changed() -> void:
	call_deferred("_apply_lighting_to_current_scene")


func _apply_lighting_to_current_scene() -> void:
	if not is_inside_tree():
		return
	var scene := get_tree().current_scene
	if scene == null:
		return

	var canvas_modulate := scene.get_node_or_null("DayNightModulate") as CanvasModulate
	if canvas_modulate == null:
		canvas_modulate = CanvasModulate.new()
		canvas_modulate.name = "DayNightModulate"
		scene.add_child(canvas_modulate)
	canvas_modulate.color = _lighting_color


func get_hour() -> int:
	return hour


func get_minute() -> int:
	return minute


func get_day() -> int:
	return day


func get_season() -> Season:
	return season


func get_time_text() -> String:
	var meridiem := "AM" if hour < 12 else "PM"
	return "%02d:%02d %s" % [hour, minute, meridiem]


func get_date_text() -> String:
	return "%s · 第%d天" % [get_season_name(), day]


func get_season_name(value: Season = season) -> String:
	match value:
		Season.SPRING:
			return "春"
		Season.SUMMER:
			return "夏"
		Season.AUTUMN:
			return "秋"
		Season.WINTER:
			return "冬"
	return "春"


func get_lighting_color() -> Color:
	var minutes := hour * MINUTES_PER_HOUR + minute
	var dawn_start := 5.0 * MINUTES_PER_HOUR
	var day_start := 7.0 * MINUTES_PER_HOUR
	var dusk_start := 17.0 * MINUTES_PER_HOUR
	var night_start := 19.0 * MINUTES_PER_HOUR
	var night_color := Color(0.48, 0.52, 0.72, 1.0)

	if minutes < dawn_start or minutes >= night_start:
		return night_color
	if minutes < day_start:
		var dawn_ratio := smoothstep(dawn_start, day_start, float(minutes))
		return night_color.lerp(Color.WHITE, dawn_ratio)
	if minutes < dusk_start:
		return Color.WHITE
	var dusk_ratio := smoothstep(dusk_start, night_start, float(minutes))
	return Color.WHITE.lerp(night_color, dusk_ratio)


func set_time(new_hour: int, new_minute: int, new_day: int, new_season: Season) -> void:
	var old_day := day
	var old_season := season
	hour = clampi(new_hour, 0, HOURS_PER_DAY - 1)
	minute = clampi(new_minute, 0, MINUTES_PER_HOUR - 1)
	day = clampi(new_day, 1, DAYS_PER_SEASON)
	season = clampi(int(new_season), 0, SEASONS_PER_YEAR - 1) as Season
	_minute_accumulator = 0.0
	if season != old_season:
		season_changed.emit(season)
	if day != old_day or season != old_season:
		day_changed.emit(day, season)
	_emit_time_changed()


func save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("time", "minute", minute)
	config.set_value("time", "hour", hour)
	config.set_value("time", "day", day)
	config.set_value("time", "season", int(season))
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("[TimeManager] 无法保存时间状态：" + error_string(error))


func load_state() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		_reset_to_default()
		return

	var saved_hour = config.get_value("time", "hour", DEFAULT_HOUR)
	var saved_minute = config.get_value("time", "minute", DEFAULT_MINUTE)
	var saved_day = config.get_value("time", "day", DEFAULT_DAY)
	var saved_season = config.get_value("time", "season", int(DEFAULT_SEASON))
	if not _is_valid_state(saved_hour, saved_minute, saved_day, saved_season):
		push_warning("[TimeManager] 时间存档无效，已恢复默认时间。")
		_reset_to_default()
		return

	hour = int(saved_hour)
	minute = int(saved_minute)
	day = int(saved_day)
	season = int(saved_season) as Season
	_minute_accumulator = 0.0


func _is_valid_state(value_hour: Variant, value_minute: Variant, value_day: Variant, value_season: Variant) -> bool:
	return value_hour is int and value_minute is int and value_day is int and value_season is int \
		and value_hour >= 0 and value_hour < HOURS_PER_DAY \
		and value_minute >= 0 and value_minute < MINUTES_PER_HOUR \
		and value_day >= 1 and value_day <= DAYS_PER_SEASON \
		and value_season >= 0 and value_season < SEASONS_PER_YEAR


func _reset_to_default() -> void:
	hour = DEFAULT_HOUR
	minute = DEFAULT_MINUTE
	day = DEFAULT_DAY
	season = DEFAULT_SEASON
	_minute_accumulator = 0.0
