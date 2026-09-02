extends RefCounted
class_name NightFogModel

## 夜间三阶段迷雾；白天只保留固定污染区，不新增迷雾范围。

enum Phase { DAY, NIGHT_PHASE_1, NIGHT_PHASE_2, NIGHT_PHASE_3 }
const NIGHT_PHASE_SECONDS: float = 120.0
const NIGHT_DURATION_SECONDS: float = 360.0
const FOG_RADIUS_RATIO_BY_PHASE: Dictionary = {
	Phase.DAY: 0.20,
	Phase.NIGHT_PHASE_1: 0.35,
	Phase.NIGHT_PHASE_2: 0.60,
	Phase.NIGHT_PHASE_3: 0.90,
}


func get_phase(night_elapsed_seconds: float, is_night: bool) -> Phase:
	if not is_night:
		return Phase.DAY
	var elapsed: float = clampf(night_elapsed_seconds, 0.0, NIGHT_DURATION_SECONDS)
	if elapsed < NIGHT_PHASE_SECONDS:
		return Phase.NIGHT_PHASE_1
	if elapsed < NIGHT_PHASE_SECONDS * 2.0:
		return Phase.NIGHT_PHASE_2
	return Phase.NIGHT_PHASE_3


func get_fog_radius_ratio(night_elapsed_seconds: float, is_night: bool) -> float:
	return float(FOG_RADIUS_RATIO_BY_PHASE[get_phase(night_elapsed_seconds, is_night)])


func is_in_fog(distance_from_safe_center: float, map_radius: float, night_elapsed_seconds: float, is_night: bool) -> bool:
	if not is_finite(distance_from_safe_center) or not is_finite(map_radius) or map_radius <= 0.0:
		return true
	return distance_from_safe_center >= map_radius * get_fog_radius_ratio(night_elapsed_seconds, is_night)


func create_snapshot() -> Dictionary:
	return {"format_version": 1}


func restore_snapshot(snapshot: Dictionary) -> bool:
	return int(snapshot.get("format_version", -1)) == 1
