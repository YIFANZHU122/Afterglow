extends Node

const PRESENTER_SCENE: PackedScene = preload("res://scenes/presentation/world_environment_presenter.tscn")

const PHASE_IDLE: int = 0
const PHASE_WARNING: int = 1
const PHASE_ACTIVE: int = 2

var _failures: int = 0


func _ready() -> void:
	# Reproduce a presenter entering after the global state has already changed.
	GameManager.reset_run()
	_assert_true(GameManager.start_run(), "late presenter fixture can start a run")
	_assert_true(GameManager.prepare_floor(), "late presenter fixture can prepare a floor")
	GameManager.tick_survival(720.0)
	_assert_true(GameManager.is_floor_night(), "late presenter fixture reaches night before instantiation")
	_assert_true(GameManager.start_disaster(0), "late presenter fixture starts a rainstorm warning")

	var presenter: Node = PRESENTER_SCENE.instantiate()
	add_child(presenter)
	await get_tree().process_frame
	_assert_true(bool(presenter.get_node("EnvironmentCanvas/MoonSprite").visible), "late presenter syncs the existing night state")
	_assert_equal(presenter.call("get_weather_mode"), &"rainstorm", "late presenter syncs the existing disaster mode")
	_assert_equal(presenter.call("get_weather_strength"), 0.35, "late presenter syncs the existing warning strength")

	presenter.call("present_survival", 0, true)
	_assert_equal(presenter.call("get_moon_phase_index"), 0, "non-positive day indexes fall back to new moon")
	_assert_true(bool(presenter.get_node("EnvironmentCanvas/MoonSprite").visible), "night shows the moon")
	_assert_true(float(presenter.get_node("EnvironmentCanvas/DayNightTint").color.a) > 0.0, "night applies a readable dusk tint")
	_assert_true(bool(presenter.get_node("EnvironmentCanvas/FogLayer").visible), "night fog layer expands with the night phase")

	presenter.call("present_survival", 9, true)
	_assert_equal(presenter.call("get_moon_phase_index"), 0, "moon phases wrap every eight days")
	_assert_true(str(presenter.get_node("EnvironmentCanvas/MoonSprite").texture.resource_path).ends_with("moon_00_new.png"), "moon texture follows the wrapped phase")
	presenter.call("present_survival", 8, true)
	_assert_equal(presenter.call("get_moon_phase_index"), 7, "day eight shows the eighth moon phase")
	presenter.call("present_survival", 8, false)
	_assert_true(not bool(presenter.get_node("EnvironmentCanvas/MoonSprite").visible), "day hides the moon")
	_assert_equal(presenter.get_node("EnvironmentCanvas/DayNightTint").color.a, 0.0, "day clears the dusk tint")

	for kind_and_mode in [
		[0, &"rainstorm"],
		[1, &"heatwave"],
		[2, &"dense_fog"],
		[3, &"cold_snap"],
	]:
		presenter.call("present_disaster", kind_and_mode[0], PHASE_WARNING)
		_assert_equal(presenter.call("get_weather_mode"), kind_and_mode[1], "warning maps the known disaster kind")
		_assert_equal(presenter.call("get_weather_strength"), 0.35, "warning uses a readable low overlay strength")
		presenter.call("present_disaster", kind_and_mode[0], PHASE_ACTIVE)
		_assert_equal(presenter.call("get_weather_strength"), 1.0, "active disaster uses the full overlay strength")

	presenter.call("present_disaster", 999, PHASE_ACTIVE)
	_assert_equal(presenter.call("get_weather_mode"), &"clear", "unknown disasters fall back to the clear presentation")
	_assert_equal(presenter.call("get_weather_strength"), 0.0, "unknown disasters disable the weather overlay")
	presenter.call("present_disaster", -1, PHASE_IDLE)
	_assert_equal(presenter.call("get_weather_mode"), &"clear", "idle disasters restore the clear presentation")

	if _failures == 0:
		print("World environment presenter focus test passed")
	else:
		push_error("World environment presenter focus test failed: %d assertion(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	_assert_true(actual == expected, "%s (actual=%s, expected=%s)" % [message, actual, expected])
