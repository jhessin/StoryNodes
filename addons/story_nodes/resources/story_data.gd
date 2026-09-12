class_name StoryData
extends Resource

@export var title: String = ''
@export var description: String = ''

var nodes: Array[StoryNode] = []

var links: Dictionary[StoryLink, Object] = { }


func add_link(from: StringName, to: StringName) -> StoryLink:
	var link := StoryLink.new(from, to)

	links[link] = null

	return link
