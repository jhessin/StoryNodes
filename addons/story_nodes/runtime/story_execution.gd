class_name StoryExecution
extends RefCounted

var story: StoryData
var current_node: StoryNode

var variables: Dictionary[StringName, Variant] = { }


func _init(story_data: StoryData) -> void:
	story = story_data
	_initialize_variables()
	reset_position()


func reset_position() -> void:
	current_node = story.get_start_node()


func restart() -> void:
	reset_position()


func has_variable(variable_name: StringName) -> bool:
	return variables.has(variable_name)


func get_variable(variable_name: StringName) -> Variant:
	return variables.get(variable_name)


func set_variable(variable_name: StringName, value: Variant) -> void:
	if not variables.has(variable_name):
		return

	variables[variable_name] = value


func reset_variables() -> void:
	_initialize_variables()


func _initialize_variables() -> void:
	variables.clear()

	var library: StoryVariableLibrary = story.variable_library

	if library == null:
		return

	for variable: StoryVariable in library.variable_list:
		variables[variable.name] = variable.default_value
