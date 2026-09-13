@tool
class_name StoryGraphNode
extends GraphNode

var story_node: StoryNode


func set_story_node(node: StoryNode) -> void:
	story_node = node

	name = String(node.id)
	title = node.display_name
	position_offset = node.position

	clear_all_slots()

	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
