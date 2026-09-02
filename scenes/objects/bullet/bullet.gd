extends Area2D

## 子弹：朝目标方向直线移动，命中角色造成伤害后销毁

@export var speed: float = 350.0
@export var damage: float = 20.0
@export var target_group: StringName = &"player"

var _direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## 设置子弹飞行方向（由发射者调用）
func setup(direction: Vector2, damage_override: float = -1.0) -> void:
	_direction = direction.normalized()
	if damage_override >= 0.0:
		damage = damage_override


func _physics_process(delta: float) -> void:
	position += _direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(target_group):
		var health: HealthComponent = body.get_node_or_null("HealthComponent")
		if health != null:
			health.take_damage(damage)
	queue_free()
