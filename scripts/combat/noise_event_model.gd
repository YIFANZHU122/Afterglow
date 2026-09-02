extends RefCounted
class_name NoiseEventModel

## 统一声音事件：只携带发生位置和有限时效的线索，不共享玩家实时坐标。

enum Kind {
	SEARCH,
	MELEE,
	GATHER,
	BUILD,
	FIREARM,
	EXPLOSION,
}

const RADIUS_STEPS_BY_KIND: Dictionary = {
	Kind.SEARCH: 2.0,
	Kind.MELEE: 4.0,
	Kind.GATHER: 6.0,
	Kind.BUILD: 8.0,
	Kind.FIREARM: 16.0,
	Kind.EXPLOSION: 24.0,
}
const RAIN_RADIUS_MULTIPLIER: float = 0.90
const FORMAT_VERSION: int = 1

var _kind: Kind = Kind.SEARCH
var _origin: Vector2 = Vector2.ZERO
var _strength: float = 1.0
var _raining: bool = false


func _init(kind: int = Kind.SEARCH, origin: Vector2 = Vector2.ZERO, strength: float = 1.0, raining: bool = false) -> void:
	_kind = kind as Kind if kind >= Kind.SEARCH and kind <= Kind.EXPLOSION else Kind.SEARCH
	_origin = origin if origin.is_finite() else Vector2.ZERO
	_strength = clampf(strength, 0.0, 1.0)
	_raining = raining


func get_kind() -> Kind:
	return _kind


func get_origin() -> Vector2:
	return _origin


func get_strength() -> float:
	return _strength


func get_radius_steps() -> float:
	var base_radius: float = float(RADIUS_STEPS_BY_KIND.get(_kind, 0.0))
	return base_radius * _strength * (RAIN_RADIUS_MULTIPLIER if _raining else 1.0)


func affects(listener_position: Vector2, blocked_by_wall: bool = false, raining_override: bool = false) -> bool:
	if blocked_by_wall or not listener_position.is_finite():
		return false
	var radius_steps: float = get_radius_steps()
	if raining_override and not _raining:
		radius_steps *= RAIN_RADIUS_MULTIPLIER
	return listener_position.distance_to(_origin) <= radius_steps * 40.0


func create_snapshot() -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"kind": int(_kind),
		"origin": [_origin.x, _origin.y],
		"strength": _strength,
		"raining": _raining,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["format_version", "kind", "origin", "strength", "raining"]:
		if not snapshot.has(key):
			return false
	var kind: int = int(snapshot["kind"])
	var raw_origin: Array = snapshot["origin"] as Array
	var origin: Vector2 = Vector2(INF, INF)
	if raw_origin != null and raw_origin.size() == 2:
		origin = Vector2(float(raw_origin[0]), float(raw_origin[1]))
	var strength: float = float(snapshot["strength"])
	if int(snapshot["format_version"]) != FORMAT_VERSION or kind < Kind.SEARCH or kind > Kind.EXPLOSION \
		or not origin.is_finite() or not is_finite(strength) or strength < 0.0 or strength > 1.0 \
		or snapshot["raining"] is not bool:
		return false
	_kind = kind as Kind
	_origin = origin
	_strength = strength
	_raining = bool(snapshot["raining"])
	return true
