extends RefCounted
class_name CampfireModel

## 篝火运行时领域状态：燃料、稳定、点火和天气燃烧倍率。

enum IgnitionMethod { LIGHTER, STONE }
enum Weather { CLEAR, RAIN, STORM }

const FORMAT_VERSION: int = 1
const STONE_IGNITION_SUCCESS_CHANCE: float = 0.30
const RAIN_BURN_MULTIPLIER: float = 1.50
const STORM_BURN_MULTIPLIER: float = 1.75
const SHELTER_BURN_MULTIPLIER: float = 1.00
const LIGHT_RADIUS: float = 280.0
const MAX_STABILITY: float = 1.0

var _fuel_seconds: float = 0.0
var _stability: float = MAX_STABILITY
var _lit: bool = false


func add_fuel(seconds: float) -> bool:
	if not is_finite(seconds) or seconds <= 0.0 or _stability <= 0.0:
		return false
	_fuel_seconds += seconds
	return true


func ignite(method: IgnitionMethod, roll: float) -> bool:
	if _lit or _fuel_seconds <= 0.0 or _stability <= 0.0:
		return false
	if method == IgnitionMethod.LIGHTER:
		_lit = true
		return true
	if method != IgnitionMethod.STONE or not is_finite(roll) or roll < 0.0 or roll > 1.0 or roll >= STONE_IGNITION_SUCCESS_CHANCE:
		return false
	_lit = true
	return true


func extinguish() -> bool:
	if not _lit:
		return false
	_lit = false
	return true


func advance(delta: float, weather: Weather, sheltered: bool) -> bool:
	if delta <= 0.0 or not is_finite(delta) or not _lit:
		return false
	var multiplier: float = 1.0
	if sheltered:
		multiplier = SHELTER_BURN_MULTIPLIER
	else:
		match weather:
			Weather.RAIN:
				multiplier = RAIN_BURN_MULTIPLIER
			Weather.STORM:
				multiplier = STORM_BURN_MULTIPLIER
	_fuel_seconds = maxf(_fuel_seconds - delta * multiplier, 0.0)
	if is_zero_approx(_fuel_seconds):
		_lit = false
	return true


func take_damage(amount: float) -> bool:
	if not is_finite(amount) or amount <= 0.0:
		return false
	_stability = clampf(_stability - amount / 100.0, 0.0, MAX_STABILITY)
	if is_zero_approx(_stability):
		_lit = false
	return true


func is_lit() -> bool:
	return _lit


func get_fuel_seconds() -> float:
	return _fuel_seconds


func get_stability() -> float:
	return _stability


func get_light_radius() -> float:
	return LIGHT_RADIUS if _lit else 0.0


func create_snapshot() -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"fuel_seconds": _fuel_seconds,
		"stability": _stability,
		"lit": _lit,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["format_version", "fuel_seconds", "stability", "lit"]:
		if not snapshot.has(key):
			return false
	var fuel: float = float(snapshot["fuel_seconds"])
	var stability: float = float(snapshot["stability"])
	if int(snapshot["format_version"]) != FORMAT_VERSION or not is_finite(fuel) or not is_finite(stability) \
		or fuel < 0.0 or stability < 0.0 or stability > MAX_STABILITY or snapshot["lit"] is not bool:
		return false
	if bool(snapshot["lit"]) and (fuel <= 0.0 or stability <= 0.0):
		return false
	_fuel_seconds = fuel
	_stability = stability
	_lit = bool(snapshot["lit"])
	return true
