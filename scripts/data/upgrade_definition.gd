extends Resource
class_name UpgradeDefinition

## 一项局内强化的静态定义。

enum EffectType {
	DAMAGE_MULTIPLIER,
	MOVE_SPEED_MULTIPLIER,
	MAX_HEALTH_MULTIPLIER,
	DAMAGE_REDUCTION,
	MAX_STAMINA_MULTIPLIER,
	STAMINA_REGEN_MULTIPLIER,
	XP_MULTIPLIER,
	LUCK,
	SURVIVAL_CONSUMPTION_MULTIPLIER,
}

enum Quality { COMMON, RARE, EPIC, LEGENDARY }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var effect_type: EffectType = EffectType.DAMAGE_MULTIPLIER
@export var amount: float = 0.0
@export var quality: Quality = Quality.COMMON
@export var quality_multiplier: float = 1.0
@export var buff_id: StringName = &""


func is_valid() -> bool:
	if id.is_empty() or display_name.is_empty() or not is_finite(amount) or amount <= 0.0:
		return false
	return effect_type >= EffectType.DAMAGE_MULTIPLIER \
		and effect_type <= EffectType.SURVIVAL_CONSUMPTION_MULTIPLIER \
		and is_finite(quality_multiplier) \
		and quality_multiplier > 0.0
