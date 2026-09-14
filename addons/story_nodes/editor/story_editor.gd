@tool
class_name StoryEditor
extends Control

@onready var save_button: Button = %SaveButton
@onready var file_list: StoryFileList = %StoryFileList
@onready var graph_editor: StoryGraphEditor = %StoryGraphEditor


func _ready() -> void:
	file_list.story_selected.connect(set_story_data)
	save_button.pressed.connect(graph_editor.save_story)


func set_story_data(data: StoryData) -> void:
	graph_editor.set_story_data(data)
	EditorInterface.inspect_object(data, '', true)
