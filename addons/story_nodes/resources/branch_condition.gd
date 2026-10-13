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
		if _undo_redo == null:
			_operator = new_value
			emit_changed()
			return

		_undo_redo.create_action('Set name')

		_undo_redo.add_do_property(self, '_operator', new_value)
		_undo_redo.add_undo_property(self, '_operator', old_value)

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

		_undo_redo.create_action('Set name')

		_undo_redo.add_do_property(self, '_value', new_value)
		_undo_redo.add_undo_property(self, '_value', old_value)

		_undo_redo.add_do_method(emit_changed)
		_undo_redo.add_undo_method(emit_changed)
		_undo_redo.commit_action()

var _undo_redo: UndoRedo
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


func set_undo_redo(undo_redo: UndoRedo) -> void:
	if undo_redo == null:
		push_error('Every Branch Condition needs access to the story\'s UndoRedo!')
		return

	_undo_redo = undo_redo
