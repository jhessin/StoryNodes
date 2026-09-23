@tool
class_name ConditionRow
extends HBoxContainer

var condition: BranchCondition
var variable: StoryVariable

@onready var operator_picker: OptionButton = %OperatorPicker
@onready var value_field: LineEdit = %ValueField


func _ready() -> void:
	_populate_operator_picker()


func set_condition(value: BranchCondition) -> void:
	condition = value

	if condition == null:
		push_error('ConditionRow requires a BranchCondition')
		return

	operator_picker.select(condition.operator)


func set_variable(value: StoryVariable) -> void:
	variable = value

	if variable == null:
		push_error('ConditionRow requires a StoryVariable')
		return

	_populate_operator_picker()


func _populate_operator_picker() -> void:
	operator_picker.clear()

	if variable == null:
		return

	var operators: Array[BranchCondition.Operator] = []

	match variable.type:
		StoryVariable.Type.STRING:
			operators = [
				BranchCondition.Operator.IS_EMPTY,
				BranchCondition.Operator.IS_NOT_EMPTY,
				BranchCondition.Operator.EQUAL,
				BranchCondition.Operator.NOT_EQUAL,
			]

		StoryVariable.Type.INT, StoryVariable.Type.FLOAT:
			operators = [
				BranchCondition.Operator.EQUAL,
				BranchCondition.Operator.NOT_EQUAL,
				BranchCondition.Operator.LESS,
				BranchCondition.Operator.LESS_EQUAL,
				BranchCondition.Operator.GREATER,
				BranchCondition.Operator.GREATER_EQUAL,
			]

		StoryVariable.Type.BOOL:
			operators = [BranchCondition.Operator.EQUAL, BranchCondition.Operator.NOT_EQUAL]

	for operator: BranchCondition.Operator in operators:
		operator_picker.add_item(_get_operator_text(operator))
		operator_picker.set_item_id(operator_picker.item_count - 1, operator)


func _get_operator_text(operator: BranchCondition.Operator) -> String:
	match operator:
		BranchCondition.Operator.IS_EMPTY:
			return 'Is Empty'
		BranchCondition.Operator.IS_NOT_EMPTY:
			return 'Is Not Empty'
		BranchCondition.Operator.EQUAL:
			return 'Equals'
		BranchCondition.Operator.NOT_EQUAL:
			return 'Does Not Equal'
		BranchCondition.Operator.LESS:
			return '<'
		BranchCondition.Operator.LESS_EQUAL:
			return '<='
		BranchCondition.Operator.GREATER:
			return '>'
		BranchCondition.Operator.GREATER_EQUAL:
			return '>='

	return ''
