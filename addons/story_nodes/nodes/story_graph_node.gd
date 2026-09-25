@tool
class_name StoryGraphNode
extends GraphNode

signal ports_changed

var story_node: StoryNode
var story_data: StoryData


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	pass


func set_story_node(node: StoryNode) -> void:
	story_node = node

	if story_node == null:
		push_error('Story node should be set when using a StoryGraphNode')
		return

	if not story_node.instance_id.is_empty():
		name = String(story_node.instance_id)
	title = story_node.display_name + '(' + story_node.instance_id + ')'
	position_offset = story_node.position

	if story_node.size != Vector2.ZERO:
		size = story_node.size


func set_story_data(data: StoryData) -> void:
	story_data = data


func get_story_data() -> StoryData:
	return story_data


func get_story_node() -> StoryNode:
	return story_node
