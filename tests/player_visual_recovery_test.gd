extends Node

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player/player.tscn")

var _failures: int = 0


func _ready() -> void:
	var player: Node = PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame
	var presenter: Node = player.get_node("Presenter")
	var visual: AnimatedSprite2D = presenter.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_assert_true(presenter is Node2D, "player presenter preserves 2D transform inheritance")
	player.global_position = Vector2(320.0, 240.0)
	_assert_true(visual.global_position.is_equal_approx(player.global_position), "player visual follows the CharacterBody2D world position")
	visual.visible = false
	presenter.call("set_dead", false)
	_assert_true(visual.visible, "set_dead(false) restores a hidden live player visual")
	if _failures == 0:
		print("Player visual recovery test passed")
	else:
		push_error("Player visual recovery test failed: %d assertion(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
