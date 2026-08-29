extends Node2D
class_name ParasiticFlower

@export_enum("scarlet", "ashen", "violet") var variant: String = "scarlet"
@export var sway_speed: float = 1.4

var _base_rotation: float


func _ready() -> void:
	_base_rotation = rotation
	_apply_variant()


func _process(_delta: float) -> void:
	rotation = _base_rotation + sin(Time.get_ticks_msec() * 0.001 * sway_speed + position.x * 0.01) * 0.035


func _apply_variant() -> void:
	var flower: Sprite2D = get_node_or_null("FlowerSprite") as Sprite2D
	if flower == null:
		return
	if variant == "ashen":
		flower.modulate = Color(0.58, 0.62, 0.56, 0.88)
	elif variant == "violet":
		flower.modulate = Color(0.55, 0.34, 0.72, 0.9)
	else:
		flower.modulate = Color(1.0, 0.72, 0.75, 0.95)
