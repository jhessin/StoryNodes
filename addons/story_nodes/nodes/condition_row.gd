@tool
class_name ConditionRow
extends HBoxContainer

var condition: BranchCondition
var variable: StoryVariable

@onready var operator_picker: OptionButton = %OperatorPicker
@onready var value_field: LineEdit = %ValueField


func _ready() -> void:
	operator_picker.item_selected.connect(_on_operator_selected)
	_populate_operator_picker()
	_refresh_value_field()


func set_condition(value: BranchCondition) -> void:
	condition = value

	if condition == null:
		push_error('ConditionRow requires a BranchCondition')
		return

	operator_picker.select(condition.operator)
	_refresh_value_field()


func set_variable(value: StoryVariable) -> void:
	variable = value

	if variable == null:
		push_error('ConditionRow requires a StoryVariable')
		return

	_populate_operator_picker()

	match variable.type:
		StoryVariable.Type.STRING:
			condition.operator = BranchCondition.Operator.IS_EMPTY
			condition.value = ''

		StoryVariable.Type.INT, StoryVariable.Type.FLOAT:
			condition.operator = BranchCondition.Operator.EQUAL
			condition.value = 0

		StoryVariable.Type.BOOL:
			condition.operator = BranchCondition.Operator.EQUAL
			condition.value = false

	operator_picker.select(condition.operator)


func _on_operator_selected(index: int) -> void:
	if condition == null:
		return

	condition.operator = operator_picker.get_item_id(index) as BranchCondition.Operator
	condition.emit_changed()
	_refresh_value_field()


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


func _refresh_value_field() -> void:
	if condition == null:
		value_field.visible = false
		return

	value_field.visible = (
		condition.operator != BranchCondition.Operator.IS_EMPTY
		and condition.operator != BranchCondition.Operator.IS_NOT_EMPTY
	)
