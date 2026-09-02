extends RefCounted
class_name BuildingModel

## 最小建筑运行时规则：位置合法性、生命和快照。

enum Kind { SHELTER, WALL }
const FORMAT_VERSION: int = 1
const MAX_HEALTH_BY_KIND: Dictionary = {Kind.SHELTER: 160.0, Kind.WALL: 100.0}
const MIN_CLEARANCE: float = 72.0
const FOOTPRINT_SIZE: Vector2 = Vector2(128.0, 40.0)

var _kind: Kind
var _position: Vector2
var _health: float


func _init(kind: Kind = Kind.WALL, position: Vector2 = Vector2.ZERO) -> void:
	_kind = kind if kind in [Kind.SHELTER, Kind.WALL] else Kind.WALL
	_position = position
	_health = float(MAX_HEALTH_BY_KIND[_kind])


func is_position_valid(bounds: Rect2, occupied_positions: Array) -> bool:
	var footprint: Rect2 = Rect2(_position - FOOTPRINT_SIZE * 0.5, FOOTPRINT_SIZE)
	if not bounds.encloses(footprint):
		return false
	for occupied: Variant in occupied_positions:
		if occupied is Vector2 and (occupied as Vector2).distance_to(_position) < MIN_CLEARANCE:
			return false
	return true


func get_footprint() -> Rect2:
	return Rect2(_position - FOOTPRINT_SIZE * 0.5, FOOTPRINT_SIZE)


func take_damage(amount: float) -> bool:
	if not is_finite(amount) or amount <= 0.0 or is_destroyed():
		return false
	_health = maxf(_health - amount, 0.0)
	return true


func is_destroyed() -> bool:
	return is_zero_approx(_health)


func get_kind() -> Kind:
	return _kind


func get_position() -> Vector2:
	return _position


func get_health() -> float:
	return _health


func create_snapshot() -> Dictionary:
	return {"format_version": FORMAT_VERSION, "kind": int(_kind), "position": _position, "health": _health}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["format_version", "kind", "position", "health"]:
		if not snapshot.has(key):
			return false
	var kind: int = int(snapshot["kind"])
	var position: Variant = snapshot["position"]
	var health: float = float(snapshot["health"])
	if int(snapshot["format_version"]) != FORMAT_VERSION or kind not in [Kind.SHELTER, Kind.WALL] \
		or not position is Vector2 or not is_finite(health) or health < 0.0 or health > float(MAX_HEALTH_BY_KIND[kind]):
		return false
	_kind = kind as Kind
	_position = position
	_health = health
	return true
