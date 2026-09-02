extends Resource
class_name ItemData

## 物品静态数据（通过右键 > New Resource 创建实例，作为 .tres 文件保存到 assets/items/）

enum ItemType {
	NONE,    ## 无类型（占位）
	SWORD,   ## 剑（近战武器）
	POTION,  ## 药水（未来扩展）
	MATERIAL, ## 材料
	FOOD,    ## 食物
	CONTAINER, ## 容器
	TOOL,    ## 工具
	AMMO,    ## 弹药
	EQUIPMENT, ## 装备
	FIREARM, ## 远程枪械
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.NONE

## 堆叠、重量和耐久属于静态定义；运行时数量由 ItemStackModel 保存。
@export_range(1, 999, 1) var max_stack: int = 1
@export_range(0.0, 999.0, 0.01) var unit_weight: float = 0.0
@export_range(0, 9999, 1) var max_durability: int = 0
@export var tags: PackedStringArray = PackedStringArray()

## 装备静态效果；运行时占用关系由 EquipmentModel 保存。
@export var equipment_definition: Resource

## 食物与容器的静态效果；运行时内容由对应领域模型保存。
@export_range(0.0, 100.0, 0.1) var food_restore: float = 0.0
@export_range(0.0, 100.0, 0.1) var water_restore: float = 0.0
@export_range(0, 5, 1) var container_capacity: int = 0
@export var is_raw_food: bool = false
@export_range(0.0, 1.0, 0.01) var disease_chance: float = 0.0

## 攻击力（仅剑类使用，未来可扩展为通用 stat 字典）
@export var attack_damage: float = 0.0

## 远程枪械配置；仅 item_type 为 FIREARM 时生效。
@export_range(0.0, 999.0, 0.1) var ranged_damage: float = 0.0
@export_range(0, 99, 1) var magazine_capacity: int = 0
@export_range(0.0, 30.0, 0.1) var reload_seconds: float = 2.0
@export_range(0.0, 10.0, 0.05) var fire_cooldown_seconds: float = 0.5
@export var ammo_item_id: StringName = &""
@export_range(0.0, 1.0, 0.05) var noise_strength: float = 1.0


func is_valid() -> bool:
	return not id.is_empty() \
		and not display_name.is_empty() \
		and max_stack >= 1 \
		and is_finite(unit_weight) \
		and unit_weight >= 0.0 \
		and max_durability >= 0 \
		and is_finite(food_restore) and food_restore >= 0.0 \
		and is_finite(water_restore) and water_restore >= 0.0 \
		and container_capacity >= 0 \
		and is_finite(disease_chance) and disease_chance >= 0.0 and disease_chance <= 1.0 \
		and is_finite(attack_damage) and attack_damage >= 0.0 \
		and is_finite(ranged_damage) and ranged_damage >= 0.0 \
		and magazine_capacity >= 0 \
		and is_finite(reload_seconds) and reload_seconds > 0.0 \
		and is_finite(fire_cooldown_seconds) and fire_cooldown_seconds >= 0.0 \
		and is_finite(noise_strength) and noise_strength >= 0.0 and noise_strength <= 1.0 \
		and (item_type != ItemType.EQUIPMENT or (equipment_definition != null and equipment_definition.is_valid())) \
		and (item_type != ItemType.FIREARM or (ranged_damage > 0.0 and magazine_capacity > 0 and not ammo_item_id.is_empty()))
