@tool
class_name BranchCondition
extends Resource

enum Operator {
	EQUAL,
	NOT_EQUAL,
	LESS,
	LESS_EQUAL,
	GREATER,
	GREATER_EQUAL,
}

@export var operator: Operator = Operator.EQUAL
@export var value: Variant
