extends RefCounted
class_name EnemyDropService

## 敌人死亡奖励：只消费当前地图预算，不修改遭遇目标或动态威胁预算。

const ITEM_CATALOG_SCRIPT: Script = preload("res://scripts/items/item_catalog.gd")
const ITEM_DROP_SERVICE_SCRIPT: Script = preload("res://scripts/items/item_drop_service.gd")
const ENEMY_TIER_MODEL_SCRIPT: Script = preload("res://scripts/combat/enemy_tier_model.gd")

const FOOD_DROP_CHANCE: float = 0.35
const MATERIAL_DROP_CHANCE: float = 0.50
const CRYSTAL_DROP_CHANCE: float = 0.25

var _catalog: RefCounted = ITEM_CATALOG_SCRIPT.new()
var _world_drop_service: RefCounted = ITEM_DROP_SERVICE_SCRIPT.new()


func spawn_for_enemy(parent: Node, position: Vector2, tier: int, budget: RefCounted, food_roll: float, material_roll: float, crystal_roll: float) -> Array[StringName]:
	var dropped: Array[StringName] = []
	if parent == null or budget == null or not position.is_finite():
		return dropped
	var normalized_tier: int = ENEMY_TIER_MODEL_SCRIPT.normalize(tier)
	var food_eligible: bool = ENEMY_TIER_MODEL_SCRIPT.can_drop_food(normalized_tier)
	var forced_food: bool = food_eligible and budget.should_force_food()
	var dropped_food: bool = food_eligible and budget.get_food_budget() > 0 and (forced_food or _is_roll_success(food_roll, FOOD_DROP_CHANCE))
	budget.register_kill(dropped_food, food_eligible)
	if dropped_food and _spawn_item(parent, &"wild_food", position):
		dropped.append(&"wild_food")
	if budget.get_material_remaining() > 0 and _is_roll_success(material_roll, MATERIAL_DROP_CHANCE) and budget.try_spend_material_budget(1):
		if _spawn_item(parent, &"scrap_parts", position + Vector2(24.0, 0.0)):
			dropped.append(&"scrap_parts")
	if ENEMY_TIER_MODEL_SCRIPT.can_drop_crystal(normalized_tier) and budget.get_crystal_remaining() > 0 \
		and _is_roll_success(crystal_roll, CRYSTAL_DROP_CHANCE) and budget.try_spend_crystal_budget(1):
		if _spawn_item(parent, &"crystal", position + Vector2(-24.0, 0.0)):
			dropped.append(&"crystal")
	return dropped


func _spawn_item(parent: Node, item_id: StringName, position: Vector2) -> bool:
	var item: ItemData = _catalog.get_item(item_id) if _catalog != null else null
	return _world_drop_service.spawn_item(parent, item, position) != null if item != null else false


func _is_roll_success(value: float, chance: float) -> bool:
	return is_finite(value) and value >= 0.0 and value < chance
