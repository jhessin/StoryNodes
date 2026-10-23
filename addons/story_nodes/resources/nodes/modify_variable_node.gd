@tool
class_name ModifyVariableNode
extends StoryNode

enum Operation {
	CLEAR,
	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE,
	TOGGLE,
}

@export var variable: StoryVariable:
	get:
		return _variable
	set(new_value):
		var old_value = _variable
		if old_value == new_value:
			return
		if _history == null:
			_variable = new_value
			emit_changed()
			return

		_history.record_property('Set Variable', self, &'_variable', new_value, old_value, emit_changed)

@export var operation: Operation:
	get:
		return _operation
	set(new_value):
		var old_value = _operation
		if old_value == new_value:
			return
		if _history == null:
			_operation = new_value
			emit_changed()
			return

		_history.record_property('Set Operation', self, &'_operation', new_value, old_value, emit_changed)

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

		_history.record_property('Set Value', self, &'_value', new_value, old_value, emit_changed)

var _operation: Operation = Operation.CLEAR

var _variable: StoryVariable
var _value: Variant
