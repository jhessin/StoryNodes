@tool
class_name StoryEditor
extends Control

@onready var graph_editor: StoryGraphEditor = %StoryGraphEditor


func set_story_data(data: StoryData) -> void:
	graph_editor.set_story_data(data)
