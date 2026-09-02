extends RefCounted
class_name EnemyTierModel

## 敌人层级的统一威胁成本和奖励资格。

enum Tier {
	COMMON,
	SPECIAL,
	ELITE,
	TIER_TWO,
}

const THREAT_COST_BY_TIER: Dictionary = {
	Tier.COMMON: 1,
	Tier.SPECIAL: 2,
	Tier.ELITE: 3,
	Tier.TIER_TWO: 4,
}


static func get_threat_cost(tier: int) -> int:
	return int(THREAT_COST_BY_TIER.get(tier, 0))


static func can_drop_crystal(tier: int) -> bool:
	return tier == Tier.ELITE or tier == Tier.TIER_TWO


static func can_drop_food(tier: int) -> bool:
	return tier != Tier.SPECIAL


static func normalize(tier: int) -> Tier:
	return tier as Tier if tier >= Tier.COMMON and tier <= Tier.TIER_TWO else Tier.COMMON
