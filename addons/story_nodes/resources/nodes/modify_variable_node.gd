@tool
class_name ModifyVariableNode
extends StandardStoryNode

enum Operation {
	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE,
	TOGGLE,
}

@export var variable: StoryVariable
@export var operation: Operation = Operation.ADD
@export var value: Variant
