extends Area2D
class_name AttackArea

## 近战攻击判定区域
## 攻击时短暂启用，扫描范围内可攻击对象（带 HealthComponent 的）并造成伤害

var _active: bool = false
var _hit_targets: Array = []
var _damage: float = 0.0


func _ready() -> void:
	monitoring = false
	body_entered.connect(_on_body_entered)


## 执行一次攻击（damage_value 为本次攻击伤害）
func start_attack(damage_value: float) -> void:
	_active = true
	_damage = damage_value
	_hit_targets.clear()
	monitoring = true
	# 等两帧让物理引擎刷新重叠检测（确保能扫到贴着的目标）
	await get_tree().physics_frame
	await get_tree().physics_frame
	for body in get_overlapping_bodies():
		_try_hit(body)
	# 攻击窗口持续 0.1 秒
	await get_tree().create_timer(0.1).timeout
	_active = false
	monitoring = false


func _on_body_entered(body: Node) -> void:
	if _active:
		_try_hit(body)


func _try_hit(node: Node) -> void:
	if node in _hit_targets:
		return
	var health: HealthComponent = node.get_node_or_null("HealthComponent")
	if health == null:
		return
	_hit_targets.append(node)
	health.take_damage(_damage)