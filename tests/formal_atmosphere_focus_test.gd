extends Node

const PRESENTER_SCENE: PackedScene = preload("res://scenes/presentation/world_environment_presenter.tscn")

var _failures: int = 0


func _ready() -> void:
	var presenter: Node = PRESENTER_SCENE.instantiate()
	add_child(presenter)
	await get_tree().process_frame
	_assert_true(presenter.get_node_or_null("SkyCanvas/SkyLayer") != null, "presenter owns a formal sky layer")
	_assert_true(presenter.get_node_or_null("SkyCanvas/HorizonGlow") != null, "presenter owns a wasteland horizon glow")
	var wasteland_silhouette: Polygon2D = presenter.get_node_or_null("SkyCanvas/WastelandSilhouette") as Polygon2D
	_assert_true(wasteland_silhouette != null, "presenter owns a wasteland silhouette")
	_assert_true(
		wasteland_silhouette != null and not wasteland_silhouette.visible,
		"top-down gameplay disables the screen-fixed wasteland silhouette"
	)
	_assert_true(presenter.get_node_or_null("EnvironmentCanvas/HeatHaze") != null, "presenter owns a heat haze animation layer")
	_assert_true(presenter.get_node_or_null("EnvironmentCanvas/FrostEdge") != null, "presenter owns a frost animation layer")
	_assert_true(presenter.get_node_or_null("EnvironmentCanvas/WeatherAudio") != null, "presenter owns a weather audio player")
	_assert_true(presenter.get_node_or_null("EnvironmentCanvas/PostProcessLayer") != null, "presenter owns a post-process layer")

	presenter.call("present_disaster", 1, 2)
	_assert_true(bool(presenter.get_node("EnvironmentCanvas/HeatHaze").visible), "heatwave enables heat haze")
	_assert_true(float(presenter.get_node("EnvironmentCanvas/PostProcessLayer").modulate.a) > 0.0, "weather enables post processing")
	presenter.call("present_disaster", 3, 2)
	_assert_true(bool(presenter.get_node("EnvironmentCanvas/FrostEdge").visible), "cold snap enables frost edge")
	presenter.call("present_disaster", 999, 0)
	_assert_true(not bool(presenter.get_node("EnvironmentCanvas/HeatHaze").visible), "invalid disaster clears heat haze")

	presenter.call("present_survival", 1, true)
	presenter.call("present_anomaly", 1, 0.75)
	_assert_equal(presenter.call("get_anomaly_kind"), 1, "aberrant moon anomaly is retained")
	_assert_equal(presenter.call("get_anomaly_intensity"), 0.75, "anomaly intensity is retained")
	_assert_true(bool(presenter.get_node("EnvironmentCanvas/AnomalyMoon").visible), "aberrant moon overlay is visible")
	presenter.call("present_anomaly", 999, 4.0)
	_assert_equal(presenter.call("get_anomaly_kind"), 0, "invalid anomaly falls back to none")
	_assert_equal(presenter.call("get_anomaly_intensity"), 0.0, "invalid anomaly clears intensity")
	presenter.call("present_anomaly", 2, 0.5)
	_assert_true(bool(presenter.get_node("EnvironmentCanvas/PollutionSky").visible), "polluted sky anomaly is visible")
	presenter.call("present_anomaly", 3, 0.5)
	_assert_true(bool(presenter.get_node("EnvironmentCanvas/CelestialRift").visible), "celestial rift anomaly is visible")

	presenter.call("present_san", 0.25)
	_assert_equal(presenter.call("get_san_intensity"), 0.75, "SAN intensity inverts remaining sanity")
	_assert_true(float(presenter.get_node("EnvironmentCanvas/SanVignette").modulate.a) > 0.0, "low SAN enables vignette")
	presenter.call("present_san", 2.0)
	_assert_equal(presenter.call("get_san_intensity"), 0.0, "full sanity clears SAN intensity")

	if _failures == 0:
		print("Formal atmosphere focus test passed")
	else:
		push_error("Formal atmosphere focus test failed: %d assertion(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	_assert_true(actual == expected, "%s (actual=%s, expected=%s)" % [message, actual, expected])
