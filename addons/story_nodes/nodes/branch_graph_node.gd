@tool
class_name BranchGraphNode
extends StoryGraphNode

const CONDITION_ROW_SCENE: PackedScene = preload(
	'res://addons/story_nodes/nodes/condition_row.tscn'
)

var branch_node: BranchNode:
	get:
		return story_node as BranchNode

@onready var variable_picker: OptionButton = %VariablePicker
@onready var new_condition_button: Button = %NewConditionButton


func _ready() -> void:
	new_condition_button.pressed.connect(_on_new_condition_pressed)
	variable_picker.item_selected.connect(_on_variable_selected)


func set_story_node(node: StoryNode) -> void:
	if not node is BranchNode:
		push_error('BranchGraphNode requires a BranchNode.')
		return

	super.set_story_node(node)
	_refresh_variable_picker()
	_refresh_condition_rows()


func set_story_data(data: StoryData) -> void:
	super.set_story_data(data)

	if story_data == null:
		return

	if story_data.variable_library == null:
		return

	story_data.variable_library.changed.connect(_refresh_variable_picker)
	_refresh_variable_picker()


func _on_new_condition_pressed() -> void:
	if branch_node == null:
		return

	var condition: BranchCondition = BranchCondition.new()
	branch_node.conditions.append(condition)
	branch_node.emit_changed()
	story_data.mark_changed()
	_refresh_condition_rows()


func _on_variable_selected(index: int) -> void:
	if branch_node == null:
		return

	if story_data == null or story_data.variable_library == null:
		return

	var variables: Array[StoryVariable] = story_data.variable_library.variable_list

	if index < 0 or index >= variables.size():
		return

	var variable: StoryVariable = variables[index]

	branch_node.variable = variable
	branch_node.emit_changed()
	if story_data != null:
		story_data.mark_changed()


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

		if branch_node != null and branch_node.variable != null:
			if branch_node.variable.name == variable.name:
				variable_picker.select(index)


func _refresh_condition_rows() -> void:
	for condition: BranchCondition in branch_node.conditions:
		var condition_row: ConditionRow = CONDITION_ROW_SCENE.instantiate() as ConditionRow

		if condition_row == null:
			push_error('Failed to instantiate ConditionRow')
			continue

		var new_condition_index: int = get_children().find(new_condition_button)
		add_child(condition_row)
		move_child(condition_row, new_condition_index)
		condition_row.set_variable(branch_node.variable)
		condition_row.set_condition(condition)

		var slot_index: int = get_children().find(condition_row)
		set_slot_enabled_right(slot_index, true)
		set_slot_type_right(slot_index, 0)
