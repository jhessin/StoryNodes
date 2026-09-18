@tool
class_name StoryVariableLibrary
extends Resource

var variable_list: Array[StoryVariable]:
	get:
		return _variables.values()

var variable_count: int:
	get:
		return _variables.size()

var variable_names: Array[StringName]:
	get:
		return _variables.keys()

@export_storage
var _variables: Dictionary[StringName, StoryVariable] = { }


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

	_variables[variable.name] = variable
	emit_changed()


func remove_variable(id: StringName) -> void:
	if not _variables.has(id):
		push_error('Cannot remove variable "%s": variable does not exist.' % id)
		return

	_variables.erase(id)
	emit_changed()


func rename_variable(old_name: StringName, new_name: StringName) -> StringName:
	if not _variables.has(old_name):
		push_error('Cannot rename "%s": variable does not exist.' % old_name)
		return &''

	if _variables.has(new_name):
		push_error('Cannot use "%s": variable name is already used.')
		return &''

	var variable := get_variable(old_name)
	variable.name = new_name

	remove_variable(old_name)
	add_variable(variable)
	return variable.name


func get_variable(variable_name: StringName) -> StoryVariable:
	return _variables.get(variable_name, null)


func has_variable(variable_name: StringName) -> bool:
	return get_variable(variable_name) != null


func has_variables() -> bool:
	return not _variables.is_empty()


func clear() -> void:
	_variables.clear()
	emit_changed()
