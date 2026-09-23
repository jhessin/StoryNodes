@tool
class_name BranchGraphNode
extends StoryGraphNode

var branch_node: BranchNode:
	get:
		return story_node as BranchNode

@onready var variable_picker: OptionButton = %VariablePicker


func _ready() -> void:
	variable_picker.item_selected.connect(_on_variable_selected)


func set_story_node(node: StoryNode) -> void:
	if not node is BranchNode:
		push_error('BranchGraphNode requires a BranchNode.')
		return

	super.set_story_node(node)


func _on_variable_selected(index: int) -> void:
	pass
