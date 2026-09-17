@tool
class_name StoryNodeLibrary
extends Resource

var node_list: Array[StoryNodeDefinition]:
	get:
		return _nodes.values()

var node_ids: Array[StringName]:
	get:
		return _nodes.keys()

@export_storage
var _nodes: Dictionary[StringName, StoryNodeDefinition] = { }


func add_node(definition: StoryNodeDefinition) -> bool:
	if definition == null:
		return false

	if definition.id.is_empty():
		return false

	if _nodes.has(definition.id):
		return false

	_nodes[definition.id] = definition
	return true


func remove_node(id: StringName) -> bool:
	if not _nodes.has(id):
		return false

	_nodes.erase(id)
	return true


func has_node(id: StringName) -> bool:
	return _nodes.has(id)


func get_node(id: StringName) -> StoryNodeDefinition:
	return _nodes.get(id, null)


func clear() -> void:
	_nodes.clear()
