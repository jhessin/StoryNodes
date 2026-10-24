@tool
class_name BranchNode
extends StoryNode

@export var variable: StoryVariable:
	get:
		return _variable
	set(new_value):
		if _variable == new_value:
			return
		if _history == null:
			_variable = new_value
			emit_changed()
			return

		if new_value != null:
			new_value.set_history(_history)

		_history.record_property(
			'Set Variable',
			self,
			&'_variable',
			new_value,
			_variable,
			emit_changed,
		)

@export var conditions: Array[BranchCondition]:
	get:
		return _conditions.duplicate()

var _conditions: Array[BranchCondition] = []

var _variable: StoryVariable


func add_condition(condition: BranchCondition, index: int = -1) -> void:
	if index < 0:
		index = _conditions.size()

	condition.set_history(_history)
	if _history == null:
		push_error('History for story node: %s (%s) was not initialized!' % [node_id, instance_id])
		return

	_history.record(
		'Add A Condition',
		_add_condition.bind(condition, index),
		_remove_condition.bind(index),
	)


func remove_condition(index: int) -> void:
	if index < 0 or index > _conditions.size():
		push_error(
			'Invalid index for condition to be removed: %d of %d' % [index, _conditions.size()]
		)
		return

	if _history == null:
		push_error('History for story node: %s (%s) was not initialized!' % [node_id, instance_id])
		return

	var condition: BranchCondition = _conditions[index]
	_history.record(
		'Remove Condition',
		_remove_condition.bind(index),
		_add_condition.bind(condition, index),
	)


func set_history(history: StoryHistory) -> void:
	for condition: BranchCondition in _conditions:
		condition.set_history(history)

	super.set_history(history)


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
