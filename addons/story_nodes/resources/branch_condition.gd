@tool
class_name BranchCondition
extends Resource

enum Operator {
	IS_EMPTY,
	IS_NOT_EMPTY,
	EQUAL,
	NOT_EQUAL,
	LESS,
	LESS_EQUAL,
	GREATER,
	GREATER_EQUAL,
}

@export var operator: Operator = Operator.IS_EMPTY
@export var value: Variant

var id: StringName:
	get:
		return "%s_%s" % [operator, value] as StringName


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
			operator = Operator.EQUAL
			value = false
