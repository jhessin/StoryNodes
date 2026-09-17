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


func _create_definition(
	id: StringName,
	display_name: String,
	description: String,
	category: String,
	graph_scene: PackedScene,
	story_node_class: Variant,
	instantiable: bool = true,
) -> StoryNodeDefinition:
	var definition := StoryNodeDefinition.new()

	if id.is_empty():
		push_error('Definition requires a an ID')
		return null

	if node_ids.has(id):
		push_error('Definition ID "%s" is already defined' % id)
		return null

	definition.id = id
	definition.display_name = display_name
	definition.description = description
	definition.category = category
	definition.graph_scene = graph_scene
	definition.story_node_class = story_node_class
	definition.instantiable = instantiable

	return definition
