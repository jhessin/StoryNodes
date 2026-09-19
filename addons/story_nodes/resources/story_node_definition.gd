@tool
class_name StoryNodeDefinition
extends Resource

@export var id: StringName = &''
@export var display_name: String = ''

@export var graph_scene: PackedScene

@export var category: String = ''

@export var instantiable: bool = true

@export var story_node_class: StringName = &''

@export_storage var script_path: String = ''

@export_multiline var description: String = ''


func create_node(instance_id: StringName) -> StoryNode:
	if instance_id.is_empty():
		push_error("StoryNodeDefinition: Cannot create node with an empty instance ID.")
		return null

	if story_node_class.is_empty():
		push_error("StoryNodeDefinition '%s': No StoryNode class has been assigned." % id)
		return null

	var node: StoryNode = StoryNodeRegistry.get_instance().create_node(story_node_class)

	if node == null:
		push_error(
			"StoryNodeDefinition '%s': Failed to create StoryNode of class '%s'."
			% [id, story_node_class]
		)
		return null

	node.instance_id = instance_id
	node.node_id = id

	return node


func is_valid() -> bool:
	if id.is_empty():
		push_error("StoryNodeDefinition: Definition has an empty ID.")
		return false

	if story_node_class.is_empty():
		push_error("StoryNodeDefinition '%s': No StoryNode class has been assigned." % id)
		return false

	if not StoryNodeRegistry.get_instance().has_class(story_node_class):
		push_error(
			"StoryNodeDefinition '%s': Unknown StoryNode class '%s'." % [id, story_node_class]
		)
		return false

	return true
