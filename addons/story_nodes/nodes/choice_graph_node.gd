@tool
class_name ChoiceGraphNode
extends StoryGraphNode

var choice_node: ChoiceNode:
	get:
		return story_node as ChoiceNode
