extends RefCounted
class_name RunRandomStreamModel

## 本局确定性随机流。每种用途拥有独立 RNG、事件编号和固定种子盐值。

const STREAM_TERRAIN: StringName = &"terrain"
const STREAM_RESOURCES: StringName = &"resources"
const STREAM_WEATHER: StringName = &"weather"
const STREAM_DISASTERS: StringName = &"disasters"
const STREAM_CONTAINERS: StringName = &"containers"
const STREAM_ENEMY_SPAWN: StringName = &"enemy_spawn"
const STREAM_DROPS: StringName = &"drops"

const STREAM_NAMES: Array[StringName] = [
	STREAM_TERRAIN,
	STREAM_RESOURCES,
	STREAM_WEATHER,
	STREAM_DISASTERS,
	STREAM_CONTAINERS,
	STREAM_ENEMY_SPAWN,
	STREAM_DROPS,
]
const STREAM_SALTS: Dictionary = {
	STREAM_TERRAIN: 104729,
	STREAM_RESOURCES: 130363,
	STREAM_WEATHER: 155921,
	STREAM_DISASTERS: 180503,
	STREAM_CONTAINERS: 205019,
	STREAM_ENEMY_SPAWN: 230003,
	STREAM_DROPS: 254959,
}
const SEED_MODULUS: int = 2147483647

var _started: bool = false
var _run_seed: int = 0
var _floor_number: int = 0
var _map_seed: int = 0
var _streams: Dictionary = {}
var _event_indices: Dictionary = {}


func start(run_seed: int, floor_number: int = 1) -> bool:
	if _started or floor_number < 1:
		return false
	_started = true
	_run_seed = run_seed
	return _initialize_floor(floor_number)


func begin_floor(floor_number: int) -> bool:
	if not _started or floor_number < 1:
		return false
	return _initialize_floor(floor_number)


func randi_range(stream_name: StringName, from: int, to: int) -> int:
	var rng: RandomNumberGenerator = _get_stream(stream_name)
	if rng == null or from > to:
		return 0
	_event_indices[stream_name] = int(_event_indices.get(stream_name, 0)) + 1
	return rng.randi_range(from, to)


func randf(stream_name: StringName) -> float:
	var rng: RandomNumberGenerator = _get_stream(stream_name)
	if rng == null:
		return 0.0
	_event_indices[stream_name] = int(_event_indices.get(stream_name, 0)) + 1
	return rng.randf()


func get_run_seed() -> int:
	return _run_seed


func get_floor_number() -> int:
	return _floor_number


func get_map_seed() -> int:
	return _map_seed


func get_event_index(stream_name: StringName) -> int:
	return int(_event_indices.get(stream_name, -1))


func create_snapshot() -> Dictionary:
	var stream_snapshots: Array[Dictionary] = []
	for stream_name: StringName in STREAM_NAMES:
		var rng: RandomNumberGenerator = _get_stream(stream_name)
		if rng == null:
			continue
		stream_snapshots.append({
			"name": String(stream_name),
			"state": str(rng.state),
			"event_index": int(_event_indices.get(stream_name, 0)),
		})
	return {
		"run_seed": _run_seed,
		"floor_number": _floor_number,
		"map_seed": _map_seed,
		"streams": stream_snapshots,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["run_seed", "floor_number", "map_seed", "streams"]:
		if not snapshot.has(key):
			return false
	var restored_floor: int = int(snapshot["floor_number"])
	var restored_streams: Array = snapshot["streams"] as Array
	if restored_floor < 1 or restored_streams.size() != STREAM_NAMES.size():
		return false
	var states_by_name: Dictionary = {}
	var indices_by_name: Dictionary = {}
	for stream_data: Variant in restored_streams:
		if not stream_data is Dictionary:
			return false
		var data: Dictionary = stream_data
		if not data.has("name") or not data.has("state") or not data.has("event_index"):
			return false
		var stream_name: StringName = StringName(String(data["name"]))
		if not STREAM_NAMES.has(stream_name) or states_by_name.has(stream_name):
			return false
		var event_index: int = int(data["event_index"])
		if event_index < 0:
			return false
		states_by_name[stream_name] = String(data["state"]).to_int()
		indices_by_name[stream_name] = event_index
	_started = true
	_run_seed = int(snapshot["run_seed"])
	_initialize_floor(restored_floor)
	if _map_seed != int(snapshot["map_seed"]):
		_reset()
		return false
	for stream_name: StringName in STREAM_NAMES:
		var rng: RandomNumberGenerator = _get_stream(stream_name)
		rng.state = int(states_by_name[stream_name])
		_event_indices[stream_name] = int(indices_by_name[stream_name])
	return true


func _initialize_floor(floor_number: int) -> bool:
	_floor_number = floor_number
	_map_seed = _derive_map_seed(_run_seed, floor_number)
	_streams.clear()
	_event_indices.clear()
	for stream_name: StringName in STREAM_NAMES:
		var rng := RandomNumberGenerator.new()
		rng.seed = _derive_stream_seed(_map_seed, int(STREAM_SALTS[stream_name]))
		_streams[stream_name] = rng
		_event_indices[stream_name] = 0
	return true


func _derive_map_seed(run_seed: int, floor_number: int) -> int:
	var normalized_run_seed: int = _positive_mod(run_seed, SEED_MODULUS)
	var derived: int = _positive_mod(
		normalized_run_seed * 48271 + floor_number * 69621 + 1,
		SEED_MODULUS
	)
	return derived if derived != 0 else 1


func _derive_stream_seed(map_seed: int, salt: int) -> int:
	var derived: int = _positive_mod(map_seed * 40692 + salt * 7919 + 17, SEED_MODULUS)
	return derived if derived != 0 else 1


func _positive_mod(value: int, modulus: int) -> int:
	var result: int = value % modulus
	return result + modulus if result < 0 else result


func _get_stream(stream_name: StringName) -> RandomNumberGenerator:
	return _streams.get(stream_name) as RandomNumberGenerator


func _reset() -> void:
	_started = false
	_run_seed = 0
	_floor_number = 0
	_map_seed = 0
	_streams.clear()
	_event_indices.clear()
