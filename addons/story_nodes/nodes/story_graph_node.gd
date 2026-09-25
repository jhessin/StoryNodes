@tool
class_name StoryGraphNode
extends GraphNode

signal ports_changed

var story_node: StoryNode
var story_data: StoryData

var _restoring_size: bool = false


func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED:
		return

	if _restoring_size:
		return

	if story_node == null:
		return

	if story_node.size == size:
		return

	story_node.size = size

	if story_data != null:
		story_data.mark_changed()


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


func set_story_data(data: StoryData) -> void:
	story_data = data


func get_story_data() -> StoryData:
	return story_data


func get_story_node() -> StoryNode:
	return story_node


func restore_saved_size() -> void:
	if story_node == null:
		return

	if story_node.size == Vector2.ZERO:
		return

	_restoring_size = true
	size = story_node.size
	_restoring_size = false
