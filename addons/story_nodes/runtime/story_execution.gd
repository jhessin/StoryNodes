class_name StoryExecution
extends RefCounted
## Steps through a StoryData graph. It knows nothing about UI: connect to the
## signals to present the story, then call advance() or choose() to continue.

signal story_started
signal dialogue_shown(character: StoryCharacter, text: String, node: DialogueNode)
signal choices_shown(choices: Array[String], node: ChoiceNode)
signal variable_changed(variable_name: StringName, value: Variant)
signal story_ended

## Returned by StoryNode.execute(): pause until advance() is called.
const WAIT: int = -1
## Returned by StoryNode.execute(): the story ends here.
const END: int = -2
## Safety net against loops made only of automatic nodes (e.g. Restart).
const MAX_STEPS: int = 1000

enum State {
	IDLE,
	WAITING_FOR_ADVANCE,
	WAITING_FOR_CHOICE,
	ENDED,
}

var story: StoryData
var current_node: StoryNode
var state: State = State.IDLE

var variables: Dictionary[StringName, Variant] = { }


func _init(story_data: StoryData) -> void:
	story = story_data
	_initialize_variables()
	reset_position()


## Begins (or begins again) from the Start node. Variables are left untouched;
## call reset_variables() first for a clean run.
func start() -> void:
	reset_position()
	story_started.emit()
	_run(current_node, 0)


## Continues after a dialogue.
func advance() -> void:
	if state != State.WAITING_FOR_ADVANCE:
		return

	_run(current_node, 0)


## Continues after a choice. `index` is the position in the ChoiceNode's list.
func choose(index: int) -> void:
	if state != State.WAITING_FOR_CHOICE:
		return

	var choice_node: ChoiceNode = current_node as ChoiceNode
	if index < 0 or index >= choice_node.choices.size():
		push_error('Invalid choice %d of %d.' % [index, choice_node.choices.size()])
		return

	_run(current_node, index)


func reset_position() -> void:
	current_node = story.get_start_node()
	state = State.IDLE


func restart() -> void:
	reset_position()


func has_variable(variable_name: StringName) -> bool:
	return variables.has(variable_name)


func get_variable(variable_name: StringName) -> Variant:
	return variables.get(variable_name)


func set_variable(variable_name: StringName, value: Variant) -> void:
	if not variables.has(variable_name):
		return

	variables[variable_name] = value
	variable_changed.emit(variable_name, value)


func reset_variables() -> void:
	_initialize_variables()


## Replaces {variable_name} placeholders with the variable's current value.
func format_text(text: String) -> String:
	for variable_name: StringName in variables:
		text = text.replace('{%s}' % variable_name, str(variables[variable_name]))

	return text


## Converts `value` to the GDScript type matching a StoryVariable.Type.
static func coerce(type: StoryVariable.Type, value: Variant) -> Variant:
	if value == null:
		return zero_value(type)

	match type:
		StoryVariable.Type.BOOL:
			return bool(value)
		StoryVariable.Type.INT:
			return int(value)
		StoryVariable.Type.FLOAT:
			return float(value)
		_:
			return str(value)


static func zero_value(type: StoryVariable.Type) -> Variant:
	match type:
		StoryVariable.Type.BOOL:
			return false
		StoryVariable.Type.INT:
			return 0
		StoryVariable.Type.FLOAT:
			return 0.0
		_:
			return ''


func _initialize_variables() -> void:
	variables.clear()

	var library: StoryVariableLibrary = story.variable_library

	if library == null:
		return

	for variable: StoryVariable in library.variable_list:
		variables[variable.name] = variable.default_value


## Follows `port` of `from`, then keeps executing automatic nodes until one
## needs input or the story runs out of links.
func _run(from: StoryNode, port: int) -> void:
	var node: StoryNode = from
	var output_port: int = port

	state = State.IDLE

	for _step: int in MAX_STEPS:
		var next: StoryNode = _get_next_node(node, output_port)

		if next == null:
			_end()
			return

		current_node = next
		output_port = _execute(next)

		if output_port == WAIT:
			return

		if output_port == END:
			_end()
			return

		# Nodes such as Restart move current_node themselves.
		node = current_node

	push_error(
		'Story stopped after %d steps without waiting for input. Is there a loop?' % MAX_STEPS
	)
	_end()


func _get_next_node(node: StoryNode, port: int) -> StoryNode:
	var links: Array[StoryLink] = story.get_links_from_port(node.instance_id, port)

	if links.is_empty():
		return null

	return story.get_node(links[0].to)


func _execute(node: StoryNode) -> int:
	if node is DialogueNode:
		return _execute_dialogue(node as DialogueNode)

	if node is ChoiceNode:
		return _execute_choice(node as ChoiceNode)

	if node is BranchNode:
		return _execute_branch(node as BranchNode)

	if node is SetVariableNode:
		return _execute_set_variable(node as SetVariableNode)

	if node is ModifyVariableNode:
		return _execute_modify_variable(node as ModifyVariableNode)

	if node is RestartStoryNode:
		current_node = story.get_start_node()
		return 0

	# Start nodes and custom nodes.
	return node.execute(self)


func _execute_dialogue(node: DialogueNode) -> int:
	state = State.WAITING_FOR_ADVANCE
	dialogue_shown.emit(_find_character(node.character), format_text(node.dialogue), node)
	return WAIT


func _execute_choice(node: ChoiceNode) -> int:
	if node.choices.is_empty():
		push_warning('Choice node "%s" has no choices.' % node.instance_id)
		return END

	var texts: Array[String] = []
	for choice: String in node.choices:
		texts.append(format_text(choice))

	state = State.WAITING_FOR_CHOICE
	choices_shown.emit(texts, node)
	return WAIT


## Follows the port of the first condition that is true; ends if none are.
func _execute_branch(node: BranchNode) -> int:
	var variable: StoryVariable = node.variable

	if variable == null or not variables.has(variable.name):
		push_warning('Branch node "%s" has no valid variable.' % node.instance_id)
		return END

	var value: Variant = variables[variable.name]
	var conditions: Array[BranchCondition] = node.conditions

	for index: int in conditions.size():
		if _evaluate(conditions[index], variable.type, value):
			return index

	return END


func _evaluate(condition: BranchCondition, type: StoryVariable.Type, value: Variant) -> bool:
	var expected: Variant = coerce(type, condition.value)

	match condition.operator:
		BranchCondition.Operator.IS_EMPTY:
			return str(value).is_empty()
		BranchCondition.Operator.IS_NOT_EMPTY:
			return not str(value).is_empty()
		BranchCondition.Operator.IS_TRUE:
			return bool(value)
		BranchCondition.Operator.IS_FALSE:
			return not bool(value)
		BranchCondition.Operator.EQUAL:
			return value == expected
		BranchCondition.Operator.NOT_EQUAL:
			return value != expected
		BranchCondition.Operator.LESS:
			return value < expected
		BranchCondition.Operator.LESS_EQUAL:
			return value <= expected
		BranchCondition.Operator.GREATER:
			return value > expected
		BranchCondition.Operator.GREATER_EQUAL:
			return value >= expected

	return false


func _execute_set_variable(node: SetVariableNode) -> int:
	var variable: StoryVariable = node.variable

	if variable == null or not variables.has(variable.name):
		push_warning('Set Variable node "%s" has no valid variable.' % node.instance_id)
		return 0

	set_variable(variable.name, coerce(variable.type, node.value))
	return 0


func _execute_modify_variable(node: ModifyVariableNode) -> int:
	var variable: StoryVariable = node.variable

	if variable == null or not variables.has(variable.name):
		push_warning('Modify Variable node "%s" has no valid variable.' % node.instance_id)
		return 0

	var current: Variant = variables[variable.name]
	var operand: Variant = coerce(variable.type, node.value)
	var is_number: bool = (
		variable.type == StoryVariable.Type.INT or variable.type == StoryVariable.Type.FLOAT
	)
	var result: Variant = current

	match node.operation:
		ModifyVariableNode.Operation.CLEAR:
			result = zero_value(variable.type)
		ModifyVariableNode.Operation.ADD:
			if is_number or variable.type == StoryVariable.Type.STRING:
				result = current + operand
		ModifyVariableNode.Operation.SUBTRACT:
			if is_number:
				result = current - operand
		ModifyVariableNode.Operation.MULTIPLY:
			if is_number:
				result = current * operand
		ModifyVariableNode.Operation.DIVIDE:
			if is_number and operand != 0:
				result = coerce(variable.type, float(current) / float(operand))
		ModifyVariableNode.Operation.TOGGLE:
			if variable.type == StoryVariable.Type.BOOL:
				result = not current

	if is_same(result, current) and node.operation != ModifyVariableNode.Operation.CLEAR:
		push_warning(
			'Modify Variable node "%s": operation does not apply to "%s".'
			% [node.instance_id, variable.name],
		)

	set_variable(variable.name, result)
	return 0


func _find_character(id: StringName) -> StoryCharacter:
	if id.is_empty() or story.character_library == null:
		return null

	return story.character_library.get_character(id)


func _end() -> void:
	state = State.ENDED
	story_ended.emit()
