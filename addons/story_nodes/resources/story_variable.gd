@tool
class_name StoryVariable
extends Resource

enum Type {
	BOOL,
	INT,
	FLOAT,
	STRING,
}

@export var name: StringName:
	get:
		return _name

@export var type: Type:
	get:
		return _type

@export var default_value: Variant:
	get:
		return _default_value

var value: Variant = default_value

var _name: StringName = &''
var _type: Type = Type.STRING
var _default_value: Variant = ''
var _undo_redo: UndoRedo


func set_undo_redo(undo_redo: UndoRedo) -> void:
	if undo_redo == null:
		push_error('Every story variable needs access to the story\'s UndoRedo!')
		return

	_undo_redo = undo_redo
