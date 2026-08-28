extends Node

const DUMMY_SCENE: PackedScene = preload("res://scenes/objects/training_dummy/training_dummy.tscn")
const RECORDING_PRESENTER_SCRIPT: Script = preload("res://tests/recording_actor_presenter.gd")

var _failures: int = 0


func _ready() -> void:
	var dummy: Node2D = DUMMY_SCENE.instantiate() as Node2D
	add_child(dummy)
	await get_tree().process_frame
	var presenter_node: Node = dummy.get_node("Presenter")
	presenter_node.free()
	var presenter: Node = RECORDING_PRESENTER_SCRIPT.new()
	presenter.name = "Presenter"
	dummy.add_child(presenter)
	var has_presenter_property: bool = dummy.get_property_list().any(
		func(property: Dictionary) -> bool: return property.get("name") == "presenter"
	)
	if has_presenter_property:
		dummy.set("presenter", presenter)
	var health: Node = dummy.get_node("HealthComponent")
	health.call("take_damage", 1.0)
	_assert_equal(presenter.get("hit_count"), 1, "damage forwards hit")
	dummy.call("_shoot_at", Vector2(100.0, 100.0))
	_assert_equal((presenter.get("attack_calls") as Array[Vector2]).size(), 1, "shot forwards attack")
	health.call("take_damage", 1000.0)
	_assert_true((presenter.get("dead_values") as Array[bool]).has(true), "death forwards dead state")
	_assert_true((dummy.get_node("Visual") as CanvasItem).visible, "death visibility stays with presenter")
	(dummy.get_node("RespawnTimer") as Timer).stop()
	dummy.call("_on_respawn_timeout")
	var dead_values: Array[bool] = presenter.get("dead_values")
	_assert_true(dead_values.size() >= 2 and dead_values[-1] == false, "respawn clears dead state")
	if _failures == 0:
		print("Training dummy presenter focus test passed")
	else:
		push_error("Training dummy presenter focus test failed: %d assertion(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	_assert_true(actual == expected, "%s (actual=%s, expected=%s)" % [message, actual, expected])
