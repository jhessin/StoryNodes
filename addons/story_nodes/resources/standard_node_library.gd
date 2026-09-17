@tool
class_name StandardNodeLibrary
extends StoryNodeLibrary


func _init() -> void:
	_register_standard_nodes()


func _register_standard_nodes() -> void:
	add_node(
		_create_definition(
			&'dialogue',
			'Dialogue',
			'Displays dialogue from a character.',
			'Conversation',
			preload('res://addons/story_nodes/nodes/dialogue_graph_node.tscn'),
			preload('res://addons/story_nodes/resources/nodes/dialogue_node.gd'),
		)
	)


func _create_definition(
	id: StringName,
	display_name: String,
	description: String,
	category: String,
	graph_scene: PackedScene,
	story_node_script: Script,
) -> StoryNodeDefinition:
	var definition := StoryNodeDefinition.new()

	definition.id = id
	definition.display_name = display_name
	definition.description = description
	definition.category = category
	definition.graph_scene = graph_scene
	definition.story_node_script = story_node_script

	return definition
