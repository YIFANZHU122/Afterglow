extends RefCounted
class_name MoonCycleModel

## 七夜月相循环：苍月2夜、冷月2夜、绯月2夜、无月1夜。

enum Kind { AZURE, COLD, CRIMSON, NEW }
const NIGHT_SEQUENCE: Array[int] = [Kind.AZURE, Kind.AZURE, Kind.COLD, Kind.COLD, Kind.CRIMSON, Kind.CRIMSON, Kind.NEW]


func get_kind(night_index: int) -> Kind:
	return NIGHT_SEQUENCE[posmod(night_index, NIGHT_SEQUENCE.size())] as Kind


func get_visibility_level(night_index: int) -> int:
	match get_kind(night_index):
		Kind.AZURE:
			return 3
		Kind.COLD:
			return 2
		Kind.CRIMSON:
			return 1
		_:
			return 0


func get_monster_spawn_multiplier(night_index: int) -> float:
	match get_kind(night_index):
		Kind.NEW:
			return 2.0
		_:
			return 0.5 if get_kind(night_index) in [Kind.AZURE, Kind.COLD] else 1.0


func get_special_spawn_ratio(night_index: int) -> float:
	match get_kind(night_index):
		Kind.CRIMSON:
			return 0.5
		Kind.NEW:
			return 0.15
		_:
			return 0.0


func get_enemy_speed_multiplier(night_index: int) -> float:
	return 0.70 if get_kind(night_index) == Kind.COLD else 1.0


func is_new_moon(night_index: int) -> bool:
	return get_kind(night_index) == Kind.NEW


func create_snapshot() -> Dictionary:
	return {"format_version": 1}


func restore_snapshot(snapshot: Dictionary) -> bool:
	return int(snapshot.get("format_version", -1)) == 1
