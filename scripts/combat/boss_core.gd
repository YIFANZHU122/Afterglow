extends CharacterBody2D
class_name BossCore

## Boss 场景适配器：只把攻击意图转发给 GameManager，不复制 Boss 规则。

var _syncing_health: bool = false


func _ready() -> void:
	var health: Node = get_node_or_null("HealthComponent")
	if health != null and health.has_signal("damaged"):
		health.damaged.connect(_on_health_damaged)


func apply_damage(amount: float) -> bool:
	if not GameManager.apply_boss_damage(amount):
		return false
	var health: Node = get_node_or_null("HealthComponent")
	if health != null:
		_syncing_health = true
		health.take_damage(amount)
		_syncing_health = false
	return true


func _on_health_damaged(amount: float) -> void:
	if _syncing_health:
		return
	GameManager.apply_boss_damage(amount)


func sync_health_from_game_manager() -> bool:
	var health: Node = get_node_or_null("HealthComponent")
	if health == null or not health.has_method("restore_snapshot"):
		return false
	var max_health: float = float(health.get("max_health"))
	var current_health: float = clampf(GameManager.get_boss_health(), 0.0, max_health)
	return bool(health.call("restore_snapshot", {
		"max_health": max_health,
		"current_health": current_health,
		"is_dead": is_zero_approx(current_health),
	}))
