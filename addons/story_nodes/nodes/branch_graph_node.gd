@tool
class_name BranchGraphNode
extends StoryGraphNode

var branch_node: BranchNode:
	get:
		return story_node as BranchNode


func set_story_node(node: StoryNode) -> void:
	if not node is BranchNode:
		push_error('BranchGraphNode requires a BranchNode.')
		return

	super.set_story_node(node)
