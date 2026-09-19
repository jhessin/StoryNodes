class_name StoryRuntimeNode
extends Node

signal on_execute(story_node: StoryNode)

var story_node: StoryNode


func execute() -> void:
	on_execute.emit(story_node)
