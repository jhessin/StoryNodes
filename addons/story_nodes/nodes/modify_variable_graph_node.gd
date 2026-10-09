@tool
class_name ModifyVariableGraphNode
extends StoryGraphNode

var modify_variable_node: ModifyVariableNode:
	get:
		return story_node as ModifyVariableNode

var variable_field: Control

var value_editor: Control = null

@onready var variable_picker: OptionButton = %VariablePicker
@onready var modification_box: BoxContainer = %ModificationBox
@onready var operator_picker: OptionButton = %OperatorPicker


func _ready() -> void:
	variable_picker.item_selected.connect(_on_variable_selected)
	operator_picker.item_selected.connect(_on_operator_changed)

	super._ready()


func set_story_node(node: StoryNode) -> void:
	if not node is ModifyVariableNode:
		push_error('ModifyVariableGraphNode requires a ModifyVariableNode.')
		return

	super.set_story_node(node)
	_refresh_variable_picker()

	if is_visible_in_tree():
		var index := _find_index_for_variable(story_node.variable)
		variable_picker.select(index)
		_update_operator_picker()
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


func _clear_value_editor() -> void:
	if is_instance_valid(value_editor):
		value_editor.free()
	value_editor = null


func _on_value_updated(value: Variant) -> void:
	var old_value: Variant = modify_variable_node.value
	var new_value: Variant = value

	undo_redo.create_action('ModifyVariableNode update value')

	undo_redo.add_do_method(_update_value.bind(new_value))
	undo_redo.add_undo_method(_update_value.bind(old_value))

	undo_redo.commit_action()


func _update_value(value: Variant) -> void:
	var variable := modify_variable_node.variable

	match variable.type:
		StoryVariable.Type.STRING:
			modify_variable_node.value = str(value)
			if value_editor is not LineEdit:
				push_error('value_editor should be a LineEdit!')
				return
			var focused: bool = value_editor.has_focus()
			var col: int
			if focused:
				col = value_editor.get_caret_column()
			value_editor.text = str(value)
			if focused:
				value_editor.set_caret_column(col)
		StoryVariable.Type.BOOL:
			modify_variable_node.value = null
		StoryVariable.Type.INT:
			modify_variable_node.value = int(value)
			if value_editor is not SpinBox:
				push_error('value_editor should be SpinBox!')
				return
			value_editor.value = int(value)
		StoryVariable.Type.FLOAT:
			modify_variable_node.value = float(value)
			if value_editor is not SpinBox:
				push_error('value_editor should be SpinBox!')
				return
			value_editor.value = float(value)


func _update_operator_picker() -> void:
	_clear_value_editor()
	operator_picker.clear()

	if modify_variable_node == null or modify_variable_node.variable == null:
		return

	var variable := modify_variable_node.variable

	if variable == null:
		return

	var value: Variant = variable.value

	match variable.type:
		StoryVariable.Type.STRING:
			# add CLEAR and ADD
			operator_picker.add_item('CLEAR')
			operator_picker.set_item_metadata(0, ModifyVariableNode.Operation.CLEAR)
			operator_picker.add_item('ADD')
			operator_picker.set_item_metadata(1, ModifyVariableNode.Operation.ADD)
			operator_picker.select(0)
			_on_operator_changed(0)
			# Only show a value_editor if ADD is selected
		StoryVariable.Type.BOOL:
			# add TOGGLE
			operator_picker.add_item('TOGGLE')
			operator_picker.set_item_metadata(0, ModifyVariableNode.Operation.TOGGLE)
			# No value_editor
			_on_operator_changed(0)
			pass
		StoryVariable.Type.INT, StoryVariable.Type.FLOAT:
			# add ADD, SUBTRACT, MULTIPLY, DIVIDE
			operator_picker.add_item('ADD')
			operator_picker.add_item('SUBTRACT')
			operator_picker.add_item('MULTIPLY')
			operator_picker.add_item('DIVIDE')
			operator_picker.set_item_metadata(0, ModifyVariableNode.Operation.ADD)
			operator_picker.set_item_metadata(1, ModifyVariableNode.Operation.SUBTRACT)
			operator_picker.set_item_metadata(2, ModifyVariableNode.Operation.MULTIPLY)
			operator_picker.set_item_metadata(3, ModifyVariableNode.Operation.DIVIDE)
			_on_operator_changed(0)
		_:
			push_error(
				'Invalid type for story variable %s in %s'
				% [modify_variable_node.variable.name, modify_variable_node.instance_id]
			)
			return


func _on_operator_changed(index: int) -> void:
	var new_operator := operator_picker.get_item_metadata(index) as ModifyVariableNode.Operation
	var old_operator := modify_variable_node.operation

	undo_redo.create_action('Change operator')

	undo_redo.add_do_method(_update_operator.bind(new_operator))

	undo_redo.add_undo_method(_update_operator.bind(old_operator))

	undo_redo.commit_action()


func _select_operator(operator: ModifyVariableNode.Operation) -> void:
	for i: int in range(operator_picker.item_count):
		var op := operator_picker.get_item_metadata(i) as ModifyVariableNode.Operation
		if op == operator:
			operator_picker.select(i)
			return


func _update_operator(operator: ModifyVariableNode.Operation) -> void:
	var variable := modify_variable_node.variable
	var value: Variant = modify_variable_node.value

	modify_variable_node.operation = operator
	_select_operator(operator)

	match variable.type:
		StoryVariable.Type.STRING:
			match operator:
				ModifyVariableNode.Operation.CLEAR:
					_clear_value_editor()
				ModifyVariableNode.Operation.ADD:
					if value_editor is not LineEdit:
						_clear_value_editor()
						value_editor = LineEdit.new()
						value_editor.text_changed.connect(_on_value_updated)
						add_child(value_editor)
					if value is String:
						value_editor.text = value
					else:
						value_editor.text = _get_default_value(variable.type)
						modify_variable_node.value = value_editor.text
		StoryVariable.Type.INT, StoryVariable.Type.FLOAT:
			if value_editor is not SpinBox:
				_clear_value_editor()
				value_editor = SpinBox.new()
				value_editor.value_changed.connect(_on_value_updated)
				add_child(value_editor)
			if value is int or value is float:
				value_editor.value = (
					int(value)
					if variable.type == StoryVariable.Type.INT
					else float(value)
				)
			else:
				value_editor.value = _get_default_value(variable.type)
				modify_variable_node.value = value_editor.value
		StoryVariable.Type.BOOL:
			_clear_value_editor()
		_:
			push_error(
				'Invalid type for story variable %s in %s'
				% [modify_variable_node.variable.name, modify_variable_node.instance_id]
			)
			return


func _on_visibility_changed():
	if is_visible_in_tree():
		_select_variable(story_node.variable)
		if visibility_changed.is_connected(_on_visibility_changed):
			visibility_changed.disconnect(_on_visibility_changed)


func _on_variable_selected(index: int) -> void:
	if modify_variable_node == null or story_data == null:
		return

	var previous_variable := modify_variable_node.variable

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
	modify_variable_node.variable = variable
	_refresh_variable_picker()
	_update_operator_picker()
	modify_variable_node.emit_changed()
	story_data.emit_changed()

	var index := _find_index_for_variable(variable)
	variable_picker.select(index)


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

		if modify_variable_node != null and modify_variable_node.variable == variable:
			variable_picker.select(index)


func _get_default_value(type: StoryVariable.Type) -> Variant:
	match type:
		StoryVariable.Type.BOOL:
			return false

		StoryVariable.Type.INT:
			return 0

		StoryVariable.Type.FLOAT:
			return 0.0

		StoryVariable.Type.STRING:
			return ''

	return ''
