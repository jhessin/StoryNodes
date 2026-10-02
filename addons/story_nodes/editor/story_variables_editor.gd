@tool
class_name StoryVariablesEditor
extends HSplitContainer

const ITEM_HEIGHT: float = 32.0

var selected_variable: StoryVariable
var _variable_library: StoryVariableLibrary

@onready var variable_list: ItemList = %VariableList
@onready var name_edit: LineEdit = %NameEdit
@onready var type_option: OptionButton = %TypeOption
@onready var default_value_container: VBoxContainer = %DefaultValueContainer


func _ready() -> void:
	%NewVariableButton.pressed.connect(_on_new_variable_pressed)
	variable_list.item_selected.connect(_on_variable_selected)
	%DeleteButton.pressed.connect(_on_delete_button_pressed)

	name_edit.text_submitted.connect(_on_name_changed)
	type_option.item_selected.connect(_on_type_selected)

	_build_type_options()


func set_variable_library(data: StoryVariableLibrary) -> void:
	if _variable_library != null:
		if _variable_library.changed.is_connected(_save):
			_variable_library.changed.disconnect(_save)
	_variable_library = data

	if not _variable_library.changed.is_connected(_save):
		_variable_library.changed.connect(_save)
	_refresh()


func _on_delete_button_pressed() -> void:
	if _variable_library == null or selected_variable == null:
		return

	var undo_redo := _variable_library.undo_redo

	undo_redo.create_action('Delete Variable')

	undo_redo.add_do_method(_variable_library.remove_variable.bind(selected_variable.name))
	undo_redo.add_do_method(_refresh)

	undo_redo.add_undo_method(_variable_library.add_variable.bind(selected_variable))
	undo_redo.add_undo_method(_refresh)

	undo_redo.commit_action()


func _build_type_options() -> void:
	type_option.clear()

	type_option.add_item('Boolean', StoryVariable.Type.BOOL)
	type_option.add_item('Integer', StoryVariable.Type.INT)
	type_option.add_item('Float', StoryVariable.Type.FLOAT)
	type_option.add_item('String', StoryVariable.Type.STRING)


func _refresh() -> void:
	variable_list.clear()
	selected_variable = null

	if _variable_library == null:
		return

	for variable: StoryVariable in _variable_library.variable_list:
		var index := variable_list.item_count
		variable_list.add_item(variable.name)
		variable_list.set_item_metadata(index, variable)

	_update_item_list_size()


func _update_item_list_size() -> void:
	variable_list.custom_minimum_size.y = variable_list.item_count * ITEM_HEIGHT


func _on_variable_selected(index: int) -> void:
	if _variable_library == null:
		return

	var new_variable := variable_list.get_item_metadata(index) as StoryVariable
	var old_variable := selected_variable

	var undo_redo := _variable_library.undo_redo

	undo_redo.create_action('Select Variable')

	undo_redo.add_do_method(_select_variable.bind(new_variable))
	undo_redo.add_undo_method(_select_variable.bind(old_variable))

	undo_redo.commit_action()


func _on_new_variable_pressed() -> void:
	if _variable_library == null:
		return

	var variable_name := _get_unique_variable_name()

	var variable := StoryVariable.new(variable_name, StoryVariable.Type.STRING, '')

	var undo_redo := _variable_library.undo_redo

	undo_redo.create_action('Add New Variable')

	undo_redo.add_do_method(_variable_library.add_variable.bind(variable))
	undo_redo.add_do_method(_refresh)
	undo_redo.add_do_method(_select_variable.bind(variable))
	undo_redo.add_do_method(name_edit.grab_focus)
	undo_redo.add_do_method(name_edit.select_all)

	undo_redo.add_undo_method(_variable_library.remove_variable.bind(variable.name))
	undo_redo.add_undo_method(_refresh)
	undo_redo.add_undo_method(_select_variable)

	undo_redo.commit_action()


func _select_variable(variable: StoryVariable = null) -> void:
	if variable == null:
		variable_list.deselect_all()

		selected_variable = null

		name_edit.text = ''
		type_option.select(0)
		_rebuild_default_value_editor()

		type_option.disabled = true
		return

	type_option.disabled = false

	var index := _find_index_for_variable(variable)

	if index == -1:
		push_error('Invalid variable selected: ', variable.name)
		return

	variable_list.select(index)

	selected_variable = variable_list.get_item_metadata(index) as StoryVariable

	name_edit.text = selected_variable.name

	var type_index := type_option.get_item_index(selected_variable.type)

	if type_index >= 0:
		type_option.select(type_index)

	_rebuild_default_value_editor()


func _find_index_for_variable(variable: StoryVariable) -> int:
	for i: int in range(variable_list.item_count):
		var current_var := variable_list.get_item_metadata(i) as StoryVariable
		if current_var.name == variable.name:
			return i

	return -1


func _get_unique_variable_name(base_name: StringName = &'new_variable') -> StringName:
	var name := base_name
	var index := 1

	while _variable_library.has_variable(name):
		name = '%s_%d' % [base_name, index]
		index += 1

	return name as StringName


func _rebuild_default_value_editor() -> void:
	for child: Node in default_value_container.get_children():
		child.free()

	if selected_variable == null:
		return

	match selected_variable.type:
		StoryVariable.Type.BOOL:
			_create_bool_editor()

		StoryVariable.Type.INT:
			_create_int_editor()

		StoryVariable.Type.FLOAT:
			_create_float_editor()

		StoryVariable.Type.STRING:
			_create_string_editor()


func _update_default_value_editor() -> void:
	var editor: Node = default_value_container.get_children()[0]

	match selected_variable.type:
		StoryVariable.Type.BOOL:
			if editor is not CheckBox:
				push_error('Invalid bool editor')
				return

			editor.button_pressed = bool(selected_variable.default_value)
		StoryVariable.Type.INT:
			if editor is not SpinBox:
				push_error('Invalid int editor')
				return
			editor.value = int(selected_variable.default_value)

		StoryVariable.Type.FLOAT:
			if editor is not SpinBox:
				push_error('Invalid float editor')
				return
			editor.value = float(selected_variable.default_value)

		StoryVariable.Type.STRING:
			if editor is not LineEdit:
				push_error('Invalid string editor')
				return
			editor.text = str(selected_variable.default_value)


func _create_bool_editor() -> void:
	var editor := CheckBox.new()

	editor.text = 'Default Value'
	editor.button_pressed = bool(selected_variable.default_value)

	editor.toggled.connect(_on_bool_default_changed)

	default_value_container.add_child(editor)


func _create_int_editor() -> void:
	var editor := SpinBox.new()

	editor.name = 'DefaultValueEdit'
	editor.min_value = -9223372036854775808.0
	editor.max_value = 9223372036854775807.0
	editor.step = 1.0
	editor.value = int(selected_variable.default_value)

	editor.value_changed.connect(_on_int_default_changed)

	default_value_container.add_child(editor)


func _create_float_editor() -> void:
	var editor := SpinBox.new()

	editor.name = 'DefaultValueEdit'
	editor.min_value = -1000000000.0
	editor.max_value = 1000000000.0
	editor.step = 0.01
	editor.value = float(selected_variable.default_value)

	editor.value_changed.connect(_on_float_default_changed)

	default_value_container.add_child(editor)


func _create_string_editor() -> void:
	var editor := LineEdit.new()

	editor.name = 'DefaultValueEdit'
	editor.text = str(selected_variable.default_value)

	editor.text_submitted.connect(_on_string_default_changed)

	default_value_container.add_child(editor)


func _on_bool_default_changed(new_value: bool) -> void:
	if selected_variable == null:
		return

	var undo_redo := _variable_library.undo_redo
	var old_value := bool(selected_variable.default_value)

	undo_redo.create_action('Change default value')

	undo_redo.add_do_property(selected_variable, 'default_value', bool(new_value))
	undo_redo.add_do_method(_update_default_value_editor)
	undo_redo.add_do_method(_variable_library.emit_changed)

	undo_redo.add_undo_property(selected_variable, 'default_value', old_value)
	undo_redo.add_undo_method(_update_default_value_editor)
	undo_redo.add_undo_method(_variable_library.emit_changed)

	undo_redo.commit_action()


func _on_int_default_changed(new_value: float) -> void:
	if selected_variable == null:
		return

	var old_value := int(selected_variable.default_value)
	var undo_redo := _variable_library.undo_redo

	undo_redo.create_action('Change default value')

	undo_redo.add_do_property(selected_variable, 'default_value', int(new_value))
	undo_redo.add_do_method(_update_default_value_editor)
	undo_redo.add_do_method(_variable_library.emit_changed)

	undo_redo.add_undo_property(selected_variable, 'default_value', old_value)
	undo_redo.add_undo_method(_update_default_value_editor)
	undo_redo.add_undo_method(_variable_library.emit_changed)

	undo_redo.commit_action()


func _on_float_default_changed(new_value: float) -> void:
	if selected_variable == null:
		return

	var old_value := float(selected_variable.default_value)
	var undo_redo := _variable_library.undo_redo

	undo_redo.create_action('Change default value')

	undo_redo.add_do_property(selected_variable, 'default_value', float(new_value))
	undo_redo.add_do_method(_update_default_value_editor)
	undo_redo.add_do_method(_variable_library.emit_changed)

	undo_redo.add_undo_property(selected_variable, 'default_value', old_value)
	undo_redo.add_undo_method(_update_default_value_editor)
	undo_redo.add_undo_method(_variable_library.emit_changed)

	undo_redo.commit_action()


func _on_string_default_changed(new_value: String) -> void:
	if selected_variable == null:
		return

	var old_value := str(selected_variable.default_value)
	var undo_redo := _variable_library.undo_redo

	undo_redo.create_action('Change default value')

	undo_redo.add_do_property(selected_variable, 'default_value', str(new_value))
	undo_redo.add_do_method(_update_default_value_editor)
	undo_redo.add_do_method(_variable_library.emit_changed)

	undo_redo.add_undo_property(selected_variable, 'default_value', old_value)
	undo_redo.add_undo_method(_update_default_value_editor)
	undo_redo.add_undo_method(_variable_library.emit_changed)

	undo_redo.commit_action()


func _on_name_changed(new_name: StringName) -> void:
	if selected_variable == null:
		return

	if new_name.is_empty():
		return

	if new_name == selected_variable.name:
		return

	# TODO
	var old_variable := selected_variable
	var old_value := old_variable.name
	var new_value := _variable_library.resolve_name(old_value, new_name)
	var undo_redo := _variable_library.undo_redo

	if new_value.is_empty():
		push_error('Could not update the name of %s to %s' % [old_value, new_value])
		return

	var new_variable := old_variable.duplicate()
	new_variable.name = new_value

	undo_redo.create_action('Change variable name')

	undo_redo.add_do_method(_variable_library.rename_variable.bind(old_value, new_value))
	undo_redo.add_do_method(_refresh)
	undo_redo.add_do_method(_select_variable.bind(new_variable))

	undo_redo.add_undo_method(_variable_library.rename_variable.bind(new_value, old_value))
	undo_redo.add_undo_method(_refresh)
	undo_redo.add_undo_method(_select_variable.bind(old_variable))

	undo_redo.commit_action()


func _on_type_selected(index: int) -> void:
	if selected_variable == null:
		return

	var new_type := type_option.get_item_id(index) as StoryVariable.Type

	if selected_variable.type == new_type:
		return

	selected_variable.type = new_type
	selected_variable.default_value = _get_default_value(new_type)

	_variable_library.emit_changed()

	_rebuild_default_value_editor()


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


func _save() -> void:
	if _variable_library == null:
		return

	var error = ResourceSaver.save(_variable_library)

	if error != OK:
		push_error('Error saving Variable library: ', error_string(error))
