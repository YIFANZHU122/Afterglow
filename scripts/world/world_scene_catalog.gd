extends RefCounted
class_name WorldSceneCatalog

const BASEMENT_SCENE_ID: StringName = &"basement"
const CIHANG_OUTSKIRTS_SCENE_ID: StringName = &"cihang_outskirts"
const FINAL_CORE_SCENE_ID: StringName = &"final_core"

const BASEMENT_SCENE_PATH: String = "res://scenes/world/basement/basement.tscn"
const CIHANG_OUTSKIRTS_SCENE_PATH: String = "res://scenes/world/cihang_outskirts/cihang_outskirts.tscn"
const FINAL_CORE_SCENE_PATH: String = "res://scenes/world/final_core/final_core.tscn"
const DEFAULT_SPAWN_POINT: StringName = &"PlayerSpawn"

const BASEMENT_SPAWN_POINTS: Array[StringName] = [&"PlayerSpawn", &"FromCihangSpawn"]
const CIHANG_OUTSKIRTS_SPAWN_POINTS: Array[StringName] = [&"PlayerSpawn", &"FromBasementSpawn"]
const FINAL_CORE_SPAWN_POINTS: Array[StringName] = [&"PlayerSpawn"]


func get_scene_id(floor_number: int) -> StringName:
	match floor_number:
		1:
			return BASEMENT_SCENE_ID
		2, 3, 4, 5:
			return CIHANG_OUTSKIRTS_SCENE_ID
		6:
			return FINAL_CORE_SCENE_ID
		_:
			return StringName()


func get_scene_path(floor_number: int) -> String:
	match floor_number:
		1:
			return BASEMENT_SCENE_PATH
		2, 3, 4, 5:
			return CIHANG_OUTSKIRTS_SCENE_PATH
		6:
			return FINAL_CORE_SCENE_PATH
		_:
			return ""


func get_default_spawn_point(floor_number: int) -> StringName:
	if get_scene_id(floor_number).is_empty():
		return StringName()
	return DEFAULT_SPAWN_POINT


func is_valid_spawn_point(floor_number: int, spawn_point_name: StringName) -> bool:
	if spawn_point_name.is_empty():
		return false
	var scene_id: StringName = get_scene_id(floor_number)
	match scene_id:
		BASEMENT_SCENE_ID:
			return spawn_point_name in BASEMENT_SPAWN_POINTS
		CIHANG_OUTSKIRTS_SCENE_ID:
			return spawn_point_name in CIHANG_OUTSKIRTS_SPAWN_POINTS
		FINAL_CORE_SCENE_ID:
			return spawn_point_name in FINAL_CORE_SPAWN_POINTS
		_:
			return false


func is_valid_location(floor_number: int, scene_id: StringName, scene_path: String) -> bool:
	var expected_scene_id: StringName = get_scene_id(floor_number)
	var expected_scene_path: String = get_scene_path(floor_number)
	return not expected_scene_id.is_empty() and scene_id == expected_scene_id and scene_path == expected_scene_path
