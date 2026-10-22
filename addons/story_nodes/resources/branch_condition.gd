@tool
class_name BranchCondition
extends Resource

enum Operator {
	IS_EMPTY,
	IS_NOT_EMPTY,
	IS_TRUE,
	IS_FALSE,
	EQUAL,
	NOT_EQUAL,
	LESS,
	LESS_EQUAL,
	GREATER,
	GREATER_EQUAL,
}

@export var operator: Operator:
	get:
		return _operator
	set(new_value):
		var old_value = _operator
		if old_value == new_value:
			return
		if _history == null:
			_operator = new_value
			emit_changed()
			return

		_history.record_property(
			'Set Operator',
			self,
			&'_operator',
			new_value,
			_operator,
			emit_changed,
		)

@export var value: Variant:
	get:
		return _value
	set(new_value):
		var old_value = _value
		if old_value == new_value:
			return
		if _history == null:
			_value = new_value
			emit_changed()
			return

		_history.record_property('Set Value', self, &'_value', new_value, _value, emit_changed)

var _history: StoryHistory
var _operator: Operator = Operator.IS_EMPTY
var _value: Variant


func initialize_for_variable(variable: StoryVariable) -> void:
	if variable == null:
		return

	match variable.type:
		StoryVariable.Type.STRING:
			operator = Operator.IS_EMPTY
			value = ''

		StoryVariable.Type.INT, StoryVariable.Type.FLOAT:
			operator = Operator.EQUAL
			value = 0

		StoryVariable.Type.BOOL:
			operator = Operator.IS_FALSE
			value = false


func set_history(history: StoryHistory) -> void:
	if history == null:
		push_error('Every Branch Condition needs access to the story\'s history!')
		return

	_history = history
