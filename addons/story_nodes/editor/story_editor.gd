@tool
class_name StoryEditor
extends Control

var _story_data: StoryData

@onready var save_button: Button = %SaveButton
@onready var file_list: StoryFileList = %StoryFileList
@onready var graph_editor: StoryGraphEditor = %StoryGraphEditor
@onready var characters_editor: StoryCharactersEditor = %StoryCharactersEditor


func _ready() -> void:
	file_list.story_selected.connect(set_story_data)
	save_button.pressed.connect(_on_save_pressed)


func set_story_data(data: StoryData) -> void:
	_story_data = data
	graph_editor.set_story_data(_story_data)
	characters_editor.set_story_data(_story_data)
	EditorInterface.inspect_object(_story_data, '', true)


func save_story() -> Error:
	if _story_data == null:
		return ERR_UNCONFIGURED

	return ResourceSaver.save(_story_data)


func _on_save_pressed() -> void:
	var error := save_story()

	if error != OK:
		push_error('Failed to save story: %s' % error)
	else:
		prints('file saved')
