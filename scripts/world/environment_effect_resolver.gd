extends RefCounted
class_name EnvironmentEffectResolver

## 将天气、灾难和遮蔽聚合为一次性最终环境修正，避免无限乘算。

const MAX_STAMINA_DRAIN_MULTIPLIER: float = 2.0
const MAX_HUNGER_DRAIN_MULTIPLIER: float = 1.5
const MAX_WATER_DRAIN_MULTIPLIER: float = 1.5
const MAX_MONSTER_SPAWN_MULTIPLIER: float = 3.0


func resolve(weather: StringName, disaster_kinds: Array, water_level_steps: int, sheltered: bool) -> Dictionary:
	var result: Dictionary = {
		"water_level_delta": 0,
		"move_speed_multiplier": 1.0,
		"stamina_drain_multiplier": 1.0,
		"hunger_drain_multiplier": 1.0,
		"water_drain_multiplier": 1.0,
		"visibility_multiplier": 1.0,
		"campfire_burn_multiplier": 1.0,
		"monster_spawn_multiplier": 1.0,
		"hazard_damage_per_second": 0.0,
	}
	if weather == &"rain":
		result["water_level_delta"] = 1
		result["campfire_burn_multiplier"] = 1.5 if not sheltered else 1.0
	elif weather == &"heatwave":
		result["water_level_delta"] = -1
		result["stamina_drain_multiplier"] = 1.25
		result["water_drain_multiplier"] = 1.2
		result["hazard_damage_per_second"] = 0.005
	elif weather == &"dense_fog":
		result["visibility_multiplier"] = 0.45
	elif weather == &"cold_snap":
		result["stamina_drain_multiplier"] = 1.2
		result["hunger_drain_multiplier"] = 1.15
	for raw_kind: Variant in disaster_kinds:
		var kind := int(raw_kind)
		match kind:
			0:
				result["water_level_delta"] = int(result["water_level_delta"]) + 1
				result["campfire_burn_multiplier"] = maxf(float(result["campfire_burn_multiplier"]), 1.5 if not sheltered else 1.0)
			1:
				result["water_drain_multiplier"] = maxf(float(result["water_drain_multiplier"]), 1.3)
				result["stamina_drain_multiplier"] = maxf(float(result["stamina_drain_multiplier"]), 1.25)
			2:
				result["visibility_multiplier"] = minf(float(result["visibility_multiplier"]), 0.35)
			3:
				result["stamina_drain_multiplier"] = maxf(float(result["stamina_drain_multiplier"]), 1.35)
			4:
				result["monster_spawn_multiplier"] = maxf(float(result["monster_spawn_multiplier"]), 1.75)
			5:
				result["monster_spawn_multiplier"] = maxf(float(result["monster_spawn_multiplier"]), 1.35)
			6:
				result["water_level_delta"] = int(result["water_level_delta"]) + 2
				result["move_speed_multiplier"] = minf(float(result["move_speed_multiplier"]), 0.65)
			7:
				result["visibility_multiplier"] = minf(float(result["visibility_multiplier"]), 0.25)
				result["hazard_damage_per_second"] = maxf(float(result["hazard_damage_per_second"]), 0.01)
			8:
				result["monster_spawn_multiplier"] = maxf(float(result["monster_spawn_multiplier"]), 2.25)
			9:
				result["monster_spawn_multiplier"] = maxf(float(result["monster_spawn_multiplier"]), 1.5)
		result["stamina_drain_multiplier"] = minf(float(result["stamina_drain_multiplier"]), MAX_STAMINA_DRAIN_MULTIPLIER)
	result["hunger_drain_multiplier"] = minf(float(result["hunger_drain_multiplier"]), MAX_HUNGER_DRAIN_MULTIPLIER)
	result["water_drain_multiplier"] = minf(float(result["water_drain_multiplier"]), MAX_WATER_DRAIN_MULTIPLIER)
	result["monster_spawn_multiplier"] = minf(float(result["monster_spawn_multiplier"]), MAX_MONSTER_SPAWN_MULTIPLIER)
	result["water_level"] = maxi(water_level_steps + int(result["water_level_delta"]), 0)
	return result
