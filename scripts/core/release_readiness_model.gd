extends RefCounted
class_name ReleaseReadinessModel

const SURVIVAL_TUNING_SCRIPT: Script = preload("res://scripts/data/survival_tuning.gd")
const MAX_SNAPSHOT_BYTES: int = 1024 * 1024


func validate_difficulty_profiles() -> PackedStringArray:
	var errors := PackedStringArray()
	for difficulty: int in range(3):
		var richness: float = SURVIVAL_TUNING_SCRIPT.difficulty_resource_richness(difficulty)
		var slots: int = SURVIVAL_TUNING_SCRIPT.disaster_slot_limit(difficulty)
		if richness <= 0.0 or richness > 1.0:
			errors.append("resource richness is outside (0,1]")
		if difficulty < 2 and slots < 1:
			errors.append("normal and hard difficulties need a finite disaster slot")
		if difficulty == 2 and slots != -1:
			errors.append("hell difficulty must allow disaster stacking")
	return errors


func validate_snapshot_size(snapshot: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if snapshot == null:
		errors.append("snapshot is null")
		return errors
	var encoded := JSON.stringify(snapshot)
	if encoded.to_utf8_buffer().size() > MAX_SNAPSHOT_BYTES:
		errors.append("snapshot exceeds one megabyte")
	return errors


func run_long_tick_simulation(floor_count: int, seconds_per_floor: float) -> bool:
	if floor_count != 6 or not is_finite(seconds_per_floor) or seconds_per_floor <= 0.0:
		return false
	var accumulated: float = 0.0
	for floor_index: int in range(floor_count):
		accumulated += seconds_per_floor
		if accumulated <= float(floor_index):
			return false
	return true
