extends Node
class_name EncounterMember

signal defeated(reward_xp: int)

@export var reward_xp: int = 0

var _reported: bool = false
var _health: Node


func _ready() -> void:
	var parent_entity: Node = get_parent()
	if parent_entity == null:
		push_warning("[EncounterMember] parent entity is missing")
		return
	_health = parent_entity.get_node_or_null("HealthComponent")
	if _health == null or not _health.has_signal("died"):
		push_warning("[EncounterMember] HealthComponent with died signal is missing on %s" % parent_entity.name)
		return
	_health.died.connect(_on_health_died)


func _on_health_died() -> void:
	if _reported:
		return
	_reported = true
	defeated.emit(maxi(reward_xp, 0))
