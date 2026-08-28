extends Node

const WORLD_SCENE_CATALOG_SCRIPT: Script = preload("res://scripts/world/world_scene_catalog.gd")

var _failures: int = 0


func _ready() -> void:
	var catalog: RefCounted = WORLD_SCENE_CATALOG_SCRIPT.new()
	_assert_equal(catalog.get_scene_id(1), &"basement", "floor one maps to the basement")
	_assert_equal(
		catalog.get_scene_path(1),
		"res://scenes/world/basement/basement.tscn",
		"floor one uses the basement scene path"
	)
	_assert_equal(catalog.get_default_spawn_point(1), &"PlayerSpawn", "floor one uses the default player spawn")

	for floor_number in range(2, 6):
		_assert_equal(catalog.get_scene_id(floor_number), &"cihang_outskirts", "middle floor maps to Cihang outskirts")
		_assert_equal(
			catalog.get_scene_path(floor_number),
			"res://scenes/world/cihang_outskirts/cihang_outskirts.tscn",
			"middle floor uses the Cihang outskirts scene path"
		)
		_assert_equal(
			catalog.get_default_spawn_point(floor_number),
			&"PlayerSpawn",
			"middle floor uses the deterministic default player spawn"
		)

	_assert_equal(catalog.get_scene_id(6), &"final_core", "floor six maps to the final core")
	_assert_equal(
		catalog.get_scene_path(6),
		"res://scenes/world/final_core/final_core.tscn",
		"floor six uses the final core scene path"
	)
	_assert_equal(catalog.get_default_spawn_point(6), &"PlayerSpawn", "floor six uses the default player spawn")
	_assert_true(catalog.is_valid_spawn_point(1, &"PlayerSpawn"), "basement player spawn is valid")
	_assert_true(catalog.is_valid_spawn_point(1, &"FromCihangSpawn"), "basement Cihang return spawn is valid")
	_assert_true(catalog.is_valid_spawn_point(3, &"PlayerSpawn"), "Cihang player spawn is valid")
	_assert_true(catalog.is_valid_spawn_point(3, &"FromBasementSpawn"), "Cihang basement return spawn is valid")
	_assert_true(catalog.is_valid_spawn_point(6, &"PlayerSpawn"), "final core player spawn is valid")
	_assert_true(not catalog.is_valid_spawn_point(1, &"MissingSpawn"), "unknown basement spawn is rejected")
	_assert_true(not catalog.is_valid_spawn_point(3, &"PlayerSpawn/Child"), "nested spawn path is rejected")
	_assert_true(not catalog.is_valid_spawn_point(6, &"FromBasementSpawn"), "unsupported final core spawn is rejected")
	_assert_true(not catalog.is_valid_spawn_point(0, &"PlayerSpawn"), "invalid floor spawn is rejected")

	_assert_true(
		catalog.is_valid_location(1, &"basement", "res://scenes/world/basement/basement.tscn"),
		"matching basement location is valid"
	)
	_assert_true(
		catalog.is_valid_location(3, &"cihang_outskirts", "res://scenes/world/cihang_outskirts/cihang_outskirts.tscn"),
		"matching middle location is valid"
	)
	_assert_true(
		catalog.is_valid_location(6, &"final_core", "res://scenes/world/final_core/final_core.tscn"),
		"matching final location is valid"
	)
	_assert_true(not catalog.is_valid_location(0, &"basement", "res://scenes/world/basement/basement.tscn"), "zero floor is rejected")
	_assert_true(not catalog.is_valid_location(7, &"final_core", "res://scenes/world/final_core/final_core.tscn"), "floor seven is rejected")
	_assert_true(not catalog.is_valid_location(1, &"cihang_outskirts", "res://scenes/world/basement/basement.tscn"), "mismatched scene id is rejected")
	_assert_true(not catalog.is_valid_location(1, &"basement", "res://scenes/world/cihang_outskirts/cihang_outskirts.tscn"), "mismatched scene path is rejected")
	_assert_equal(catalog.get_scene_id(0), StringName(), "invalid floor has no scene id")
	_assert_equal(catalog.get_scene_path(7), "", "invalid floor has no scene path")
	_assert_equal(catalog.get_default_spawn_point(-1), StringName(), "invalid floor has no spawn point")

	if _failures == 0:
		print("World scene catalog test passed")
	else:
		push_error("World scene catalog test failed: %d assertion(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	_assert_true(actual == expected, "%s (actual=%s, expected=%s)" % [message, actual, expected])
