extends RefCounted
class_name DisasterCountermeasureModel

## 普通灾难多解，困难灾难仅允许公开的主设施解决核心威胁。

const ORDINARY_OPTIONS: Dictionary = {
	0: [&"shelter", &"evacuate"],
	1: [&"water_reserve", &"shade"],
	2: [&"light_beacon", &"evacuate"],
	3: [&"fire", &"insulate"],
	4: [&"hide", &"thin_the_wave"],
	5: [&"relocate", &"block_spawn"],
}
const HARD_PRIMARY: Dictionary = {
	6: &"flood_gate",
	7: &"purifier",
	8: &"signal_suppressor",
	9: &"hunter_lure",
}


func get_options(kind: int) -> Array[StringName]:
	if HARD_PRIMARY.has(kind):
		return [HARD_PRIMARY[kind]]
	if ORDINARY_OPTIONS.has(kind):
		return (ORDINARY_OPTIONS[kind] as Array).duplicate()
	return []


func can_resolve(kind: int, method: StringName) -> bool:
	if HARD_PRIMARY.has(kind):
		return HARD_PRIMARY[kind] == method
	return get_options(kind).has(method)
