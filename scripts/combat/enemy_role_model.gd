extends RefCounted
class_name EnemyRoleModel

## 普通敌人的职责差异：追猎、调查和攻坚只决定目标偏好与脱战边界。

enum Role {
	HUNTER,
	INVESTIGATOR,
	SIEGE,
}

const INVESTIGATOR_SOUND_MULTIPLIER: float = 1.333333
const SIEGE_SOUND_MULTIPLIER: float = 0.666667
const HUNTER_DISENGAGE_DISTANCE_STEPS: float = 32.0
const INVESTIGATOR_DISENGAGE_DISTANCE_STEPS: float = 24.0


func get_sound_radius_steps(role: int, base_radius_steps: float) -> float:
	var base: float = maxf(base_radius_steps, 0.0)
	match role:
		Role.INVESTIGATOR:
			return base * INVESTIGATOR_SOUND_MULTIPLIER
		Role.SIEGE:
			return base * SIEGE_SOUND_MULTIPLIER
		_:
			return base


func should_disengage(role: int, distance_steps: float, health_ratio: float) -> bool:
	if not is_finite(distance_steps) or not is_finite(health_ratio):
		return true
	if role == Role.SIEGE:
		return false
	var limit: float = INVESTIGATOR_DISENGAGE_DISTANCE_STEPS if role == Role.INVESTIGATOR else HUNTER_DISENGAGE_DISTANCE_STEPS
	return distance_steps > limit and health_ratio > 0.25


func choose_target(role: int, has_visual_target: bool, has_sound_clue: bool, has_objective_target: bool) -> StringName:
	if role == Role.SIEGE and has_objective_target:
		return &"objective"
	if role == Role.INVESTIGATOR and has_sound_clue and not has_visual_target:
		return &"sound"
	if has_visual_target:
		return &"player"
	if has_sound_clue:
		return &"sound"
	return &"none"
