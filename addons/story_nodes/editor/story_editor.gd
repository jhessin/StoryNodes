@tool
class_name StoryEditor
extends Control

var _character_library_path: String:
	get:
		return StorySettings.get_character_library_path()

var _variable_library_path: String:
	get:
		return StorySettings.get_variable_library_path()

var _story_data: StoryData
var _character_library: StoryCharacterLibrary
var _variable_library: StoryVariableLibrary

@onready var save_button: Button = %SaveButton
@onready var file_list: StoryFileList = %StoryFileList
@onready var graph_editor: StoryGraphEditor = %StoryGraphEditor
@onready var characters_editor: StoryCharactersEditor = %StoryCharactersEditor
@onready var variables_editor: StoryVariablesEditor = %StoryVariablesEditor


func _ready() -> void:
	_load_character_library()
	_load_variable_library()

	file_list.story_selected.connect(_on_story_selected)
	save_button.pressed.connect(_on_save_pressed)

	characters_editor.set_character_library(_character_library)
	variables_editor.set_variable_library(_variable_library)


func set_story_data(data: StoryData) -> void:
	if _story_data != null:
		if _story_data.changed.is_connected(_on_story_changed):
			_story_data.changed.disconnect(_on_story_changed)

	_story_data = data

	if _story_data != null:
		if _story_data.character_library == null:
			_story_data.character_library = _character_library

		_story_data.ensure_start_node()
		_story_data.changed.connect(_on_story_changed)

		file_list.mark_dirty(_story_data)
		file_list.select_path(_story_data.resource_path)
		call_deferred('_inspect_story')

	graph_editor.set_story_data(data)


func save_story() -> Error:
	var error: Error
	if _character_library != null:
		error = ResourceSaver.save(_character_library)

		if error != OK:
			print('Character Library save error: ', error)
			print('Character Library save error string: ', error_string(error))
			return error
	if _variable_library != null:
		error = ResourceSaver.save(_variable_library)

		if error != OK:
			print('Variable Library save error: ', error)
			print('Variable Library save error string: ', error_string(error))
			return error

	if _story_data == null:
		return OK

	print('Story path: ', _story_data.resource_path)
	print('Character library: ', _character_library)
	print(
		'Character library path: ',
		_character_library.resource_path if _character_library != null else 'NULL',
	)

	error = ResourceSaver.save(_story_data)

	print('Story save error: ', error)
	print('Story save error string: ', error_string(error))

	if error != OK:
		return error

	_story_data.is_dirty = false
	file_list.mark_dirty(_story_data)
	file_list.select_path(_story_data.resource_path)

	return OK


func save_character_library() -> Error:
	if _character_library == null:
		return ERR_UNCONFIGURED

	return ResourceSaver.save(_character_library)


func _load_character_library() -> void:
	if ResourceLoader.exists(_character_library_path):
		_character_library = ResourceLoader.load(_character_library_path) as StoryCharacterLibrary
		return

	_character_library = StoryCharacterLibrary.new()
	_character_library.resource_path = _character_library_path

	var error := ResourceSaver.save(_character_library)

	if error != OK:
		push_error('Failed to create character library: %s' % error)


func _load_variable_library() -> void:
	if ResourceLoader.exists(_variable_library_path):
		_variable_library = ResourceLoader.load(_variable_library_path) as StoryVariableLibrary
		return

	_variable_library = StoryVariableLibrary.new()
	_variable_library.resource_path = _variable_library_path

	var error := ResourceSaver.save(_variable_library)

	if error != OK:
		push_error('Failed to create variable library: %s' % error)


func _inspect_story() -> void:
	if _story_data == null:
		return
	EditorInterface.inspect_object(_story_data, '', true)


func _on_story_selected(data: StoryData) -> void:
	set_story_data(data)


func _on_save_pressed() -> void:
	var error := save_story()

	if error != OK:
		push_error('Failed to save story: %s' % error)
	else:
		prints('file saved')


func _on_story_changed() -> void:
	file_list.mark_dirty(_story_data)
