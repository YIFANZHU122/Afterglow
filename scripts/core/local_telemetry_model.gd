extends RefCounted
class_name LocalTelemetryModel

var _death_reasons: Dictionary = {}
var _floor_departures: Array[Dictionary] = []


func record_death(reason: StringName) -> bool:
	if reason.is_empty():
		return false
	var key := String(reason)
	_death_reasons[key] = int(_death_reasons.get(key, 0)) + 1
	return true


func record_floor_departure(elapsed_seconds: float, remaining_resources: int) -> bool:
	if not is_finite(elapsed_seconds) or elapsed_seconds < 0.0 or remaining_resources < 0:
		return false
	_floor_departures.append({"elapsed_seconds": elapsed_seconds, "remaining_resources": remaining_resources})
	return true


func clear() -> bool:
	_death_reasons.clear()
	_floor_departures.clear()
	return true


func create_snapshot() -> Dictionary:
	return {"death_reasons": _death_reasons.duplicate(true), "floor_departures": _floor_departures.duplicate(true)}
