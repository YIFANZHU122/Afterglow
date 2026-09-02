extends RefCounted
class_name DiggingModel

const STEP_TERRAIN_MODEL_SCRIPT: Script = preload("res://scripts/world/step_terrain_model.gd")

## 离散地块挖掘：一次动作只降低一个 step，并消耗一点铲子耐久。

enum State { IDLE, ACTIVE }

var _dig_duration_seconds: float
var _noise_strength: float
var _state: State = State.IDLE
var _remaining_seconds: float = 0.0
var _terrain_kind: int = STEP_TERRAIN_MODEL_SCRIPT.TerrainKind.OPEN
var _terrain_depth: int = 0
var _shovel_durability: int = 0


func _init(dig_duration_seconds: float = 2.0, noise_strength: float = 3.0) -> void:
	_dig_duration_seconds = maxf(dig_duration_seconds, 0.1)
	_noise_strength = maxf(noise_strength, 0.0)


func try_start(terrain_kind: int, terrain_depth: int, shovel_durability: int) -> bool:
	if _state != State.IDLE or not STEP_TERRAIN_MODEL_SCRIPT.is_diggable(terrain_kind):
		return false
	if terrain_depth <= 0 or terrain_depth > STEP_TERRAIN_MODEL_SCRIPT.MAX_DIRECT_TRAVERSAL_STEPS or shovel_durability <= 0:
		return false
	_terrain_kind = terrain_kind
	_terrain_depth = terrain_depth
	_shovel_durability = shovel_durability
	_remaining_seconds = _dig_duration_seconds
	_state = State.ACTIVE
	return true


func advance(delta: float) -> bool:
	if _state != State.ACTIVE or delta <= 0.0:
		return false
	_remaining_seconds = maxf(_remaining_seconds - delta, 0.0)
	if _remaining_seconds > 0.0:
		return false
	_terrain_depth = maxi(_terrain_depth - 1, 0)
	_shovel_durability = maxi(_shovel_durability - 1, 0)
	_state = State.IDLE
	return true


func cancel() -> bool:
	if _state == State.IDLE:
		return false
	_state = State.IDLE
	_remaining_seconds = 0.0
	return true


func get_state() -> State:
	return _state


func get_terrain_depth() -> int:
	return _terrain_depth


func get_shovel_durability() -> int:
	return _shovel_durability


func get_noise_strength() -> float:
	return _noise_strength


func create_snapshot() -> Dictionary:
	return {"format_version": 1, "state": int(_state), "remaining_seconds": _remaining_seconds, "terrain_kind": _terrain_kind, "terrain_depth": _terrain_depth, "shovel_durability": _shovel_durability}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if int(snapshot.get("format_version", -1)) != 1:
		return false
	var state := int(snapshot.get("state", -1))
	var remaining := float(snapshot.get("remaining_seconds", -1.0))
	var kind := int(snapshot.get("terrain_kind", -1))
	var depth := int(snapshot.get("terrain_depth", -1))
	var durability := int(snapshot.get("shovel_durability", -1))
	if state < State.IDLE or state > State.ACTIVE or not is_finite(remaining) or remaining < 0.0 or (not STEP_TERRAIN_MODEL_SCRIPT.is_diggable(kind) and kind != STEP_TERRAIN_MODEL_SCRIPT.TerrainKind.OPEN) or depth < 0 or depth > STEP_TERRAIN_MODEL_SCRIPT.MAX_DIRECT_TRAVERSAL_STEPS or durability < 0:
		return false
	_state = state as State
	_remaining_seconds = remaining
	_terrain_kind = kind
	_terrain_depth = depth
	_shovel_durability = durability
	return true
