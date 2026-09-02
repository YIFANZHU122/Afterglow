extends Resource
class_name RecipeDefinition

## 制作配方的静态内容契约。

enum StationType { HAND, CAMPFIRE, WORKBENCH }
const RECIPE_INGREDIENT_SCRIPT: Script = preload("res://scripts/data/recipe_ingredient.gd")

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var output_item: ItemData
@export_range(1, 999, 1) var output_quantity: int = 1
@export var ingredients: Array[Resource] = []
@export var station_type: StationType = StationType.HAND
@export_range(0.0, 3600.0, 0.1) var craft_time_seconds: float = 0.0
@export_range(0, 99, 1) var required_intelligence: int = 0


func is_valid() -> bool:
	if id.is_empty() or display_name.is_empty() or output_item == null or not output_item.is_valid() \
		or output_quantity < 1 or not is_finite(craft_time_seconds) or craft_time_seconds < 0.0 \
		or required_intelligence < 0 or station_type < StationType.HAND or station_type > StationType.WORKBENCH \
		or ingredients.is_empty():
		return false
	var seen: Dictionary = {}
	for raw: Resource in ingredients:
		if raw == null or raw.get_script() != RECIPE_INGREDIENT_SCRIPT:
			return false
		var ingredient: Resource = raw
		if ingredient == null or not ingredient.is_valid() or seen.has(ingredient.item.id):
			return false
		seen[ingredient.item.id] = true
	return true
