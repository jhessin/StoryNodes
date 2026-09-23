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
	_refresh_variable_picker()


func set_story_data(data: StoryData) -> void:
	super.set_story_data(data)

	if story_data == null:
		return

	if story_data.variable_library == null:
		return

	story_data.variable_library.changed.connect(_refresh_variable_picker)
	_refresh_variable_picker()


func _on_variable_selected(index: int) -> void:
	pass


func _refresh_variable_picker() -> void:
	variable_picker.clear()

	if story_data == null:
		return

	if story_data.variable_library == null:
		return

	for variable: StoryVariable in story_data.variable_library.variable_list:
		var index: int = variable_picker.item_count
		variable_picker.add_item(String(variable.name))
		variable_picker.set_item_id(index, index)
