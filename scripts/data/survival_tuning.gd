extends RefCounted
class_name SurvivalTuning

## 生存系统的首版集中配置；不保存运行时状态。

enum Difficulty {
	NORMAL,
	HARD,
	HELL,
}

const STATE_MAX: float = 100.0
const INITIAL_HUNGER: float = 30.0
const INITIAL_WATER: float = 50.0
const HUNGER_SECONDS_PER_POINT: float = 36.0
const WATER_SECONDS_PER_POINT: float = 27.0
const LIGHT_PENALTY_THRESHOLD: float = 20.0
const CRITICAL_THRESHOLD: float = 5.0
const ZERO_WARNING_SECONDS: float = 5.0
const ENVIRONMENT_DAMAGE_RATIO_PER_SECOND: float = 0.01

const DAY_DURATION_SECONDS: float = 720.0
const NIGHT_DURATION_SECONDS: float = 360.0
const CYCLE_DURATION_SECONDS: float = DAY_DURATION_SECONDS + NIGHT_DURATION_SECONDS
const NORMAL_STAY_DURATION_SECONDS: float = 3240.0
const OVERTIME_STAGE_SECONDS: float = 1080.0

const DISASTER_CHECK_INTERVAL_SECONDS: float = 60.0
const DISASTER_MISS_BONUS: float = 0.05
const DISASTER_PROBABILITY_MAX: float = 0.80
const SAME_DISASTER_COOLDOWN_SECONDS: float = 600.0
const SAME_DISASTER_OTHER_EVENT_COUNT: int = 2


static func normalize_difficulty(difficulty: int) -> Difficulty:
	if difficulty == Difficulty.HARD:
		return Difficulty.HARD
	if difficulty == Difficulty.HELL:
		return Difficulty.HELL
	return Difficulty.NORMAL


static func difficulty_resource_richness(difficulty: int) -> float:
	match normalize_difficulty(difficulty):
		Difficulty.HARD:
			return 0.95
		Difficulty.HELL:
			return 0.90
		_:
			return 1.0


static func difficulty_consumption_multiplier(difficulty: int) -> float:
	match normalize_difficulty(difficulty):
		Difficulty.HARD:
			return 1.05
		Difficulty.HELL:
			return 1.10
		_:
			return 1.0


static func difficulty_disaster_multiplier(difficulty: int) -> float:
	match normalize_difficulty(difficulty):
		Difficulty.HARD:
			return 1.25
		Difficulty.HELL:
			return 1.50
		_:
			return 1.0


static func disaster_slot_limit(difficulty: int) -> int:
	match normalize_difficulty(difficulty):
		Difficulty.HARD:
			return 2
		Difficulty.HELL:
			return -1
		_:
			return 1


static func disaster_base_probability(day_index: int) -> float:
	if day_index <= 1:
		return 0.05
	if day_index == 2:
		return 0.10
	return 0.15


static func overtime_probability_bonus(overtime_stage: int) -> float:
	if overtime_stage <= 0:
		return 0.0
	var full_rate_stages: int = mini(overtime_stage, 2)
	var reduced_rate_stages: int = maxi(overtime_stage - full_rate_stages, 0)
	return float(full_rate_stages) * 0.05 + float(reduced_rate_stages) * 0.03


static func hard_disaster_weight(difficulty: int, elapsed_seconds: float) -> float:
	if elapsed_seconds < CYCLE_DURATION_SECONDS:
		return 0.0
	var is_overtime: bool = elapsed_seconds > NORMAL_STAY_DURATION_SECONDS
	var day_index: int = int(floor(elapsed_seconds / CYCLE_DURATION_SECONDS)) + 1
	match normalize_difficulty(difficulty):
		Difficulty.HARD:
			if is_overtime:
				return 0.30
			return 0.10 if day_index == 2 else 0.20
		Difficulty.HELL:
			if is_overtime:
				return 0.40
			return 0.20 if day_index == 2 else 0.30
		_:
			if is_overtime:
				return 0.20
			return 0.05 if day_index == 2 else 0.10
