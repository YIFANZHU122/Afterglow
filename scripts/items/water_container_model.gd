extends RefCounted
class_name WaterContainerModel

## 容器内容模型；生水和净水不能混装。

enum Source { EMPTY, RAIN, FLOWING, PUDDLE }

var _capacity: int
var _amount: int = 0
var _source: Source = Source.EMPTY
var _purified: bool = false


func _init(capacity: int = 1) -> void:
	_capacity = capacity if capacity in [1, 3, 5] else 1


func get_capacity() -> int:
	return _capacity


func get_amount() -> int:
	return _amount


func is_purified() -> bool:
	return _purified


func get_source() -> Source:
	return _source


func fill(source: Source, amount: int, purified: bool) -> bool:
	if source == Source.EMPTY or amount <= 0 or _amount + amount > _capacity:
		return false
	if _amount > 0 and (_source != source or _purified != purified):
		return false
	_amount += amount
	_source = source
	_purified = purified
	return true


func consume(amount: int = 1) -> bool:
	if amount <= 0 or amount > _amount:
		return false
	_amount -= amount
	if _amount == 0:
		_source = Source.EMPTY
		_purified = false
	return true


func purify() -> bool:
	if _amount <= 0 or _purified:
		return false
	_purified = true
	return true


func create_snapshot() -> Dictionary:
	return {"capacity": _capacity, "amount": _amount, "source": int(_source), "purified": _purified}


func restore_snapshot(snapshot: Dictionary) -> bool:
	if snapshot.size() != 4 or not snapshot.has("capacity") or not snapshot.has("amount") \
		or not snapshot.has("source") or not snapshot.has("purified"):
		return false
	var capacity: int = _to_integral(snapshot["capacity"])
	var amount: int = _to_integral(snapshot["amount"])
	var source: int = _to_integral(snapshot["source"])
	if capacity not in [1, 3, 5] or amount < 0 or amount > capacity or source < Source.EMPTY or source > Source.PUDDLE \
		or snapshot["purified"] is not bool:
		return false
	if amount == 0 and source != Source.EMPTY:
		return false
	_capacity = capacity
	_amount = amount
	_source = source as Source
	_purified = snapshot["purified"]
	return true


func _to_integral(value: Variant) -> int:
	if value is int:
		return value
	if value is float and is_finite(value) and is_equal_approx(value, floor(value)):
		return int(value)
	return -1
