extends Resource
class_name EquipmentDefinition

## 装备静态效果。运行时装备关系由 EquipmentModel 保存。

enum Slot {
	HEAD,
	CHEST,
	LEGS,
	BACKPACK,
}

@export var id: StringName = &""
@export var slot: Slot = Slot.HEAD
@export_range(0, 99, 1) var inventory_slot_bonus: int = 0
@export_range(0.0, 999.0, 0.1) var carry_capacity_bonus: float = 0.0
@export_range(0.0, 3.0, 0.01) var move_speed_multiplier: float = 1.0
@export_range(0.0, 3.0, 0.01) var stamina_cost_multiplier: float = 1.0
@export_range(0.0, 3.0, 0.01) var melee_damage_multiplier: float = 1.0
@export_range(0.0, 0.75, 0.01) var damage_reduction: float = 0.0
@export_range(0.0, 999.0, 0.1) var max_health_bonus: float = 0.0
@export_range(0.0, 999.0, 0.1) var max_stamina_bonus: float = 0.0
@export_range(0, 10, 1) var vision_bonus_steps: int = 0
@export_range(0.0, 1.0, 0.01) var disease_resistance: float = 0.0


func is_valid() -> bool:
	return not id.is_empty() \
		and inventory_slot_bonus >= 0 \
		and is_finite(carry_capacity_bonus) and carry_capacity_bonus >= 0.0 \
		and is_finite(move_speed_multiplier) and move_speed_multiplier > 0.0 \
		and is_finite(stamina_cost_multiplier) and stamina_cost_multiplier > 0.0 \
		and is_finite(melee_damage_multiplier) and melee_damage_multiplier > 0.0 \
		and is_finite(damage_reduction) and damage_reduction >= 0.0 and damage_reduction <= 0.75 \
		and is_finite(max_health_bonus) and max_health_bonus >= 0.0 \
		and is_finite(max_stamina_bonus) and max_stamina_bonus >= 0.0 \
		and vision_bonus_steps >= 0 \
		and is_finite(disease_resistance) and disease_resistance >= 0.0 and disease_resistance <= 1.0
