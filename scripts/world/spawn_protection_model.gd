extends RefCounted
class_name SpawnProtectionModel

## 刷新点领域校验；像素与 step 的换算由调用方负责。

const PLAYER_MIN_DISTANCE_STEPS: float = 8.0
const PROTECTED_POINT_RADIUS_STEPS: float = 4.0


func is_protected(
	candidate: Vector2,
	player_position: Vector2,
	protected_points: Array[Vector2],
	is_visible: bool,
	in_fog: bool
) -> bool:
	if not candidate.is_finite() or not player_position.is_finite():
		return true
	if is_visible or not in_fog:
		return true
	if candidate.distance_to(player_position) < PLAYER_MIN_DISTANCE_STEPS:
		return true
	for protected_point: Vector2 in protected_points:
		if protected_point.is_finite() and candidate.distance_to(protected_point) <= PROTECTED_POINT_RADIUS_STEPS:
			return true
	return false


func is_valid_spawn(
	candidate: Vector2,
	player_position: Vector2,
	protected_points: Array[Vector2],
	is_visible: bool,
	in_fog: bool
) -> bool:
	return not is_protected(candidate, player_position, protected_points, is_visible, in_fog)
