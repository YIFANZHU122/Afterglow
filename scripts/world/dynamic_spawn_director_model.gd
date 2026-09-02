extends RefCounted
class_name DynamicSpawnDirectorModel

## 动态刷怪导演：独立于固定 EncounterController，只消费合法刷新点和威胁预算。

const SPAWN_POINT_SCRIPT: Script = preload("res://scripts/data/dynamic_spawn_point_definition.gd")
const SPAWN_PROTECTION_MODEL_SCRIPT: Script = preload("res://scripts/world/spawn_protection_model.gd")

const FORMAT_VERSION: int = 1
const DEFAULT_WAVE_INTERVAL_SECONDS: float = 45.0

var _wave_interval_seconds: float = DEFAULT_WAVE_INTERVAL_SECONDS
var _wave_elapsed_seconds: float = 0.0
var _retry_count: int = 0


func _init(wave_interval_seconds: float = DEFAULT_WAVE_INTERVAL_SECONDS) -> void:
	_wave_interval_seconds = maxf(wave_interval_seconds, 1.0)


func set_wave_interval_seconds(wave_interval_seconds: float) -> bool:
	if not is_finite(wave_interval_seconds) or wave_interval_seconds < 1.0:
		return false
	if is_equal_approx(_wave_interval_seconds, wave_interval_seconds):
		return false
	_wave_interval_seconds = wave_interval_seconds
	return true


func get_wave_interval_seconds() -> float:
	return _wave_interval_seconds


func advance(delta: float, is_night: bool) -> bool:
	if not is_finite(delta) or delta <= 0.0:
		return false
	if is_night:
		_wave_elapsed_seconds += delta
	else:
		_wave_elapsed_seconds = 0.0
	return true


func is_wave_ready() -> bool:
	return _wave_elapsed_seconds >= _wave_interval_seconds


func consume_wave() -> bool:
	if not is_wave_ready():
		return false
	_wave_elapsed_seconds -= _wave_interval_seconds
	_retry_count = 0
	return true


func register_retry() -> bool:
	_retry_count += 1
	return true


func get_retry_count() -> int:
	return _retry_count


func choose_spawn_point(
	candidates: Array[Resource],
	rng: Object,
	player_position: Vector2,
	protected_points: Array[Vector2],
	is_visible: bool,
	in_fog: bool,
	prefer_special: bool = false,
	special_ratio: float = -1.0
) -> Resource:
	if rng == null or not player_position.is_finite():
		return null
	var normalized_special_ratio: float = 1.0 if prefer_special and special_ratio < 0.0 else clampf(special_ratio, 0.0, 1.0)
	var protection: RefCounted = SPAWN_PROTECTION_MODEL_SCRIPT.new()
	var valid: Array[Resource] = []
	var total_weight: float = 0.0
	for raw_candidate: Resource in candidates:
		if raw_candidate == null or raw_candidate.get_script() != SPAWN_POINT_SCRIPT or not raw_candidate.is_valid():
			continue
		var candidate: Resource = raw_candidate
		if not protection.is_valid_spawn(candidate.position, player_position, protected_points, is_visible, in_fog):
			continue
		var candidate_weight: float = candidate.weight * (1.0 + candidate.special_weight * normalized_special_ratio)
		valid.append(candidate)
		total_weight += candidate_weight
	if valid.is_empty() or total_weight <= 0.0:
		return null
	var roll: float = _next_random_float(rng) * total_weight
	for candidate: Resource in valid:
		var candidate_weight: float = candidate.weight * (1.0 + candidate.special_weight * normalized_special_ratio)
		roll -= candidate_weight
		if roll < 0.0:
			return candidate
	return valid.back()


func _next_random_float(rng: Object) -> float:
	if rng.has_method("randf"):
		return float(rng.call("randf", &"enemy_spawn"))
	if rng.has_method("random_float"):
		return float(rng.call("random_float", &"enemy_spawn"))
	return 0.0


func create_snapshot() -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"wave_interval_seconds": _wave_interval_seconds,
		"wave_elapsed_seconds": _wave_elapsed_seconds,
		"retry_count": _retry_count,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["format_version", "wave_interval_seconds", "wave_elapsed_seconds", "retry_count"]:
		if not snapshot.has(key):
			return false
	var interval: float = float(snapshot["wave_interval_seconds"])
	var elapsed: float = float(snapshot["wave_elapsed_seconds"])
	var retries: int = int(snapshot["retry_count"])
	if int(snapshot["format_version"]) != FORMAT_VERSION or not is_finite(interval) or interval < 1.0 \
		or not is_finite(elapsed) or elapsed < 0.0 or not is_finite(float(retries)) or retries < 0:
		return false
	_wave_interval_seconds = interval
	_wave_elapsed_seconds = elapsed
	_retry_count = retries
	return true
