extends RefCounted
class_name StepTerrainModel

## 统一世界高度、水深和像素距离的领域换算。

const PIXELS_PER_STEP: float = 40.0
const MAX_DIRECT_TRAVERSAL_STEPS: int = 3

enum TerrainKind {
	OPEN,
	DIRT,
	SAND,
	RUBBLE,
	COLLAPSE,
	STONE,
	WATER,
}


static func pixels_to_steps(distance_px: float) -> int:
	if not is_finite(distance_px):
		return 0
	return abs(roundi(distance_px / PIXELS_PER_STEP))


static func steps_to_pixels(steps: int) -> float:
	return float(maxi(steps, 0)) * PIXELS_PER_STEP


static func can_vault(height_steps: int, has_high_vault: bool = false, encumbrance_ratio: float = 1.0) -> bool:
	if height_steps < 0 or height_steps > MAX_DIRECT_TRAVERSAL_STEPS:
		return false
	if not is_finite(encumbrance_ratio) or encumbrance_ratio > 1.4:
		return false
	if height_steps <= 2:
		return true
	return has_high_vault


static func is_diggable(kind: int) -> bool:
	return kind == TerrainKind.DIRT or kind == TerrainKind.SAND or kind == TerrainKind.RUBBLE or kind == TerrainKind.COLLAPSE


static func is_water_depth(depth_steps: int) -> bool:
	return depth_steps >= 0
