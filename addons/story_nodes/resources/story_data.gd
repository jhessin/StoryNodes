class_name StoryData
extends Resource

@export var title: String = ''
@export var description: String = ''

@export var nodes: Array[StoryNode] = []

var links: Dictionary[StoryLink, Object] = { }
