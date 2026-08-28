extends "res://scripts/presentation/actor_presenter.gd"

var movement_calls: Array[Vector2] = []
var attack_calls: Array[Vector2] = []
var hit_count: int = 0
var dead_values: Array[bool] = []


func set_movement(direction: Vector2) -> void:
	movement_calls.append(direction)


func play_attack(direction: Vector2) -> void:
	attack_calls.append(direction)


func play_hit() -> void:
	hit_count += 1


func set_dead(dead: bool) -> void:
	dead_values.append(dead)
