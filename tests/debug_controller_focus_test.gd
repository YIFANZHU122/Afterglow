extends Node

const BASEMENT_SCENE: PackedScene = preload("res://scenes/world/basement/basement.tscn")

var _failures: int = 0


func _ready() -> void:
	GameManager.reset_run()
	var basement := BASEMENT_SCENE.instantiate()
	add_child(basement)
	await get_tree().process_frame
	var controller: Node = basement.get_node_or_null("DebugController")
	_assert_true(controller != null, "world scene instantiates the debug controller")
	if controller != null:
		_assert_true(not bool(controller.get_node("DebugPanel").visible), "debug panel starts hidden")
		_assert_equal(controller.call("spawn_preview_monsters", 2), 2, "debug controller spawns two isolated monsters")
		await get_tree().process_frame
		var preview_root: Node = basement.get_node_or_null("DebugPreviewRoot")
		_assert_true(preview_root != null and preview_root.get_child_count() == 2, "preview monsters live under the isolated debug root")
		if preview_root != null and preview_root.get_child_count() > 0:
			var monster := preview_root.get_child(0) as Node2D
			var rift_sprite := monster.get_node_or_null("Presenter/RiftSprite") as Sprite2D
			_assert_true(rift_sprite != null, "preview monster owns the rift animal sprite")
			if rift_sprite != null:
				_assert_true(rift_sprite.global_position.is_equal_approx(monster.global_position), "rift animal sprite follows the spawned monster position")
		controller.call("preview_weather", &"rainstorm", 0.8)
		var presenter: Node = basement.get_node("WorldEnvironmentPresenter")
		_assert_equal(presenter.call("get_weather_mode"), &"rainstorm", "debug controller selects rainstorm presentation")
		_assert_equal(presenter.call("get_weather_strength"), 0.8, "debug controller applies weather strength")
		var rain := presenter.get_node("EnvironmentCanvas/RainLayer") as GPUParticles2D
		var rain_material := rain.process_material as ParticleProcessMaterial
		_assert_true(rain.position.y <= 32.0, "rain starts at the top edge of the viewport")
		_assert_true(rain_material.emission_box_extents.x >= 600.0, "rain emission covers the full viewport width")
		_assert_true(rain.modulate.a <= 0.65, "rain remains translucent enough to preserve readability")
		controller.call("preview_weather", &"cold_snap", 1.0)
		var snow := presenter.get_node("EnvironmentCanvas/ParticleLayer") as GPUParticles2D
		var snow_material := snow.process_material as ParticleProcessMaterial
		_assert_true(snow.position.y <= 32.0, "snow starts at the top edge of the viewport")
		_assert_true(snow_material.emission_box_extents.x >= 600.0, "snow emission covers the full viewport width")
		_assert_true(snow.modulate.a <= 0.65, "snow remains translucent enough to preserve readability")
		controller.call("preview_weather", &"heatwave", 1.0)
		var heat_haze := presenter.get_node("EnvironmentCanvas/HeatHaze") as CanvasItem
		var heat_material := heat_haze.material as ShaderMaterial
		_assert_true(heat_haze.modulate.a <= 0.15, "heat haze uses a restrained overlay strength")
		_assert_true(heat_material.shader.code.contains("hint_screen_texture"), "heat haze preserves the rendered scene through the screen texture")
		controller.call("preview_anomaly", 2, 0.7)
		_assert_equal(presenter.call("get_anomaly_kind"), 2, "debug controller selects polluted sky anomaly")
		controller.call("preview_san", 0.25)
		_assert_true(float(presenter.call("get_san_intensity")) > 0.0, "debug controller enables SAN vignette")
		controller.call("clear_preview_monsters")
		await get_tree().process_frame
		_assert_true(preview_root.get_child_count() == 0, "debug controller clears isolated monsters")
	if _failures == 0:
		print("Debug controller focus test passed")
	else:
		push_error("Debug controller focus test failed: %d assertion(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	_assert_true(actual == expected, "%s (actual=%s, expected=%s)" % [message, actual, expected])
