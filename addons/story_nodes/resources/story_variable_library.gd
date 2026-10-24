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
var history: StoryHistory:
	get:
		return _history

var has_undo: bool:
	get:
		return _history.undo_redo.has_undo()

var has_redo: bool:
	get:
		return _history.undo_redo.has_redo()
var _history: StoryHistory = StoryHistory.new()


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

	variable.set_history(_history)

	_history.record(
		'Add Variable',
		_add_variable.bind(variable),
		_remove_variable.bind(variable.name),
	)


func remove_variable(id: StringName) -> void:
	if not _variables.has(id):
		push_error('Cannot remove variable "%s": variable does not exist.' % id)
		return

	var variable: StoryVariable = _variables[id]

	_history.record(
		'Remove Variable',
		_remove_variable.bind(id),
		_add_variable.bind(variable),
		emit_changed,
	)


func rename_variable(old_name: StringName, new_name: StringName) -> void:
	new_name = _resolve_name(old_name, new_name)

	if new_name.is_empty():
		push_error('Cannot rename a variable with an empty name!')
		return

	_history.record(
		'Rename Variable',
		_rename_variable.bind(old_name, new_name),
		_rename_variable.bind(new_name, old_name),
	)


func get_variable(variable_name: StringName) -> StoryVariable:
	return _variables.get(variable_name, null)


func has_variable(variable_name: StringName) -> bool:
	return get_variable(variable_name) != null


func undo() -> void:
	_history.undo_redo.undo()


func redo() -> void:
	_history.undo_redo.redo()


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
