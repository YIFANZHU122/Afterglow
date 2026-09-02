extends CharacterBody2D

## 最小追击型敌人：直线追踪玩家，接触时按冷却造成伤害。

const ENEMY_PERCEPTION_MODEL_SCRIPT: Script = preload("res://scripts/combat/enemy_perception_model.gd")
const ENEMY_ROLE_MODEL_SCRIPT: Script = preload("res://scripts/combat/enemy_role_model.gd")
const NOISE_EVENT_MODEL_SCRIPT: Script = preload("res://scripts/combat/noise_event_model.gd")
const PIXELS_PER_STEP: float = 40.0

@export var move_speed: float = 90.0
@export var contact_damage: float = 8.0
@export var attack_range: float = 72.0
@export var attack_cooldown: float = 1.0
@export var vision_range_steps: float = 8.0
@export_enum("hunter", "investigator", "siege") var enemy_role: int = 0

@onready var health: HealthComponent = $HealthComponent
@onready var health_bar: ProgressBar = $HealthBar
@onready var presenter: Variant = get_node_or_null("Presenter")

var _attack_cooldown_remaining: float = 0.0
var _defeated: bool = false
var _missing_presenter_warned: bool = false
var _perception: RefCounted
var _visual_contact_enabled: bool = true
var _visual_contact_override: bool = false
var _environment_speed_multiplier: float = 1.0
var _dynamic_special: bool = false
var _role_model: RefCounted
var _home_position: Vector2 = Vector2.ZERO
var _game_manager: Node
var _enemy_tier: int = 0


func _ready() -> void:
	_perception = ENEMY_PERCEPTION_MODEL_SCRIPT.new()
	_role_model = ENEMY_ROLE_MODEL_SCRIPT.new()
	_home_position = global_position
	_game_manager = get_node_or_null("/root/GameManager")
	if _game_manager != null and _game_manager.has_signal("noise_event_emitted"):
		_game_manager.connect("noise_event_emitted", _on_noise_event)
	health.health_changed.connect(_on_health_changed)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_on_health_changed(health.get_health(), health.max_health)


func _physics_process(delta: float) -> void:
	if _defeated:
		return
	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)
	var player: Node2D = _get_player()
	if player == null:
		velocity = Vector2.ZERO
		_present_movement(Vector2.ZERO)
		return
	var has_visual_contact: bool = _visual_contact_enabled if _visual_contact_override else \
		global_position.distance_to(player.global_position) / PIXELS_PER_STEP <= maxf(vision_range_steps, 0.0)
	if has_visual_contact:
		_perception.call("observe_visual", player.global_position, true, 1.0, 0.5)
	else:
		_perception.call("advance", delta)
	var perception_state: int = int(_perception.call("get_state"))
	if perception_state == ENEMY_PERCEPTION_MODEL_SCRIPT.State.SEARCHING:
		var health_ratio: float = health.get_health() / maxf(health.max_health, 1.0)
		var distance_from_home_steps: float = global_position.distance_to(_home_position) / PIXELS_PER_STEP
		if enemy_role != ENEMY_ROLE_MODEL_SCRIPT.Role.HUNTER and _role_model.should_disengage(enemy_role, distance_from_home_steps, health_ratio) and distance_from_home_steps > 1.0:
			var return_direction: Vector2 = (_home_position - global_position).normalized()
			velocity = return_direction * move_speed * _environment_speed_multiplier
			_present_movement(return_direction)
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			_present_movement(Vector2.ZERO)
		return
	var target_position: Vector2 = _perception.call("get_last_known_position")
	var offset: Vector2 = target_position - global_position
	if offset.length() > attack_range or perception_state != ENEMY_PERCEPTION_MODEL_SCRIPT.State.TRACKING:
		var movement_direction: Vector2 = offset.normalized()
		velocity = movement_direction * move_speed * _environment_speed_multiplier
		_present_movement(movement_direction)
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_present_movement(Vector2.ZERO)
		if perception_state == ENEMY_PERCEPTION_MODEL_SCRIPT.State.TRACKING:
			_try_attack(player)


func set_visual_contact(has_contact: bool, brightness: float = 1.0, has_line_of_sight: bool = true) -> void:
	_visual_contact_override = true
	_visual_contact_enabled = has_contact and has_line_of_sight and brightness >= 0.5
	if _visual_contact_enabled and _perception != null:
		var player: Node2D = _get_player()
		if player != null:
			_perception.call("observe_visual", player.global_position, has_line_of_sight, brightness, 0.5)


func clear_visual_contact_override() -> void:
	_visual_contact_override = false
	_visual_contact_enabled = true


func set_environment_speed_multiplier(multiplier: float) -> bool:
	if not is_finite(multiplier) or multiplier <= 0.0:
		return false
	_environment_speed_multiplier = multiplier
	return true


func set_dynamic_special(is_special: bool) -> bool:
	if _dynamic_special == is_special:
		return false
	_dynamic_special = is_special
	if is_special:
		_enemy_tier = 1
		move_speed *= 1.20
		contact_damage *= 1.35
		if health != null:
			health.apply_max_health_multiplier(1.25)
	return true


func set_enemy_role(role: int) -> bool:
	if role < ENEMY_ROLE_MODEL_SCRIPT.Role.HUNTER or role > ENEMY_ROLE_MODEL_SCRIPT.Role.SIEGE:
		return false
	enemy_role = role
	return true


func set_enemy_tier(tier: int) -> bool:
	if tier < 0 or tier > 3:
		return false
	_enemy_tier = tier
	return true


func get_enemy_tier() -> int:
	return _enemy_tier


func hear_sound(sound_position: Vector2, radius: float, sound_strength: float) -> bool:
	if _perception == null or radius <= 0.0:
		return false
	if global_position.distance_to(sound_position) / PIXELS_PER_STEP > radius:
		return false
	return bool(_perception.call("hear_sound", sound_position, radius, sound_strength))


func get_target_mode(has_visual_target: bool, has_sound_clue: bool, has_objective_target: bool = false) -> StringName:
	if _role_model == null:
		return &"none"
	return _role_model.choose_target(enemy_role, has_visual_target, has_sound_clue, has_objective_target)


func _on_noise_event(noise_event: RefCounted) -> void:
	if noise_event == null or noise_event.get_script() != NOISE_EVENT_MODEL_SCRIPT or _role_model == null:
		return
	var kind: int = int(noise_event.get_kind())
	if enemy_role == ENEMY_ROLE_MODEL_SCRIPT.Role.HUNTER and kind == NOISE_EVENT_MODEL_SCRIPT.Kind.SEARCH:
		return
	if enemy_role == ENEMY_ROLE_MODEL_SCRIPT.Role.SIEGE and kind < NOISE_EVENT_MODEL_SCRIPT.Kind.BUILD:
		return
	var radius_steps: float = _role_model.get_sound_radius_steps(enemy_role, noise_event.get_radius_steps())
	if global_position.distance_to(noise_event.get_origin()) > radius_steps * PIXELS_PER_STEP:
		return
	if _is_noise_blocked(noise_event.get_origin()):
		return
	hear_sound(noise_event.get_origin(), radius_steps, noise_event.get_strength())


func _is_noise_blocked(origin: Vector2) -> bool:
	if not is_inside_tree() or not origin.is_finite():
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, origin)
	query.collision_mask = 1
	query.exclude = [self]
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var collider: Node = hit.get("collider") as Node
	return collider != null and not collider.is_in_group("player")


func get_perception_state() -> int:
	return int(_perception.call("get_state")) if _perception != null else ENEMY_PERCEPTION_MODEL_SCRIPT.State.SEARCHING


func _try_attack(player: Node2D) -> void:
	if _attack_cooldown_remaining > 0.0:
		return
	var player_health: Node = player.get_node_or_null("HealthComponent")
	if player_health == null:
		return
	if bool(player_health.call("is_dead")):
		return
	var health_before_attack: float = float(player_health.call("get_health"))
	player_health.call("take_damage", contact_damage)
	_attack_cooldown_remaining = attack_cooldown
	if float(player_health.call("get_health")) < health_before_attack:
		_present_attack((player.global_position - global_position).normalized())


func _get_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	return players[0] as Node2D if players.size() > 0 else null


func _on_health_changed(current: float, max_value: float) -> void:
	health_bar.value = current
	health_bar.max_value = max_value


func _on_damaged(_amount: float) -> void:
	if presenter != null:
		presenter.play_hit()
	else:
		_warn_missing_presenter()


func _on_died() -> void:
	if _defeated:
		return
	_defeated = true
	velocity = Vector2.ZERO
	health_bar.visible = false
	collision_layer = 0
	collision_mask = 0
	if presenter != null:
		presenter.set_dead(true)
	else:
		_warn_missing_presenter()


func _present_movement(direction: Vector2) -> void:
	if presenter == null:
		_warn_missing_presenter()
		return
	presenter.set_movement(direction)


func _present_attack(direction: Vector2) -> void:
	if presenter == null:
		_warn_missing_presenter()
		return
	presenter.play_attack(direction)


func _warn_missing_presenter() -> void:
	if _missing_presenter_warned:
		return
	_missing_presenter_warned = true
	push_warning("[ChaserEnemy] Presenter is missing; gameplay continues without presentation feedback")


func create_snapshot() -> Dictionary:
	return {
		"entity_id": name,
		"position": [global_position.x, global_position.y],
		"velocity": [velocity.x, velocity.y],
		"health": health.create_snapshot() if health != null else {},
		"attack_cooldown_remaining": _attack_cooldown_remaining,
		"defeated": _defeated,
		"visual_contact_enabled": _visual_contact_enabled,
		"visual_contact_override": _visual_contact_override,
		"environment_speed_multiplier": _environment_speed_multiplier,
		"dynamic_special": _dynamic_special,
		"enemy_role": enemy_role,
		"enemy_tier": _enemy_tier,
		"perception": _perception.create_snapshot() if _perception != null else {},
		"collision_layer": collision_layer,
		"collision_mask": collision_mask,
	}


func restore_snapshot(snapshot: Dictionary) -> bool:
	for key: String in ["entity_id", "position", "velocity", "health", "attack_cooldown_remaining", "defeated", "visual_contact_enabled", "visual_contact_override", "perception", "collision_layer", "collision_mask"]:
		if not snapshot.has(key):
			return false
	var position: Vector2 = _decode_vector(snapshot["position"])
	var restored_velocity: Vector2 = _decode_vector(snapshot["velocity"])
	if not position.is_finite() or not restored_velocity.is_finite() or float(snapshot["attack_cooldown_remaining"]) < 0.0:
		return false
	if health == null or not health.restore_snapshot(snapshot["health"]):
		return false
	if _perception == null:
		_perception = ENEMY_PERCEPTION_MODEL_SCRIPT.new()
	if not _perception.restore_snapshot(snapshot["perception"]):
		return false
	global_position = position
	velocity = restored_velocity
	_attack_cooldown_remaining = float(snapshot["attack_cooldown_remaining"])
	_defeated = bool(snapshot["defeated"])
	_visual_contact_enabled = bool(snapshot["visual_contact_enabled"])
	_visual_contact_override = bool(snapshot["visual_contact_override"])
	if snapshot.has("environment_speed_multiplier"):
		if not is_finite(float(snapshot["environment_speed_multiplier"])) or float(snapshot["environment_speed_multiplier"]) <= 0.0:
			return false
		_environment_speed_multiplier = float(snapshot["environment_speed_multiplier"])
	if snapshot.has("dynamic_special") and bool(snapshot["dynamic_special"]):
		set_dynamic_special(true)
	if snapshot.has("enemy_role"):
		var restored_role: int = int(snapshot["enemy_role"])
		if restored_role < ENEMY_ROLE_MODEL_SCRIPT.Role.HUNTER or restored_role > ENEMY_ROLE_MODEL_SCRIPT.Role.SIEGE:
			return false
		enemy_role = restored_role
	if snapshot.has("enemy_tier"):
		if int(snapshot["enemy_tier"]) < 0 or int(snapshot["enemy_tier"]) > 3:
			return false
		_enemy_tier = int(snapshot["enemy_tier"])
	collision_layer = int(snapshot["collision_layer"])
	collision_mask = int(snapshot["collision_mask"])
	if health.is_dead() != _defeated:
		return false
	return true


func _decode_vector(value: Variant) -> Vector2:
	if value is Array and (value as Array).size() == 2:
		return Vector2(float((value as Array)[0]), float((value as Array)[1]))
	return Vector2(INF, INF)
