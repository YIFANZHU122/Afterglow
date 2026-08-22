extends Node
class_name HealthComponent

## 可复用血量组件
## 角色、敌人、人偶等一切有生命值的实体都可挂载本节点，通过信号驱动 UI 和逻辑

## 血量变化信号（current: 当前血量, max_value: 最大血量）
signal health_changed(current: float, max_value: float)
## 受到伤害信号（amount: 本次伤害量，用于触发受击反馈）
signal damaged(amount: float)
## 死亡信号（血量归零时触发一次）
signal died

@export var max_health: float = 100.0

var _current_health: float = 0.0
var _is_dead: bool = false


func _ready() -> void:
	_current_health = max_health


## 受到伤害；已死亡时忽略
func take_damage(amount: float) -> void:
	if _is_dead:
		return
	_current_health = maxf(_current_health - amount, 0.0)
	damaged.emit(amount)
	health_changed.emit(_current_health, max_health)
	if _current_health <= 0.0:
		_is_dead = true
		died.emit()


## 恢复血量
func heal(amount: float) -> void:
	_current_health = minf(_current_health + amount, max_health)
	health_changed.emit(_current_health, max_health)


## 重置为满血（复活/刷新用）
func reset() -> void:
	_is_dead = false
	_current_health = max_health
	health_changed.emit(_current_health, max_health)


func is_dead() -> bool:
	return _is_dead


func get_health() -> float:
	return _current_health