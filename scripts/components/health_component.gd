extends Node
class_name HealthComponent

const HEALTH_MODEL_SCRIPT: Script = preload("res://scripts/combat/health_model.gd")

## 可复用血量组件
## 角色、敌人、人偶等一切有生命值的实体都可挂载本节点，通过信号驱动 UI 和逻辑

## 血量变化信号（current: 当前血量, max_value: 最大血量）
signal health_changed(current: float, max_value: float)
## 受到伤害信号（amount: 本次伤害量，用于触发受击反馈）
signal damaged(amount: float)
## 死亡信号（血量归零时触发一次）
signal died

@export var max_health: float = 100.0

var _model: HealthModel
var _damage_taken_multiplier: float = 1.0


func _ready() -> void:
	_model = HEALTH_MODEL_SCRIPT.new(max_health)


## 受到伤害；已死亡时忽略
func take_damage(amount: float) -> void:
	if _model == null:
		return
	amount = maxf(amount, 0.0) * _damage_taken_multiplier
	var previous_health: float = _model.get_health()
	var was_dead: bool = _model.is_dead()
	_model.take_damage(amount)
	var current_health: float = _model.get_health()
	var is_dead_now: bool = _model.is_dead()
	if current_health == previous_health and is_dead_now == was_dead:
		return
	if current_health != previous_health:
		damaged.emit(amount)
		health_changed.emit(current_health, _model.get_max_health())
	if not was_dead and is_dead_now:
		died.emit()


## 恢复血量
func heal(amount: float) -> void:
	if _model == null:
		return
	var previous_health: float = _model.get_health()
	_model.heal(amount)
	var current_health: float = _model.get_health()
	if current_health != previous_health:
		health_changed.emit(current_health, _model.get_max_health())


## 重置为满血（复活/刷新用）
func reset() -> void:
	if _model == null:
		return
	_model.reset()
	health_changed.emit(_model.get_health(), _model.get_max_health())


func is_dead() -> bool:
	return _model != null and _model.is_dead()


func get_health() -> float:
	return _model.get_health() if _model != null else 0.0


func set_damage_taken_multiplier(multiplier: float) -> bool:
	if not is_finite(multiplier) or multiplier < 0.0:
		return false
	_damage_taken_multiplier = multiplier
	return true


func apply_max_health_multiplier(multiplier: float) -> bool:
	if _model == null or not is_finite(multiplier) or multiplier <= 0.0:
		return false
	var snapshot: Dictionary = _model.create_snapshot()
	var old_max: float = float(snapshot.get("max_health", 0.0))
	var old_health: float = float(snapshot.get("current_health", 0.0))
	var new_max: float = old_max * multiplier
	if new_max <= 0.0:
		return false
	var was_dead: bool = bool(snapshot.get("is_dead", false))
	var new_health: float = 0.0 if was_dead else clampf(old_health * multiplier, 0.0, new_max)
	var replacement: HealthModel = HEALTH_MODEL_SCRIPT.new(new_max)
	if not replacement.restore_snapshot({
		"max_health": new_max,
		"current_health": new_health,
		"is_dead": was_dead,
	}):
		return false
	_model = replacement
	max_health = new_max
	health_changed.emit(_model.get_health(), _model.get_max_health())
	return true


func create_snapshot() -> Dictionary:
	return _model.create_snapshot() if _model != null else {}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if _model == null or not _model.restore_snapshot(snapshot):
		return false
	max_health = _model.get_max_health()
	health_changed.emit(_model.get_health(), _model.get_max_health())
	return true
