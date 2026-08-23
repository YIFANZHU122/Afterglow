extends Area2D
class_name ItemWorld

const INTERACTION_INPUT_ADAPTER_SCRIPT: Script = preload("res://scripts/presentation/interaction_input_adapter.gd")

## 世界中可拾取的物品
## 玩家进入触发区域后按 E 键拾取，加入 Inventory 后自身销毁

## 物品数据（在 .tscn 实例化时配置）
@export var item_data: ItemData

@onready var sprite: Sprite2D = $Sprite2D

var _player_nearby: bool = false
var _interaction_input_adapter: InteractionInputAdapter


func _ready() -> void:
	_interaction_input_adapter = INTERACTION_INPUT_ADAPTER_SCRIPT.new()
	# 用 item_data.icon 设置视觉
	if item_data != null and item_data.icon != null:
		sprite.texture = item_data.icon

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = false


func _process(_delta: float) -> void:
	if _player_nearby and _interaction_input_adapter.is_interact_pressed():
		_try_pickup()


func _try_pickup() -> void:
	if item_data == null:
		return
	if Inventory.add_item(item_data):
		queue_free()  # 拾取成功，移除世界物品
