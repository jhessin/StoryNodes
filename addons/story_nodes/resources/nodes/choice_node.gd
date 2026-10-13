@tool
class_name ChoiceNode
extends StoryNode

@export var choices: Array[String] = []:
	get:
		return _choices.duplicate()

var _choices: Array[String] = []


func add_choice(new_choice: String, index: int = -1) -> void:
	if index == -1:
		index = _choices.size()

	if _undo_redo == null:
		push_error('UndoRedo for story node: %s (%s) was not initialized!' % [node_id, instance_id])
		return

	_undo_redo.create_action('Add a choice')

	_undo_redo.add_do_method(_add_choice.bind(new_choice, index))
	_undo_redo.add_undo_method(_remove_choice.bind(index))

	_undo_redo.commit_action()


func remove_choice(index: int) -> void:
	if index < 0 or index >= _choices.size():
		push_error('Invalid index for choice to remove: %s of %s' % [index, _choices.size()])
		return

	if _undo_redo == null:
		push_error('UndoRedo for story node: %s (%s) was not initialized!' % [node_id, instance_id])
		return

	_undo_redo.create_action('Remove a choice')
	var choice: String = _choices[index]

	_undo_redo.add_do_method(_remove_choice.bind(index))
	_undo_redo.add_undo_method(_add_choice.bind(choice, index))

	_undo_redo.commit_action()


func move_choice(from_index: int, to_index: int) -> void:
	if from_index < 0 or from_index >= _choices.size():
		return

	if to_index < 0 or to_index >= _choices.size():
		return

	if from_index == to_index:
		return

	var choice: String = _choices[from_index]
	_choices.remove_at(from_index)
	_choices.insert(to_index, choice)

	emit_changed()


func _add_choice(choice: String, index: int) -> void:
	_choices.insert(index, choice)
	emit_changed()


func _remove_choice(index: int) -> void:
	_choices.remove_at(index)
	emit_changed()
