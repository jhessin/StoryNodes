@tool
class_name StoryGraphNode
extends GraphNode

@export var story_node: StoryNode
@export var story_data: StoryData


func set_story_node(node: StoryNode) -> void:
	story_node = node

	if story_node == null:
		push_error('Story node should be set when using a StoryGraphNode')
		return

	name = String(story_node.instance_id)
	title = story_node.display_name
	position_offset = story_node.position


func set_story_data(data: StoryData) -> void:
	story_data = data


func get_story_data() -> StoryData:
	return story_data


func get_story_node() -> StoryNode:
	return story_node
