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

@export var operator: Operator = Operator.IS_EMPTY
@export var value: Variant

var _undo_redo: UndoRedo


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
