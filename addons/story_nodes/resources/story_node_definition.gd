@tool
class_name StoryNodeDefinition
extends Resource

@export var id: StringName = &''
@export var display_name: String = ''

@export var graph_scene: PackedScene

@export var category: String = ''

@export var instantiable: bool = true

var story_node_class: Variant

@export_multiline var description: String = ''


func create_node(instance_id: StringName) -> StoryNode:
	if instance_id.is_empty():
		return null

	if story_node_class == null:
		return null

	var node: Variant = story_node_class.new()

	if not node is StoryNode:
		return null

	node.instance_id = instance_id
	node.definition_id = id
	return node as StoryNode


func is_valid() -> bool:
	if id.is_empty():
		return false

	if story_node_class == null:
		return false

	if not story_node_class is GDScript:
		return false

	var node: Variant = story_node_class.new()

	return node is StoryNode
