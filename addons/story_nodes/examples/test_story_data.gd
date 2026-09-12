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

	nodes.append(start)
	nodes.append(choice)
	nodes.append(ending)

	add_link(start.id, choice.id)
	add_link(choice.id, ending.id)
