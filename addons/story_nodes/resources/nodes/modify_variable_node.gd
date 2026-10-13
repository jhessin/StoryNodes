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
		if _undo_redo == null:
			_variable = new_value
			emit_changed()
			return

		_undo_redo.create_action('Set variable')

		_undo_redo.add_do_property(self, '_variable', new_value)
		_undo_redo.add_undo_property(self, '_variable', old_value)

		_undo_redo.add_do_method(emit_changed)
		_undo_redo.add_undo_method(emit_changed)
		_undo_redo.commit_action()
@export var operation: Operation:
	get:
		return _operation
	set(new_value):
		var old_value = _operation
		if old_value == new_value:
			return
		if _undo_redo == null:
			_operation = new_value
			emit_changed()
			return

		_undo_redo.create_action('Set operation')

		_undo_redo.add_do_property(self, '_operation', new_value)
		_undo_redo.add_undo_property(self, '_operation', old_value)

		_undo_redo.add_do_method(emit_changed)
		_undo_redo.add_undo_method(emit_changed)
		_undo_redo.commit_action()
@export var value: Variant:
	get:
		return _value
	set(new_value):
		var old_value = _value
		if old_value == new_value:
			return
		if _undo_redo == null:
			_value = new_value
			emit_changed()
			return

		_undo_redo.create_action('Set value')

		_undo_redo.add_do_property(self, '_value', new_value)
		_undo_redo.add_undo_property(self, '_value', old_value)

		_undo_redo.add_do_method(emit_changed)
		_undo_redo.add_undo_method(emit_changed)
		_undo_redo.commit_action()

var _operation: Operation = Operation.CLEAR

var _variable: StoryVariable
var _value: Variant
