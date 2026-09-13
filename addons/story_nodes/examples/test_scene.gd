extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var story := TestStoryData.new()

	assert(story.has_node(&'start'))
	assert(story.has_node(&'choice'))
	assert(story.has_node(&'ending'))

	assert(story.get_links_from(&"start").size() == 1)
	assert(story.get_links_to(&"ending").size() == 1)

	story.remove_node(&'choice')
	assert(story.has_node(&'ending'))
	assert(story.get_links_to(&'ending').size() == 0)
	assert(story.get_links().size() == 0)

	story.remove_node(&'ending')
	assert(not story.has_node(&'ending'))
	assert(story.get_links_to(&'ending').size() == 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
