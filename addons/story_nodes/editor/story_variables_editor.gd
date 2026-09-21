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
	_variable_library = data
	_refresh()


func _on_delete_button_pressed() -> void:
	if _variable_library == null or selected_variable == null:
		return

	_variable_library.remove_variable(selected_variable.name)
	_refresh()


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
		variable_list.add_item(variable.name)

	_update_item_list_size()


func _update_item_list_size() -> void:
	variable_list.custom_minimum_size.y = variable_list.item_count * ITEM_HEIGHT


func _on_variable_selected(index: int) -> void:
	if _variable_library == null:
		return

	var variables := _variable_library.variable_list

	if index < 0 or index >= variables.size():
		return

	selected_variable = variables[index]

	name_edit.text = selected_variable.name

	var type_index := type_option.get_item_index(selected_variable.type)

	if type_index >= 0:
		type_option.select(type_index)

	_rebuild_default_value_editor()


func _on_new_variable_pressed() -> void:
	if _variable_library == null:
		return

	var variable_name := _get_unique_variable_name()

	var variable := StoryVariable.new(variable_name, StoryVariable.Type.STRING, '')

	_variable_library.add_variable(variable)

	_refresh()

	var index := _variable_library.variable_list.find(variable)

	if index == -1:
		return

	variable_list.select(index)
	_on_variable_selected(index)

	name_edit.grab_focus()
	name_edit.select_all()


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

	editor.text_changed.connect(_on_string_default_changed)

	default_value_container.add_child(editor)


func _on_bool_default_changed(value: bool) -> void:
	if selected_variable == null:
		return

	selected_variable.default_value = value
	_variable_library.emit_changed()


func _on_int_default_changed(value: float) -> void:
	if selected_variable == null:
		return

	selected_variable.default_value = int(value)
	_variable_library.emit_changed()


func _on_float_default_changed(value: float) -> void:
	if selected_variable == null:
		return

	selected_variable.default_value = value
	_variable_library.emit_changed()


func _on_string_default_changed(value: String) -> void:
	if selected_variable == null:
		return

	selected_variable.default_value = value
	_variable_library.emit_changed()


func _on_name_changed(new_name: StringName) -> void:
	if selected_variable == null:
		return

	if new_name.is_empty():
		return

	if new_name == selected_variable.name:
		return

	var resolved_name = _variable_library.rename_variable(selected_variable.name, new_name)

	if resolved_name.is_empty():
		push_error('Could not update the name of %s' % new_name)
		return

	_refresh()


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
