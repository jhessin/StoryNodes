@tool
class_name ConditionRow
extends HBoxContainer

var condition: BranchCondition

@onready var operator_picker: OptionButton = %OperatorPicker
@onready var value_field: LineEdit = %ValueField


func set_condition(value: BranchCondition) -> void:
	condition = value

	if condition == null:
		push_error('ConditionRow requires a BranchCondition')
		return

	operator_picker.select(condition.operator)
