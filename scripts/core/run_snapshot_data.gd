extends RefCounted
class_name RunSnapshotData

## 运行存档固定 schema。各分区由对应领域模型生成，禁止调用方追加未登记的顶层字段。

const CURRENT_SCHEMA_VERSION: int = 1
const REQUIRED_SECTION_NAMES: Array[StringName] = [
	&"run_session_state",
	&"random_stream_state",
	&"survival_state",
	&"boss_state",
	&"escape_state",
	&"disaster_state",
	&"player_state",
	&"enemy_state",
	&"inventory_state",
	&"building_state",
	&"interaction_state",
]

var schema_version: int = CURRENT_SCHEMA_VERSION
var settlement_id: String = ""
var invalidated: bool = false
var run_session_state: Dictionary = {}
var random_stream_state: Dictionary = {}
var survival_state: Dictionary = {}
var boss_state: Dictionary = {}
var escape_state: Dictionary = {}
var disaster_state: Dictionary = {}
var player_state: Dictionary = {}
var enemy_state: Dictionary = {}
var inventory_state: Dictionary = {}
var building_state: Dictionary = {}
var interaction_state: Dictionary = {}


func to_dictionary() -> Dictionary:
	return {
		"schema_version": schema_version,
		"settlement_id": settlement_id,
		"invalidated": invalidated,
		"run_session_state": run_session_state.duplicate(true),
		"random_stream_state": random_stream_state.duplicate(true),
		"survival_state": survival_state.duplicate(true),
		"boss_state": boss_state.duplicate(true),
		"escape_state": escape_state.duplicate(true),
		"disaster_state": disaster_state.duplicate(true),
		"player_state": player_state.duplicate(true),
		"enemy_state": enemy_state.duplicate(true),
		"inventory_state": inventory_state.duplicate(true),
		"building_state": building_state.duplicate(true),
		"interaction_state": interaction_state.duplicate(true),
	}


func from_dictionary(data: Dictionary) -> bool:
	for key: StringName in [&"schema_version", &"settlement_id", &"invalidated"] + REQUIRED_SECTION_NAMES:
		if not data.has(key):
			return false
	var restored_version: int = int(data["schema_version"])
	if restored_version != CURRENT_SCHEMA_VERSION:
		return false
	if not data["settlement_id"] is String or not data["invalidated"] is bool:
		return false
	var restored_sections: Dictionary = {}
	for section_name: StringName in REQUIRED_SECTION_NAMES:
		if not data[section_name] is Dictionary:
			return false
		restored_sections[section_name] = (data[section_name] as Dictionary).duplicate(true)
	schema_version = restored_version
	settlement_id = data["settlement_id"]
	invalidated = data["invalidated"]
	for section_name: StringName in REQUIRED_SECTION_NAMES:
		set(String(section_name), restored_sections[section_name])
	return true


func is_recoverable() -> bool:
	return schema_version == CURRENT_SCHEMA_VERSION and not invalidated and settlement_id.is_empty()
