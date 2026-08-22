extends Resource
class_name ItemData

## 物品静态数据（通过右键 > New Resource 创建实例，作为 .tres 文件保存到 assets/items/）

enum ItemType {
	NONE,    ## 无类型（占位）
	SWORD,   ## 剑（近战武器）
	POTION,  ## 药水（未来扩展）
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.NONE

## 攻击力（仅剑类使用，未来可扩展为通用 stat 字典）
@export var attack_damage: float = 0.0