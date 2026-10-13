@tool
class_name DialogueNode
extends StoryNode

@export var character: StringName:
	get:
		return _character
	set(new_value):
		var old_value = _character
		if old_value == new_value:
			return
		if _undo_redo == null:
			_character = new_value
			emit_changed()
			return

		_undo_redo.create_action('Set character')

		_undo_redo.add_do_property(self, '_character', new_value)
		_undo_redo.add_undo_property(self, '_character', old_value)

		_undo_redo.add_do_method(emit_changed)
		_undo_redo.add_undo_method(emit_changed)
		_undo_redo.commit_action()

@export_multiline var dialogue: String = '':
	get:
		return _dialogue
	set(new_value):
		var old_value = _dialogue
		if old_value == new_value:
			return
		if _undo_redo == null:
			_dialogue = new_value
			emit_changed()
			return

		_undo_redo.create_action('Set dialogue')

		_undo_redo.add_do_property(self, '_dialogue', new_value)
		_undo_redo.add_undo_property(self, '_dialogue', old_value)

		_undo_redo.add_do_method(emit_changed)
		_undo_redo.add_undo_method(emit_changed)
		_undo_redo.commit_action()

var _character: StringName = &''
var _dialogue: String = ''
