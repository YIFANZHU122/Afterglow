extends RefCounted
class_name RouteValidationModel

## 小型路线图验证器，拒绝唯一工具路线和无法抵达出口的布局。

class RouteEdge:
	var from_id: StringName
	var to_id: StringName
	var required_steps: int

	func _init(from_value: StringName, to_value: StringName, required_value: int) -> void:
		from_id = from_value
		to_id = to_value
		required_steps = required_value


func edge(from_id: StringName, to_id: StringName, required_steps: int) -> RouteEdge:
	return RouteEdge.new(from_id, to_id, required_steps)


func validate(start_id: StringName, exit_id: StringName, edges: Array) -> PackedStringArray:
	var errors := PackedStringArray()
	if start_id.is_empty() or exit_id.is_empty() or start_id == exit_id:
		errors.append("start and exit must be distinct non-empty ids")
		return errors
	var graph: Dictionary = {}
	var base_edges: int = 0
	for raw_edge: Variant in edges:
		if not raw_edge is RouteEdge:
			errors.append("route contains an invalid edge")
			continue
		var route_edge: RouteEdge = raw_edge as RouteEdge
		if route_edge.from_id.is_empty() or route_edge.to_id.is_empty() or route_edge.required_steps < 0 or route_edge.required_steps > 3:
			errors.append("route edge has invalid ids or step requirement")
			continue
		if not graph.has(route_edge.from_id):
			graph[route_edge.from_id] = []
		(graph[route_edge.from_id] as Array).append(route_edge)
		if route_edge.required_steps == 0:
			base_edges += 1
	if base_edges == 0:
		errors.append("route has no base-access edge")
	var reachable: Dictionary = {start_id: true}
	var frontier: Array[StringName] = [start_id]
	while not frontier.is_empty():
		var current: StringName = frontier.pop_front()
		for route_edge: RouteEdge in graph.get(current, []):
			if not reachable.has(route_edge.to_id):
				reachable[route_edge.to_id] = true
				frontier.append(route_edge.to_id)
	if not reachable.has(exit_id):
		errors.append("exit is not reachable")
	var base_reachable: Dictionary = {start_id: true}
	var base_frontier: Array[StringName] = [start_id]
	while not base_frontier.is_empty():
		var base_current: StringName = base_frontier.pop_front()
		for route_edge: RouteEdge in graph.get(base_current, []):
			if route_edge.required_steps == 0 and not base_reachable.has(route_edge.to_id):
				base_reachable[route_edge.to_id] = true
				base_frontier.append(route_edge.to_id)
	if not base_reachable.has(exit_id):
		errors.append("exit has no base route")
	return errors
