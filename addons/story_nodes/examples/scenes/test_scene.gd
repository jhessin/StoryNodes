extends Node


func _ready() -> void:
	var story := StoryData.new()

	var first := StoryNode.new()
	first.id = &"first"
	first.display_name = "First"

	var second := StoryNode.new()
	second.id = &"second"
	second.display_name = "Second"

	story.add_node(first)
	story.add_node(second)
	story.add_link(&"first", &"second")

	var path := "user://story_test.tres"

	ResourceSaver.save(story, path)

	var loaded := ResourceLoader.load(path) as StoryData

	if loaded == null:
		push_error("Failed to load StoryData.")
		return

	print("Nodes: ", loaded.node_count)
	print("Links: ", loaded.link_count)
	print("First: ", loaded.get_node(&"first").display_name)
	print("Connected: ", loaded.has_link(&"first", &"second", 0, 0))
