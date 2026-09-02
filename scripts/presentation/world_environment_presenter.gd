extends Node2D
class_name WorldEnvironmentPresenter

## 只负责把现有昼夜与灾难状态映射为环境覆盖层，不改变任何玩法状态。

const DISASTER_SCHEDULER_MODEL_SCRIPT: Script = preload("res://scripts/world/disaster_scheduler_model.gd")
const DISASTER_EVENT_MODEL_SCRIPT: Script = preload("res://scripts/world/disaster_event_model.gd")

const MOON_TEXTURES: Array[Texture2D] = [
	preload("res://assets/art/moon/moon_00_new.png"),
	preload("res://assets/art/moon/moon_01_waxing_crescent.png"),
	preload("res://assets/art/moon/moon_02_first_quarter.png"),
	preload("res://assets/art/moon/moon_03_waxing_gibbous.png"),
	preload("res://assets/art/moon/moon_04_full.png"),
	preload("res://assets/art/moon/moon_05_waning_gibbous.png"),
	preload("res://assets/art/moon/moon_06_third_quarter.png"),
	preload("res://assets/art/moon/moon_07_waning_crescent.png"),
]

const WEATHER_COLORS: Dictionary = {
	&"clear": Color(1.0, 1.0, 1.0, 0.0),
	&"rainstorm": Color(0.28, 0.39, 0.52, 0.42),
	&"heatwave": Color(0.82, 0.54, 0.22, 0.34),
	&"dense_fog": Color(0.62, 0.66, 0.67, 0.5),
	&"cold_snap": Color(0.42, 0.58, 0.72, 0.38),
}
const DAY_TINT: Color = Color(0.92, 0.84, 0.62, 0.0)
const NIGHT_TINT: Color = Color(0.11, 0.16, 0.28, 0.32)
const FROST_TEXTURE: Texture2D = preload("res://assets/art/weather/frost_particle.png")
const SMOKE_TEXTURE: Texture2D = preload("res://assets/art/weather/smoke_particle.png")

enum AnomalyKind {
	NONE,
	ABERRANT_MOON,
	POLLUTED_SKY,
	CELESTIAL_RIFT,
}

var _moon_phase_index: int = 0
var _weather_mode: StringName = &"clear"
var _weather_strength: float = 0.0
var _is_night: bool = false
var _anomaly_kind: int = AnomalyKind.NONE
var _anomaly_intensity: float = 0.0
var _san_intensity: float = 0.0
var _audio_phase: float = 0.0

@onready var _moon: Sprite2D = $EnvironmentCanvas/MoonSprite
@onready var _day_night_tint: ColorRect = $EnvironmentCanvas/DayNightTint
@onready var _weather_tint: ColorRect = $EnvironmentCanvas/WeatherTint
@onready var _fog_layer: TextureRect = $EnvironmentCanvas/FogLayer
@onready var _dust_layer: GPUParticles2D = $EnvironmentCanvas/DustLayer
@onready var _rain_layer: GPUParticles2D = $EnvironmentCanvas/RainLayer
@onready var _particle_layer: GPUParticles2D = $EnvironmentCanvas/ParticleLayer
@onready var _heat_haze: CanvasItem = $EnvironmentCanvas/HeatHaze
@onready var _frost_edge: CanvasItem = $EnvironmentCanvas/FrostEdge
@onready var _post_process_layer: CanvasItem = $EnvironmentCanvas/PostProcessLayer
@onready var _weather_audio: AudioStreamPlayer = $EnvironmentCanvas/WeatherAudio
@onready var _rain_audio: AudioStreamPlayer = $EnvironmentCanvas/RainAudio
@onready var _heat_audio: AudioStreamPlayer = $EnvironmentCanvas/HeatAudio
@onready var _fog_audio: AudioStreamPlayer = $EnvironmentCanvas/FogAudio
@onready var _cold_audio: AudioStreamPlayer = $EnvironmentCanvas/ColdAudio
@onready var _anomaly_moon: CanvasItem = $EnvironmentCanvas/AnomalyMoon
@onready var _pollution_sky: CanvasItem = $EnvironmentCanvas/PollutionSky
@onready var _celestial_rift: CanvasItem = $EnvironmentCanvas/CelestialRift
@onready var _san_vignette: CanvasItem = $EnvironmentCanvas/SanVignette


func _ready() -> void:
	_setup_weather_audio()
	if GameManager.has_signal("survival_changed"):
		GameManager.survival_changed.connect(_on_survival_changed)
	if GameManager.has_signal("disaster_changed"):
		GameManager.disaster_changed.connect(_on_disaster_changed)
	_sync_from_game_manager()


func _process(delta: float) -> void:
	_audio_phase += delta
	_fill_weather_audio()


func _exit_tree() -> void:
	for player: AudioStreamPlayer in [_rain_audio, _heat_audio, _fog_audio, _cold_audio]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null


func present_survival(day_index: int, is_night: bool) -> void:
	_moon_phase_index = _calculate_moon_phase_index(day_index)
	_is_night = is_night
	_apply_moon_state()


func present_disaster(kind: int, phase: int) -> void:
	var mapped_mode: StringName = _weather_mode_for_kind(kind)
	var mapped_strength: float = _weather_strength_for_phase(phase)
	if mapped_mode == &"clear" or mapped_strength <= 0.0:
		_weather_mode = &"clear"
		_weather_strength = 0.0
	else:
		_weather_mode = mapped_mode
		_weather_strength = mapped_strength
	_apply_weather_state()


func present_weather_override(mode: StringName, strength: float) -> void:
	## 调试预览入口：只改变当前 Presenter 的表现，不改变 GameManager 灾难状态。
	if mode != &"clear" and not WEATHER_COLORS.has(mode):
		_weather_mode = &"clear"
		_weather_strength = 0.0
	else:
		_weather_mode = mode
		_weather_strength = 0.0 if mode == &"clear" else clampf(strength, 0.0, 1.0)
	_apply_weather_state()


func get_moon_phase_index() -> int:
	return _moon_phase_index


func get_weather_mode() -> StringName:
	return _weather_mode


func get_weather_strength() -> float:
	return _weather_strength


func present_anomaly(anomaly_kind: int, intensity: float) -> void:
	if anomaly_kind < AnomalyKind.NONE or anomaly_kind > AnomalyKind.CELESTIAL_RIFT:
		_anomaly_kind = AnomalyKind.NONE
		_anomaly_intensity = 0.0
	else:
		_anomaly_kind = anomaly_kind
		_anomaly_intensity = clampf(intensity, 0.0, 1.0) if anomaly_kind != AnomalyKind.NONE else 0.0
	_apply_anomaly_state()


func get_anomaly_kind() -> int:
	return _anomaly_kind


func get_anomaly_intensity() -> float:
	return _anomaly_intensity


func present_san(sanity_ratio: float) -> void:
	_san_intensity = clampf(1.0 - sanity_ratio, 0.0, 1.0)
	_apply_san_state()


func get_san_intensity() -> float:
	return _san_intensity


func _sync_from_game_manager() -> void:
	if GameManager.has_method("get_floor_day_index") and GameManager.has_method("is_floor_night"):
		present_survival(GameManager.get_floor_day_index(), GameManager.is_floor_night())
	if GameManager.has_method("get_primary_disaster_kind") and GameManager.has_method("get_primary_disaster_phase"):
		present_disaster(GameManager.get_primary_disaster_kind(), GameManager.get_primary_disaster_phase())


func _on_survival_changed(
	_hunger: float,
	_water: float,
	_elapsed_seconds: float,
	day_index: int,
	is_night: bool,
	_overtime_stage: int,
	_disaster_probability: float
) -> void:
	present_survival(day_index, is_night)


func _on_disaster_changed(
	kind: int,
	phase: int,
	_remaining_seconds: float,
	_risk_level: int,
	_countermeasure_progress: float
) -> void:
	present_disaster(kind, phase)


func _calculate_moon_phase_index(day_index: int) -> int:
	return (maxi(day_index, 1) - 1) % MOON_TEXTURES.size()


func _weather_mode_for_kind(kind: int) -> StringName:
	if kind == int(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.RAINSTORM):
		return &"rainstorm"
	if kind == int(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.HEATWAVE):
		return &"heatwave"
	if kind == int(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.DENSE_FOG):
		return &"dense_fog"
	if kind == int(DISASTER_SCHEDULER_MODEL_SCRIPT.DisasterKind.COLD_SNAP):
		return &"cold_snap"
	return &"clear"


func _weather_strength_for_phase(phase: int) -> float:
	if phase == int(DISASTER_EVENT_MODEL_SCRIPT.Phase.WARNING):
		return 0.35
	if phase == int(DISASTER_EVENT_MODEL_SCRIPT.Phase.ACTIVE):
		return 1.0
	return 0.0


func _apply_moon_state() -> void:
	if not is_instance_valid(_moon) or not is_instance_valid(_day_night_tint):
		return
	_moon.texture = MOON_TEXTURES[_moon_phase_index]
	_moon.visible = _is_night
	_day_night_tint.color = NIGHT_TINT if _is_night else DAY_TINT
	_apply_night_fog_visual()
	_apply_anomaly_state()


func _apply_weather_state() -> void:
	if not is_instance_valid(_weather_tint) or not is_instance_valid(_fog_layer) \
		or not is_instance_valid(_dust_layer) or not is_instance_valid(_rain_layer) \
		or not is_instance_valid(_particle_layer):
		return
	var base_color: Color = WEATHER_COLORS.get(_weather_mode, WEATHER_COLORS[&"clear"])
	_weather_tint.color = Color(base_color.r, base_color.g, base_color.b, base_color.a * _weather_strength)
	_apply_night_fog_visual()
	if _weather_mode == &"dense_fog" and _weather_strength > 0.0:
		_fog_layer.visible = true
		_fog_layer.modulate.a = maxf(_fog_layer.modulate.a, 0.35 * _weather_strength)
	_rain_layer.visible = _weather_mode == &"rainstorm" and _weather_strength > 0.0
	_rain_layer.modulate.a = 0.55 * _weather_strength
	_rain_layer.emitting = _rain_layer.visible
	_dust_layer.visible = _weather_mode == &"heatwave" and _weather_strength > 0.0
	_dust_layer.modulate.a = _weather_strength
	_dust_layer.emitting = _dust_layer.visible
	_particle_layer.visible = _weather_mode == &"cold_snap" and _weather_strength > 0.0
	_particle_layer.texture = FROST_TEXTURE if _weather_mode == &"cold_snap" else SMOKE_TEXTURE
	_particle_layer.modulate.a = 0.5 * _weather_strength
	_heat_haze.visible = _weather_mode == &"heatwave" and _weather_strength > 0.0
	_heat_haze.modulate.a = 0.12 * _weather_strength
	_frost_edge.visible = _weather_mode == &"cold_snap" and _weather_strength > 0.0
	_frost_edge.modulate.a = 0.32 * _weather_strength
	_post_process_layer.visible = _weather_strength > 0.0
	_post_process_layer.modulate.a = 0.16 * _weather_strength
	_update_weather_audio()


func _apply_anomaly_state() -> void:
	if not is_instance_valid(_anomaly_moon) or not is_instance_valid(_pollution_sky) or not is_instance_valid(_celestial_rift):
		return
	_anomaly_moon.visible = _anomaly_kind == AnomalyKind.ABERRANT_MOON and _is_night and _anomaly_intensity > 0.0
	_anomaly_moon.modulate.a = _anomaly_intensity
	_pollution_sky.visible = _anomaly_kind == AnomalyKind.POLLUTED_SKY and _anomaly_intensity > 0.0
	_pollution_sky.modulate.a = 0.42 * _anomaly_intensity
	_celestial_rift.visible = _anomaly_kind == AnomalyKind.CELESTIAL_RIFT and _anomaly_intensity > 0.0
	_celestial_rift.modulate.a = 0.55 * _anomaly_intensity
	if is_instance_valid(_post_process_layer) and _anomaly_kind != AnomalyKind.NONE:
		_post_process_layer.visible = true
		_post_process_layer.modulate.a = maxf(float(_post_process_layer.modulate.a), 0.2 * _anomaly_intensity)


func _apply_san_state() -> void:
	if not is_instance_valid(_san_vignette):
		return
	_san_vignette.visible = _san_intensity > 0.0
	_san_vignette.modulate.a = 0.45 * _san_intensity


func _update_weather_audio() -> void:
	var players: Array[AudioStreamPlayer] = [_rain_audio, _heat_audio, _fog_audio, _cold_audio]
	for player: AudioStreamPlayer in players:
		if is_instance_valid(player):
			player.stop()
	var selected: AudioStreamPlayer = null
	if _weather_mode == &"rainstorm":
		selected = _rain_audio
	elif _weather_mode == &"heatwave":
		selected = _heat_audio
	elif _weather_mode == &"dense_fog":
		selected = _fog_audio
	elif _weather_mode == &"cold_snap":
		selected = _cold_audio
	if selected != null and _weather_strength > 0.0:
		if selected.stream == null:
			selected.stream = AudioStreamGenerator.new()
			(selected.stream as AudioStreamGenerator).mix_rate = 22050.0
		selected.volume_db = linear_to_db(clampf(_weather_strength, 0.01, 1.0)) - 8.0
		selected.play()


func _setup_weather_audio() -> void:
	for player: AudioStreamPlayer in [_rain_audio, _heat_audio, _fog_audio, _cold_audio]:
		if not is_instance_valid(player):
			continue
		var generator := AudioStreamGenerator.new()
		generator.mix_rate = 22050.0
		player.stream = generator


func _fill_weather_audio() -> void:
	var selected: AudioStreamPlayer = null
	if _weather_mode == &"rainstorm":
		selected = _rain_audio
	elif _weather_mode == &"heatwave":
		selected = _heat_audio
	elif _weather_mode == &"dense_fog":
		selected = _fog_audio
	elif _weather_mode == &"cold_snap":
		selected = _cold_audio
	if selected == null or not selected.playing:
		return
	var playback := selected.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frequency: float = 90.0 if _weather_mode == &"heatwave" else 180.0 if _weather_mode == &"rainstorm" else 260.0 if _weather_mode == &"dense_fog" else 520.0
	while playback.get_frames_available() > 0:
		var sample: float = sin(_audio_phase * TAU * frequency) * 0.025 * _weather_strength
		playback.push_frame(Vector2(sample, sample))
	_particle_layer.emitting = _particle_layer.visible


func _apply_night_fog_visual() -> void:
	if not is_instance_valid(_fog_layer):
		return
	var phase: int = 0
	if is_instance_valid(GameManager) and GameManager.has_method("get_night_fog_phase"):
		phase = int(GameManager.get_night_fog_phase())
	var alpha_by_phase: Array[float] = [0.0, 0.10, 0.20, 0.30]
	var night_alpha: float = alpha_by_phase[clampi(phase, 0, alpha_by_phase.size() - 1)] if _is_night else 0.0
	_fog_layer.visible = night_alpha > 0.0
	_fog_layer.modulate.a = night_alpha
