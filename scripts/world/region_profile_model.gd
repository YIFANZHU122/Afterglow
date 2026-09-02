extends RefCounted
class_name RegionProfileModel

## 六张区域的稳定玩法差异配置；不持有运行时状态。

const PROFILES: Dictionary = {
	&"basement": {"display_name": "地下室", "terrain": &"enclosed", "water_depth_bias": 0, "digging_bias": 0, "fog_bias": 0, "resource_bias": 0.80},
	&"cihang_outskirts": {"display_name": "慈航郊外", "terrain": &"mixed_wilderness", "water_depth_bias": 1, "digging_bias": 1, "fog_bias": 1, "resource_bias": 1.00},
	&"flooded_settlement": {"display_name": "淹没聚落", "terrain": &"flooded_rooftops", "water_depth_bias": 3, "digging_bias": 0, "fog_bias": 1, "resource_bias": 0.90},
	&"abandoned_industry": {"display_name": "废弃工区", "terrain": &"industrial_rubble", "water_depth_bias": 1, "digging_bias": 3, "fog_bias": 0, "resource_bias": 0.95},
	&"polluted_forest": {"display_name": "污染林带", "terrain": &"toxic_forest", "water_depth_bias": 1, "digging_bias": 1, "fog_bias": 3, "resource_bias": 0.75},
	&"final_core": {"display_name": "终局核心", "terrain": &"boss_arena", "water_depth_bias": 0, "digging_bias": 0, "fog_bias": 2, "resource_bias": 0.65},
}


func get_profile(region_id: StringName) -> Dictionary:
	if not PROFILES.has(region_id):
		return {}
	return (PROFILES[region_id] as Dictionary).duplicate(true)


func get_all_region_ids() -> Array[StringName]:
	return PROFILES.keys()
