extends Resource
class_name RecipeIngredient

## 配方的一项材料需求；只描述静态定义，不保存运行时预留数量。

@export var item: ItemData
@export_range(1, 999, 1) var quantity: int = 1


func is_valid() -> bool:
	return item != null and item.is_valid() and quantity >= 1
