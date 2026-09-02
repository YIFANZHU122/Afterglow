extends RefCounted
class_name RegionRouteModel

const REGION_PROFILE_MODEL_SCRIPT: Script = preload("res://scripts/world/region_profile_model.gd")


func generate(floor_number: int, map_seed: int) -> Dictionary:
	var region_id: StringName = _region_id_for_floor(floor_number)
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(map_seed) + maxi(floor_number, 1) * 7919
	var base_cost: int = rng.randi_range(0, 1)
	return {
		"format_version": 1,
		"region_id": region_id,
		"map_seed": map_seed,
		"routes": [
			{"id": &"base", "required_tool": &"", "risk": 1 + base_cost},
			{"id": &"ability", "required_tool": &"traversal", "risk": 2 + base_cost},
			{"id": &"resource", "required_tool": &"optional", "risk": 3 + base_cost},
		],
		"profile": REGION_PROFILE_MODEL_SCRIPT.new().get_profile(region_id),
	}


func validate_generated(route_data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if int(route_data.get("format_version", -1)) != 1:
		errors.append("unsupported route profile version")
	var region_id: StringName = StringName(route_data.get("region_id", ""))
	if REGION_PROFILE_MODEL_SCRIPT.new().get_profile(region_id).is_empty():
		errors.append("route profile has an unknown region")
	var routes: Array = route_data.get("routes", []) as Array
	var has_base := false
	var has_ability := false
	for route: Variant in routes:
		if not route is Dictionary:
			errors.append("route entry is invalid")
			continue
		if StringName(route.get("id", "")) == &"base":
			has_base = true
		if StringName(route.get("id", "")) == &"ability":
			has_ability = true
		if int(route.get("risk", -1)) < 0:
			errors.append("route risk must be non-negative")
	if not has_base:
		errors.append("generated route is missing a base path")
	if not has_ability:
		errors.append("generated route is missing an ability path")
	return errors


func _region_id_for_floor(floor_number: int) -> StringName:
	match floor_number:
		1: return &"basement"
		2: return &"cihang_outskirts"
		3: return &"flooded_settlement"
		4: return &"abandoned_industry"
		5: return &"polluted_forest"
		6: return &"final_core"
		_: return &""
