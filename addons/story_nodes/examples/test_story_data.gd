class_name TestStoryData
extends StoryData


func _init() -> void:
	var start := StoryNode.new()
	start.id = &"start"
	start.display_name = "Start"

	var choice := ChoiceNode.new()
	choice.id = &"choice"
	choice.display_name = "Choice"

	var ending := StoryNode.new()
	ending.id = &"ending"
	ending.display_name = "Ending"

	add_node(start)
	add_node(choice)
	add_node(ending)

	add_link(start.id, choice.id)
	add_link(choice.id, ending.id)
