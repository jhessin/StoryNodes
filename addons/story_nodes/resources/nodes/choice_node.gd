@tool
class_name ChoiceNode
extends StoryNode

@export var choices: Array[String] = []


func move_choice(from_index: int, to_index: int) -> void:
	if from_index < 0 or from_index >= choices.size():
		return

	if to_index < 0 or to_index >= choices.size():
		return

	if from_index == to_index:
		return

	var choice: String = choices[from_index]
	choices.remove_at(from_index)
	choices.insert(to_index, choice)

	emit_changed()
