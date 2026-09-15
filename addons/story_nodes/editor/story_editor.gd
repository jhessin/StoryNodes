@tool
class_name StoryEditor
extends Control

var _story_data: StoryData

@onready var save_button: Button = %SaveButton
@onready var file_list: StoryFileList = %StoryFileList
@onready var graph_editor: StoryGraphEditor = %StoryGraphEditor
@onready var characters_editor: StoryCharactersEditor = %StoryCharactersEditor


func _ready() -> void:
	file_list.story_selected.connect(_on_story_selected)
	save_button.pressed.connect(_on_save_pressed)


func set_story_data(data: StoryData) -> void:
	if _story_data != null:
		if _story_data.changed.is_connected(_on_story_changed):
			_story_data.changed.disconnect(_on_story_changed)

	_story_data = data

	if _story_data != null:
		_story_data.ensure_start_node()
		_story_data.changed.connect(_on_story_changed)
		file_list.mark_dirty(_story_data)
		file_list.select_path(_story_data.resource_path)
		call_deferred('_inspect_story')

	graph_editor.set_story_data(data)
	characters_editor.set_story_data(data)


func save_story() -> Error:
	if _story_data == null:
		return ERR_UNCONFIGURED

	var error := ResourceSaver.save(_story_data)

	if error == OK:
		_story_data.is_dirty = false
		file_list.mark_dirty(_story_data)

	file_list.select_path(_story_data.resource_path)

	return error


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
