@tool
class_name SetVariableGraphNode
extends StoryGraphNode

var set_variable_node: SetVariableNode:
	get:
		return story_node as SetVariableNode

var variable_field: Control

@onready var variable_picker: OptionButton = %VariablePicker


func _ready() -> void:
	variable_picker.item_selected.connect(_on_variable_selected)

	super._ready()


func _process(_delta: float) -> void:
	if not is_instance_valid(variable_field):
		return

	if variable_field.get_parent() != self:
		return

	if variable_field.size.y <= 0.0:
		print(
			"Variable field has zero height. ",
			"Field size: ",
			variable_field.size,
			" | Node size: ",
			size,
			" | Minimum size: ",
			get_combined_minimum_size(),
		)


func set_story_node(node: StoryNode) -> void:
	if not node is SetVariableNode:
		push_error('SetVariableGraphNode requires a SetVariableNode.')
		return

	super.set_story_node(node)
	_refresh_variable_picker()

	if is_visible_in_tree():
		var index := _find_index_for_variable(story_node.variable)
		variable_picker.select(index)
		_update_variable_field()
	else:
		if not visibility_changed.is_connected(_on_visibility_changed):
			visibility_changed.connect(_on_visibility_changed)


func set_story_data(data: StoryData) -> void:
	super.set_story_data(data)

	if story_data == null:
		return

	if story_data.variable_library == null:
		return

	story_data.variable_library.changed.connect(_refresh_variable_picker)
	_refresh_variable_picker()


func _on_visibility_changed():
	if is_visible_in_tree():
		_select_variable(story_node.variable)
		if visibility_changed.is_connected(_on_visibility_changed):
			visibility_changed.disconnect(_on_visibility_changed)


func _on_variable_selected(index: int) -> void:
	if set_variable_node == null or story_data == null:
		return

	var previous_variable := set_variable_node.variable

	if index == 0:
		undo_redo.create_action('Select Variable')

		undo_redo.add_do_method(_select_variable.bind(null))

		undo_redo.add_undo_method(_select_variable.bind(previous_variable))

		undo_redo.commit_action()
		return

	var variable_index: int = index - 1
	var variables: Array[StoryVariable] = story_data.variable_library.variable_list

	if variable_index < 0 or variable_index >= variables.size():
		return

	var variable: StoryVariable = variables[variable_index]

	if variable == previous_variable:
		return

	if story_data == null or story_data.variable_library == null:
		return

	undo_redo.create_action('Select Variable')

	undo_redo.add_do_method(_select_variable.bind(variable))

	undo_redo.add_undo_method(_select_variable.bind(previous_variable))

	undo_redo.commit_action()


func _select_variable(variable: StoryVariable) -> void:
	set_variable_node.variable = variable
	_refresh_variable_picker()
	_update_variable_field()
	set_variable_node.emit_changed()
	story_data.emit_changed()

	var index := _find_index_for_variable(variable)
	variable_picker.select(index)


func _clear_variable_field() -> void:
	if is_instance_valid(variable_field):
		variable_field.free()
	variable_field = null


func _update_variable_field() -> void:
	_clear_variable_field()

	if set_variable_node == null or set_variable_node.variable == null:
		return

	var value: Variant = set_variable_node.variable.value

	match set_variable_node.variable.type:
		StoryVariable.Type.STRING:
			variable_field = LineEdit.new()
			variable_field.text = str(value)
			variable_field.text_changed.connect(_on_update_variable)
		StoryVariable.Type.BOOL:
			variable_field = CheckBox.new()
			if value is bool:
				variable_field.set_pressed(value)
			else:
				variable_field.set_pressed(value == 'true')
			variable_field.toggled.connect(_on_update_variable)
		StoryVariable.Type.INT:
			variable_field = SpinBox.new()
			variable_field.value = int(value)
			variable_field.value_changed.connect(_on_update_variable)
		StoryVariable.Type.FLOAT:
			variable_field = SpinBox.new()
			variable_field.value = float(value)
			variable_field.value_changed.connect(_on_update_variable)
		_:
			push_error('Invalid type for variable ', set_variable_node.variable.name)
			return

	add_child(variable_field)


func _on_update_variable(value: Variant) -> void:
	if undo_redo == null:
		push_error('SetVariableGraphNode needs a reference to the StoryData')
		return

	undo_redo.create_action('Update Variable')
	var old_value: Variant = set_variable_node.variable.value

	undo_redo.add_do_method(_update_variable.bind(value))

	undo_redo.add_undo_method(_update_variable.bind(old_value))

	undo_redo.commit_action()


func _update_variable(value: Variant) -> void:
	if variable_field == null:
		return

	set_variable_node.variable.value = value

	match set_variable_node.variable.type:
		StoryVariable.Type.STRING:
			# variable_field is LineEdit
			var focused: bool = variable_field.has_focus()
			var col: int

			if focused:
				col = variable_field.get_caret_column()

			variable_field.text = str(value)

			if focused:
				variable_field.set_caret_column(col)
		StoryVariable.Type.BOOL:
			# variable_field is CheckBox
			if value is bool:
				variable_field.set_pressed(value)
			else:
				variable_field.set_pressed(value == 'true')
		StoryVariable.Type.INT:
			# variable_field is SpinBox
			variable_field.value = int(value)
		StoryVariable.Type.FLOAT:
			# variable_field is SpinBox
			variable_field.value = float(value)
		_:
			push_error('Invalid type for variable ', set_variable_node.variable.name)
			return


func _find_index_for_variable(variable: StoryVariable) -> int:
	if variable == null:
		return 0

	if story_data == null or story_data.variable_library == null:
		return -1

	if variable == null:
		return -1

	for i: int in range(story_data.variable_library.variable_list.size()):
		var v: StoryVariable = story_data.variable_library.variable_list[i]
		if v == null:
			continue

		if v.name == variable.name:
			return i + 1

	return -1


func _refresh_variable_picker() -> void:
	variable_picker.clear()

	if story_data == null:
		return

	variable_picker.add_item('None')
	variable_picker.set_item_id(0, -1)
	variable_picker.select(0)

	if story_data.variable_library == null:
		return

	for variable: StoryVariable in story_data.variable_library.variable_list:
		var index: int = variable_picker.item_count
		variable_picker.add_item(String(variable.name))
		variable_picker.set_item_id(index, index - 1)

		if set_variable_node != null and set_variable_node.variable == variable:
			variable_picker.select(index)
