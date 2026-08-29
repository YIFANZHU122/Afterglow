extends RefCounted
class_name EnemyPerceptionModel

## 追击型敌人的视觉、听声和线索衰减状态。

enum State {
	SEARCHING,
	TRACKING,
	INVESTIGATING,
}

const CLUE_GRACE_SECONDS: float = 8.0
const SEARCH_TIMEOUT_SECONDS: float = 15.0

var _state: State = State.SEARCHING
var _last_known_position: Vector2 = Vector2.ZERO
var _confidence: float = 0.0
var _clue_start_confidence: float = 0.0
var _time_since_last_clue: float = 0.0


func observe_visual(
	player_position: Vector2,
	has_line_of_sight: bool,
	brightness: float,
	required_brightness: float
) -> bool:
	if not player_position.is_finite() or not has_line_of_sight:
		return false
	if brightness < maxf(required_brightness, 0.0):
		return false
	_state = State.TRACKING
	_last_known_position = player_position
	_confidence = 1.0
	_clue_start_confidence = _confidence
	_time_since_last_clue = 0.0
	return true


func hear_sound(sound_position: Vector2, radius: float, sound_strength: float) -> bool:
	if not sound_position.is_finite() or radius <= 0.0 or sound_strength <= 0.0:
		return false
	_state = State.INVESTIGATING
	_last_known_position = sound_position
	_confidence = clampf(sound_strength, 0.25, 1.0)
	_clue_start_confidence = _confidence
	_time_since_last_clue = 0.0
	return true


func advance(delta: float) -> bool:
	if delta <= 0.0 or _state == State.SEARCHING:
		return false
	_time_since_last_clue += delta
	if _time_since_last_clue <= CLUE_GRACE_SECONDS:
		return false
	var decay_window: float = SEARCH_TIMEOUT_SECONDS - CLUE_GRACE_SECONDS
	var remaining_ratio: float = 1.0 - (_time_since_last_clue - CLUE_GRACE_SECONDS) / decay_window
	_confidence = clampf(_clue_start_confidence * remaining_ratio, 0.0, _clue_start_confidence)
	if _time_since_last_clue >= SEARCH_TIMEOUT_SECONDS:
		_state = State.SEARCHING
		_confidence = 0.0
		return true
	return false


func get_state() -> State:
	return _state


func get_last_known_position() -> Vector2:
	return _last_known_position


func get_confidence() -> float:
	return _confidence


func create_snapshot() -> Dictionary:
	return {
		"state": int(_state),
		"last_known_position": [_last_known_position.x, _last_known_position.y],
		"confidence": _confidence,
		"clue_start_confidence": _clue_start_confidence,
		"time_since_last_clue": _time_since_last_clue,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["state", "last_known_position", "confidence", "clue_start_confidence", "time_since_last_clue"]:
		if not snapshot.has(key):
			return false
	var state: int = int(snapshot["state"])
	var position: Vector2 = _decode_vector(snapshot["last_known_position"])
	var confidence: float = float(snapshot["confidence"])
	var start_confidence: float = float(snapshot["clue_start_confidence"])
	var elapsed: float = float(snapshot["time_since_last_clue"])
	if state < State.SEARCHING or state > State.INVESTIGATING or not position.is_finite() or confidence < 0.0 or confidence > 1.0 or start_confidence < 0.0 or start_confidence > 1.0 or elapsed < 0.0:
		return false
	_state = state as State
	_last_known_position = position
	_confidence = confidence
	_clue_start_confidence = start_confidence
	_time_since_last_clue = elapsed
	return true


func _decode_vector(value: Variant) -> Vector2:
	if value is Array and (value as Array).size() == 2:
		return Vector2(float((value as Array)[0]), float((value as Array)[1]))
	return Vector2(INF, INF)
