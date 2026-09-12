extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var story := TestStoryData.new()

	print(story.has_node(&"start"))
	print(story.has_node(&"choice"))

	print(story.get_links_from(&"start").size())
	print(story.get_links_to(&"ending").size())

	story.remove_node(&'choice')
	print(story.has_node(&'ending'))
	print(story.get_links_to(&'ending').size())
	for link: StoryLink in story.links:
		print(link.from, '->', link.to)

	story.remove_node(&'ending')
	print(story.has_node(&'ending'))
	print(story.get_links_to(&'ending').size())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
