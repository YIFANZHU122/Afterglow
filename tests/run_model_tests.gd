extends SceneTree

const HEALTH_MODEL_SCRIPT: Script = preload("res://scripts/combat/health_model.gd")
const STAMINA_MODEL_SCRIPT: Script = preload("res://scripts/player/stamina_model.gd")
const PLAYER_COMMAND_SCRIPT: Script = preload("res://scripts/player/player_command.gd")
const INVENTORY_MODEL_SCRIPT: Script = preload("res://scripts/items/inventory_model.gd")
const MELEE_ATTACK_MODEL_SCRIPT: Script = preload("res://scripts/combat/melee_attack_model.gd")
const REVIVE_MODEL_SCRIPT: Script = preload("res://scripts/progression/revive_model.gd")
const ITEM_DATA_SCRIPT: Script = preload("res://scripts/item_data.gd")

const MOVE_STATE_WALKING: int = 0
const MOVE_STATE_RUNNING: int = 1
const MOVE_STATE_EXHAUSTED: int = 2

var _failures: int = 0


func _init() -> void:
	_run_health_model_tests()
	_run_stamina_model_tests()
	_run_player_command_tests()
	_run_inventory_model_tests()
	_run_melee_attack_model_tests()
	_run_revive_model_tests()
	if _failures == 0:
		print("Model tests passed")
	else:
		push_error("Model tests failed: %d assertion(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	_assert_true(actual == expected, "%s (actual=%s, expected=%s)" % [message, actual, expected])


func _run_health_model_tests() -> void:
	var clamped_model = HEALTH_MODEL_SCRIPT.new(-25.0)
	_assert_equal(clamped_model.get_max_health(), 0.0, "negative max health is clamped")
	clamped_model.take_damage(1.0)
	_assert_true(clamped_model.is_dead(), "zero-capacity health becomes dead on damage")
	var model = HEALTH_MODEL_SCRIPT.new(100.0)
	_assert_equal(model.get_health(), 100.0, "health starts full")
	model.take_damage(25.0)
	_assert_equal(model.get_health(), 75.0, "positive damage reduces health")
	model.take_damage(-10.0)
	_assert_equal(model.get_health(), 75.0, "negative damage is rejected")
	model.heal(10.0)
	_assert_equal(model.get_health(), 85.0, "positive healing restores health")
	model.heal(-10.0)
	_assert_equal(model.get_health(), 85.0, "negative healing is rejected")
	model.take_damage(1000.0)
	_assert_true(model.is_dead(), "lethal damage marks the model dead")
	model.heal(10.0)
	_assert_equal(model.get_health(), 0.0, "dead model cannot be healed")
	model.take_damage(10.0)
	_assert_equal(model.get_health(), 0.0, "dead model ignores repeated damage")
	model.reset()
	_assert_true(not model.is_dead(), "reset clears the dead state")
	_assert_equal(model.get_health(), 100.0, "reset restores full health")


func _run_stamina_model_tests() -> void:
	var model = STAMINA_MODEL_SCRIPT.new(100.0, 30.0, 15.0)
	_assert_equal(model.get_state(), MOVE_STATE_WALKING, "stamina starts walking")
	model.tick(1.0, Vector2.RIGHT, true)
	_assert_equal(model.get_state(), MOVE_STATE_RUNNING, "sprint request enters running")
	_assert_equal(model.get_stamina(), 100.0, "entering running preserves the current frame stamina")
	model.tick(1.0, Vector2.RIGHT, true)
	_assert_equal(model.get_stamina(), 70.0, "running drains stamina")
	model.tick(3.0, Vector2.RIGHT, true)
	_assert_equal(model.get_state(), MOVE_STATE_EXHAUSTED, "empty stamina enters exhausted")
	_assert_equal(model.get_stamina(), 0.0, "stamina is clamped at zero")
	model.tick(1.0, Vector2.ZERO, false)
	_assert_equal(model.get_stamina(), 15.0, "exhausted state regenerates stamina")
	model.tick(1.0, Vector2.ZERO, false)
	_assert_equal(model.get_state(), MOVE_STATE_WALKING, "reaching the threshold leaves exhaustion")
	model.tick(-1.0, Vector2.RIGHT, true)
	_assert_equal(model.get_stamina(), 30.0, "negative delta is ignored")
	var zero_model = STAMINA_MODEL_SCRIPT.new(0.0, 30.0, 15.0)
	zero_model.tick(1.0, Vector2.RIGHT, true)
	_assert_equal(zero_model.get_stamina(), 0.0, "zero-capacity stamina stays at zero")


func _run_player_command_tests() -> void:
	var command = PLAYER_COMMAND_SCRIPT.new()
	_assert_equal(command.move_direction, Vector2.ZERO, "command defaults to no movement")
	_assert_true(not command.sprint_requested, "command defaults to no sprint")
	_assert_true(not command.attack_pressed, "command defaults to no attack")
	_assert_equal(command.cycle_delta, 0, "command defaults to no slot cycling")
	_assert_equal(command.selected_slot, -1, "command defaults to no direct slot selection")
	_assert_true(not command.drop_pressed, "command defaults to no drop")

	var populated = PLAYER_COMMAND_SCRIPT.new(Vector2.RIGHT, true, true, -1, 4, true)
	_assert_equal(populated.move_direction, Vector2.RIGHT, "command stores movement intent")
	_assert_true(populated.sprint_requested, "command stores sprint intent")
	_assert_true(populated.attack_pressed, "command stores attack edge")
	_assert_equal(populated.cycle_delta, -1, "command stores previous-slot intent")
	_assert_equal(populated.selected_slot, 4, "command stores direct slot intent")
	_assert_true(populated.drop_pressed, "command stores drop edge")

	var clamped = PLAYER_COMMAND_SCRIPT.new(Vector2(2.0, 0.0), false, false, 8, -5, false)
	_assert_equal(clamped.move_direction, Vector2.RIGHT, "command clamps movement length")
	_assert_equal(clamped.cycle_delta, 1, "command clamps slot cycling to one step")
	_assert_equal(clamped.selected_slot, -1, "command rejects negative slot selection")


func _run_inventory_model_tests() -> void:
	var model = INVENTORY_MODEL_SCRIPT.new(2)
	var sword = ITEM_DATA_SCRIPT.new()
	sword.item_type = 1
	sword.attack_damage = 10.0
	_assert_true(model.add_item(sword), "inventory accepts the first item")
	_assert_equal(model.get_selected_item(), sword, "inventory exposes selected item")
	_assert_true(not model.set_selected_slot(-1), "inventory rejects negative slot")
	_assert_true(model.set_selected_slot(1), "inventory selects a valid slot")
	_assert_true(model.add_item(sword), "inventory accepts the second item")
	_assert_true(not model.add_item(sword), "full inventory rejects another item")
	_assert_true(model.cycle_selected(-1), "inventory cycles selected slot")
	_assert_equal(model.get_selected_slot(), 0, "inventory cycle wraps to first slot")
	_assert_equal(model.drop_selected(), sword, "inventory drops selected item")
	_assert_equal(model.drop_selected(), null, "empty selected slot returns null")
	var dropped: Array = model.drop_all()
	_assert_equal(dropped.size(), 1, "drop_all returns remaining items")
	_assert_equal(model.get_items()[0], null, "drop_all clears all slots")


func _run_melee_attack_model_tests() -> void:
	var model = MELEE_ATTACK_MODEL_SCRIPT.new()
	var empty_item = null
	_assert_true(not model.can_attack(empty_item), "melee rejects empty item")
	var potion = ITEM_DATA_SCRIPT.new()
	potion.item_type = 2
	potion.attack_damage = 20.0
	_assert_true(not model.can_attack(potion), "melee rejects non-sword item")
	var zero_sword = ITEM_DATA_SCRIPT.new()
	zero_sword.item_type = 1
	_assert_true(not model.can_attack(zero_sword), "melee rejects zero damage sword")
	var sword = ITEM_DATA_SCRIPT.new()
	sword.item_type = 1
	sword.attack_damage = 20.0
	_assert_true(model.can_attack(sword), "melee accepts positive damage sword")
	_assert_equal(model.get_damage(sword), 20.0, "melee returns sword damage")


func _run_revive_model_tests() -> void:
	var model = REVIVE_MODEL_SCRIPT.new()
	_assert_true(model.is_alive(), "revive model starts alive")
	_assert_true(not model.request(), "alive model rejects revive request")
	_assert_true(model.mark_dead(), "alive model can become dead")
	_assert_true(not model.mark_dead(), "dead model rejects repeated death")
	_assert_true(model.request(), "dead model enters revive wait")
	_assert_true(not model.request(), "waiting model rejects duplicate request")
	_assert_true(model.complete(), "waiting model completes revive")
	_assert_true(model.is_alive(), "completed revive returns to alive")
	_assert_true(not model.complete(), "alive model rejects repeated completion")
