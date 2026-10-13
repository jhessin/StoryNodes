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
	set(new_value):
		var old_value = _name
		if old_value == new_value:
			return
		if _undo_redo == null:
			_name = new_value
			emit_changed()
			return

		_undo_redo.create_action('Set name')

		_undo_redo.add_do_property(self, '_name', new_value)
		_undo_redo.add_undo_property(self, '_name', old_value)

		_undo_redo.add_do_method(emit_changed)
		_undo_redo.add_undo_method(emit_changed)
		_undo_redo.commit_action()

@export var type: Type:
	get:
		return _type
	set(new_value):
		var old_value = _type
		if old_value == new_value:
			return
		if _undo_redo == null:
			_type = new_value
			emit_changed()
			return

		_undo_redo.create_action('Set name')

		_undo_redo.add_do_property(self, '_type', new_value)
		_undo_redo.add_undo_property(self, '_type', old_value)

		_undo_redo.add_do_method(emit_changed)
		_undo_redo.add_undo_method(emit_changed)
		_undo_redo.commit_action()

@export var default_value: Variant:
	get:
		return _default_value
	set(new_value):
		var old_value = _default_value
		if old_value == new_value:
			return
		if _undo_redo == null:
			_default_value = new_value
			emit_changed()
			return

		_undo_redo.create_action('Set name')

		_undo_redo.add_do_property(self, '_default_value', new_value)
		_undo_redo.add_undo_property(self, '_default_value', old_value)

		_undo_redo.add_do_method(emit_changed)
		_undo_redo.add_undo_method(emit_changed)
		_undo_redo.commit_action()

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
