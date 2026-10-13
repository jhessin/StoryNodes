@tool
class_name BranchNode
extends StoryNode

@export var variable: StoryVariable:
	get:
		return _variable
	set(new_value):
		var old_value = variable
		if old_value == new_value:
			return
		if _undo_redo == null:
			_variable = new_value
			emit_changed()
			return

		if new_value != null:
			new_value.set_undo_redo(_undo_redo)

		_undo_redo.create_action('Set variable')

		_undo_redo.add_do_property(self, '_variable', new_value)
		_undo_redo.add_undo_property(self, '_variable', old_value)

		_undo_redo.add_do_method(emit_changed)
		_undo_redo.add_undo_method(emit_changed)
		_undo_redo.commit_action()

@export var conditions: Array[BranchCondition]:
	get:
		return _conditions.duplicate()

var _conditions: Array[BranchCondition] = []

var _variable: StoryVariable


func add_condition(condition: BranchCondition, index: int = -1) -> void:
	if index < 0:
		index = _conditions.size()

	condition.set_undo_redo(_undo_redo)
	if _undo_redo == null:
		push_error('UndoRedo for story node: %s (%s) was not initialized!' % [node_id, instance_id])
		return

	_undo_redo.create_action('Add a condition')

	_undo_redo.add_do_method(_add_condition.bind(condition, index))
	_undo_redo.add_undo_method(_remove_condition.bind(index))

	_undo_redo.commit_action()


func remove_condition(index: int) -> void:
	if index < 0 or index > _conditions.size():
		push_error(
			'Invalid index for condition to be removed: %d of %d' % [index, _conditions.size()]
		)
		return

	if _undo_redo == null:
		push_error('UndoRedo for story node: %s (%s) was not initialized!' % [node_id, instance_id])
		return

	_undo_redo.create_action('Remove condition')
	var condition: BranchCondition = _conditions[index]

	_undo_redo.add_do_method(_remove_condition.bind(index))
	_undo_redo.add_undo_method(_add_condition.bind(condition, index))

	_undo_redo.commit_action()


func set_undo_redo(undo_redo: UndoRedo) -> void:
	if variable != null:
		variable.set_undo_redo(undo_redo)

	for condition: BranchCondition in _conditions:
		condition.set_undo_redo(undo_redo)

	super.set_undo_redo(undo_redo)


func _add_condition(condition: BranchCondition, index: int) -> void:
	if index < 0 or index > _conditions.size():
		push_error(
			'Invalid index for condition to be added: %d of %d' % [index, _conditions.size()]
		)
		return

	_conditions.insert(index, condition)
	emit_changed()


func _remove_condition(index: int) -> void:
	if index < 0 or index >= _conditions.size():
		push_error(
			'Invalid index for condition to be removed: %d of %d' % [index, _conditions.size()]
		)
		return

	_conditions.remove_at(index)
	emit_changed()
