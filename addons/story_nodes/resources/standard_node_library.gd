@tool
class_name StandardNodeLibrary
extends StoryNodeLibrary


func _init() -> void:
	_register_standard_nodes()


func get_start_node() -> StoryNodeDefinition:
	return get_node(&'start')


func _register_standard_nodes() -> void:
	add_node(
		_create_definition(
			&'start',
			'Start',
			'The starting point of every story.',
			'Flow',
			preload('res://addons/story_nodes/nodes/start_graph_node.tscn'),
			StoryNode,
			false,
		)
	)
	add_node(
		_create_definition(
			&'dialogue',
			'Dialogue',
			'Displays dialogue from a character.',
			'Conversation',
			preload('res://addons/story_nodes/nodes/dialogue_graph_node.tscn'),
			DialogueNode,
		)
	)
