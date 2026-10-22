@tool
class_name StoryVariableLibrary
extends Resource

@export_storage
var _variables: Dictionary[StringName, StoryVariable] = { }

var variable_list: Array[StoryVariable]:
	get:
		return _variables.values()

var variable_count: int:
	get:
		return _variables.size()

var variable_names: Array[StringName]:
	get:
		return _variables.keys()

var undo_redo: UndoRedo = UndoRedo.new()


func _init() -> void:
	_undo_redo_setup()


func undo_redo_setup() -> void:
	_undo_redo_setup()


func add_variable(variable: StoryVariable) -> void:
	if variable == null:
		push_error('Cannot add a null variable.')
		return

	if variable.name.is_empty():
		push_error('Cannot add a variable with an empty name.')
		return

	if _variables.has(variable.name):
		push_error('Variable "%s" already exists.' % variable.name)
		return

	variable.set_undo_redo(undo_redo)

	undo_redo.create_action('Add variable')

	undo_redo.add_do_method(_add_variable.bind(variable))
	undo_redo.add_undo_method(_remove_variable.bind(variable.name))

	undo_redo.commit_action()


func remove_variable(id: StringName) -> void:
	if not _variables.has(id):
		push_error('Cannot remove variable "%s": variable does not exist.' % id)
		return

	var variable: StoryVariable = _variables[id]

	undo_redo.create_action('Remove variable')

	undo_redo.add_do_method(_remove_variable.bind(id))
	undo_redo.add_undo_method(_add_variable.bind(variable))

	undo_redo.commit_action()


func rename_variable(old_name: StringName, new_name: StringName) -> void:
	new_name = _resolve_name(old_name, new_name)

	if new_name.is_empty():
		push_error('Cannot rename a variable with an empty name!')
		return

	undo_redo.create_action('Rename variable')

	undo_redo.add_do_method(_rename_variable.bind(old_name, new_name))
	undo_redo.add_undo_method(_remove_variable.bind(new_name, old_name))

	undo_redo.commit_action()


func get_variable(variable_name: StringName) -> StoryVariable:
	return _variables.get(variable_name, null)


func has_variable(variable_name: StringName) -> bool:
	return get_variable(variable_name) != null


func _rename_variable(old_name: StringName, new_name: StringName) -> void:
	var variable := get_variable(old_name)
	variable.name = new_name

	remove_variable(old_name)
	add_variable(variable)
	emit_changed()


func _resolve_name(old_name: StringName, new_name: StringName) -> StringName:
	if not _variables.has(old_name):
		push_error('Cannot rename "%s": variable does not exist.' % old_name)
		return &''

	while _variables.has(new_name):
		new_name += '_'

	return new_name


func _add_variable(variable: StoryVariable) -> void:
	_variables[variable.name] = variable
	emit_changed()


func _remove_variable(id: StringName) -> void:
	_variables.erase(id)
	emit_changed()


func _undo_redo_setup() -> void:
	for variable: StoryVariable in _variables.values():
		variable.set_undo_redo(undo_redo)
