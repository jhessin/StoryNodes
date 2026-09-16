@tool
class_name StoryVariableLibrary
extends Resource

@export var _variables: Array[StoryVariable] = []

var variable_list: Array[StoryVariable]:
	get:
		return _variables

var variable_count: int:
	get:
		return _variables.size()


func add_variable(variable: StoryVariable) -> void:
	if variable == null:
		return

	if variable.name.is_empty():
		return

	if has_variable(variable.name):
		return

	_variables.append(variable)
	emit_changed()


func remove_variable(variable: StoryVariable) -> void:
	if variable == null:
		return

	if not _variables.has(variable):
		return

	_variables.erase(variable)
	emit_changed()


func get_variable(variable_name: String) -> StoryVariable:
	for variable: StoryVariable in _variables:
		if variable.name == variable_name:
			return variable

	return null


func has_variable(variable_name: String) -> bool:
	return get_variable(variable_name) != null


func has_variables() -> bool:
	return not _variables.is_empty()


func clear() -> void:
	_variables.clear()
	emit_changed()
