extends Resource
class_name UpgradeDefinition

## 一项局内强化的静态定义。

enum EffectType {
	DAMAGE_MULTIPLIER,
	MOVE_SPEED_MULTIPLIER,
}

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var effect_type: EffectType = EffectType.DAMAGE_MULTIPLIER
@export var amount: float = 0.0


func is_valid() -> bool:
	if id.is_empty() or display_name.is_empty() or amount <= 0.0:
		return false
	return effect_type == EffectType.DAMAGE_MULTIPLIER \
		or effect_type == EffectType.MOVE_SPEED_MULTIPLIER
