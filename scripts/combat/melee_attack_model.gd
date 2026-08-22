extends RefCounted
class_name MeleeAttackModel

## 近战攻击资格规则，不执行碰撞扫描或表现反馈。


func can_attack(item: ItemData) -> bool:
	return item != null \
		and item.item_type == ItemData.ItemType.SWORD \
		and item.attack_damage > 0.0


func get_damage(item: ItemData) -> float:
	return item.attack_damage if can_attack(item) else 0.0
