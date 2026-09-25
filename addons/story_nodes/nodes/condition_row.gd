@tool
class_name ConditionRow
extends HBoxContainer

signal delete_requested(condition: BranchCondition)

var condition: BranchCondition
var variable: StoryVariable

@onready var operator_picker: OptionButton = %OperatorPicker
@onready var value_field: LineEdit = %ValueField
@onready var delete_button: Button = %DeleteButton
@onready var drag_handle: StoryDragHandle = %StoryDragHandle


func _ready() -> void:
	operator_picker.item_selected.connect(_on_operator_selected)
	value_field.text_changed.connect(_on_value_changed)
	delete_button.pressed.connect(_on_delete_pressed)
	_populate_operator_picker()
	_refresh_value_field()
	_refresh_value()


func set_condition(value: BranchCondition) -> void:
	condition = value

	if condition == null:
		push_error('ConditionRow requires a BranchCondition')
		return

	drag_handle.drag_data = condition
	_refresh_value_field()
	_refresh_value()


func set_variable(value: StoryVariable) -> void:
	variable = value

	if variable == null:
		push_error('ConditionRow requires a StoryVariable')
		return

	_populate_operator_picker()


func _on_delete_pressed() -> void:
	if condition == null:
		return

	delete_requested.emit(condition)


func _on_operator_selected(index: int) -> void:
	if condition == null:
		return

	condition.operator = operator_picker.get_item_id(index) as BranchCondition.Operator
	condition.emit_changed()
	_refresh_value_field()
	_refresh_value()


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
			operators = [BranchCondition.Operator.IS_TRUE, BranchCondition.Operator.IS_FALSE]

	for operator: BranchCondition.Operator in operators:
		operator_picker.add_item(_get_operator_text(operator))

		var index: int = operator_picker.item_count - 1
		operator_picker.set_item_id(index, operator)

		if condition != null and operator == condition.operator:
			operator_picker.select(index)


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
		BranchCondition.Operator.IS_TRUE:
			return 'Is True'
		BranchCondition.Operator.IS_FALSE:
			return 'Is False'

	return ''


func _refresh_value_field() -> void:
	if condition == null:
		value_field.visible = false
		return

	value_field.visible = (
		condition.operator != BranchCondition.Operator.IS_EMPTY
		and condition.operator != BranchCondition.Operator.IS_NOT_EMPTY
		and condition.operator != BranchCondition.Operator.IS_TRUE
		and condition.operator != BranchCondition.Operator.IS_FALSE
	)


func _refresh_value() -> void:
	if condition == null:
		value_field.text = ''
		return

	if (
		condition.operator == BranchCondition.Operator.IS_EMPTY
		or condition.operator == BranchCondition.Operator.IS_NOT_EMPTY
		or condition.operator == BranchCondition.Operator.IS_TRUE
		or condition.operator == BranchCondition.Operator.IS_FALSE
	):
		value_field.text = ''
		return

	value_field.text = str(condition.value)


func _on_value_changed(value: String) -> void:
	if condition == null or variable == null:
		return

	match variable.type:
		StoryVariable.Type.STRING:
			condition.value = value
		StoryVariable.Type.INT:
			condition.value = value.to_int()

		StoryVariable.Type.FLOAT:
			condition.value = value.to_float()

		StoryVariable.Type.BOOL:
			condition.value = value.to_lower() == 'true'


func _get_operator_index(operator: BranchCondition.Operator) -> int:
	for index: int in operator_picker.item_count:
		if operator_picker.get_item_id(index) == operator:
			return index

	return -1
