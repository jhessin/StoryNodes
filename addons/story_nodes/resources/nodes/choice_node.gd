@tool
class_name ChoiceNode
extends StoryNode

## Read-only copy. Edit through add_choice(), set_choice(), remove_choice() and
## move_choice(). The setter only exists so the resource loads from disk.
@export var choices: Array[String] = []:
	get:
		return _choices.duplicate()
	set(new_value):
		_choices.assign(new_value)

var _choices: Array[String] = []


func add_choice(new_choice: String, index: int = -1) -> void:
	if index == -1:
		index = _choices.size()

	if _history == null:
		push_error('UndoRedo for story node: %s (%s) was not initialized!' % [node_id, instance_id])
		return

	_history.record('Add A Choice', _add_choice.bind(new_choice, index), _remove_choice.bind(index))



func set_choice(index: int, text: String) -> void:
	if index < 0 or index >= _choices.size() or _choices[index] == text:
		return

	if _history == null:
		push_error('History for story node: %s (%s) was not initialized!' % [node_id, instance_id])
		return

	_history.record(
		'Update A Choice',
		_set_choice.bind(index, text),
		_set_choice.bind(index, _choices[index]),
	)


func remove_choice(index: int) -> void:
	if index < 0 or index >= _choices.size():
		push_error('Invalid index for choice to remove: %s of %s' % [index, _choices.size()])
		return

	if _history == null:
		push_error('UndoRedo for story node: %s (%s) was not initialized!' % [node_id, instance_id])
		return

	var choice: String = _choices[index]
	_history.record('Remove A Choice', _remove_choice.bind(index), _add_choice.bind(choice, index))


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


func _set_choice(index: int, text: String) -> void:
	if index < 0 or index >= _choices.size():
		return

	_choices[index] = text
	emit_changed()


func _add_choice(choice: String, index: int) -> void:
	_choices.insert(index, choice)
	emit_changed()


func _remove_choice(index: int) -> void:
	_choices.remove_at(index)
	emit_changed()
