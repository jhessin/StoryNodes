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
var _standard_node_library: StoryNodeLibrary
var _undo_redo: EditorUndoRedoManager

@onready var file_list: StoryFileList = %StoryFileList
@onready var graph_editor: StoryGraphEditor = %Graph
@onready var characters_editor: StoryCharactersEditor = %StoryCharactersEditor
@onready var cast_editor: StoryCastEditor = %StoryCastEditor
@onready var variables_editor: StoryVariablesEditor = %StoryVariablesEditor
@onready var node_library_editor: StoryNodeLibraryEditor = %StoryNodeLibraryEditor


func _ready() -> void:
	_undo_redo = EditorInterface.get_editor_undo_redo()

	_standard_node_library = StorySettings.get_standard_library()

	_load_character_library()
	_load_variable_library()

	file_list.story_selected.connect(_on_story_selected)

	characters_editor.set_character_library(_character_library)
	cast_editor.set_story_data(null)
	variables_editor.set_variable_library(_variable_library)

	node_library_editor.set_library(_standard_node_library)


func set_story_data(data: StoryData) -> void:
	if _story_data != null:
		if _story_data.changed.is_connected(_on_story_changed):
			_story_data.changed.disconnect(_on_story_changed)

	_story_data = data

	if _story_data != null:
		if _story_data.character_library == null:
			_story_data.character_library = _character_library
		if _story_data.variable_library == null:
			_story_data.variable_library = _variable_library

		_story_data.ensure_start_node()
		_story_data.changed.connect(_on_story_changed)

		file_list.mark_dirty(_story_data)
		file_list.select_path(_story_data.resource_path)
		call_deferred('_inspect_story')

	graph_editor.set_story_data(_story_data)
	cast_editor.set_story_data(_story_data)


func get_undo_redo() -> EditorUndoRedoManager:
	return _undo_redo


func _load_character_library() -> void:
	if ResourceLoader.exists(_character_library_path):
		_character_library = ResourceLoader.load(_character_library_path) as StoryCharacterLibrary
		return

	_character_library = StoryCharacterLibrary.new()
	_character_library.resource_path = _character_library_path

	var error := ResourceSaver.save(_character_library)

	if error != OK:
		push_error('Failed to create character library: %s' % error_string(error))


func _load_variable_library() -> void:
	if ResourceLoader.exists(_variable_library_path):
		_variable_library = ResourceLoader.load(_variable_library_path) as StoryVariableLibrary
		return

	_variable_library = StoryVariableLibrary.new()
	_variable_library.resource_path = _variable_library_path

	var error := ResourceSaver.save(_variable_library)

	if error != OK:
		push_error('Failed to create variable library: %s' % error_string(error))


func _inspect_story() -> void:
	if _story_data == null:
		return
	EditorInterface.inspect_object(_story_data, '', true)


func _on_story_selected(data: StoryData) -> void:
	set_story_data(data)


func _on_story_changed() -> void:
	file_list.mark_dirty(_story_data)
