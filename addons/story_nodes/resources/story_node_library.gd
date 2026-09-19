@tool
class_name StoryNodeLibrary
extends Resource

@export var _nodes: Dictionary[StringName, StoryNode] = { }

var node_list: Array[StoryNode]:
	get:
		return _nodes.values()

var node_ids: Array[StringName]:
	get:
		return _nodes.keys()


func add_node(node: StoryNode) -> bool:
	if node == null:
		push_error('Cannot add a null node.')
		return false

	if node.node_id.is_empty():
		push_error('Cannot add a node with an empty Node ID.')
		return false

	if _nodes.has(node.node_id):
		push_error('Node with node id: "%s" already exists.' % node.node_id)
		return false

	_nodes[node.node_id] = node
	emit_changed()

	return true


func remove_node(id: StringName) -> bool:
	if not _nodes.has(id):
		push_error('Cannot remove node "%s": it does not exist.' % id)
		return false

	_nodes.erase(id)
	emit_changed()

	return true


func has_node(id: StringName) -> bool:
	return _nodes.has(id)


func get_node(id: StringName) -> StoryNode:
	return _nodes.get(id, null)


func clear() -> void:
	_nodes.clear()
	emit_changed()
