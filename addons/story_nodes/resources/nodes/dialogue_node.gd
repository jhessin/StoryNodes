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
		if _history == null:
			_character = new_value
			emit_changed()
			return

		_history.record_property('Set Character', self, &'_character', new_value, old_value, emit_changed)

@export_multiline var dialogue: String = '':
	get:
		return _dialogue
	set(new_value):
		var old_value = _dialogue
		if old_value == new_value:
			return
		if _history == null:
			_dialogue = new_value
			emit_changed()
			return

		_history.record_property('Set Dialogue', self, '_dialogue', new_value, old_value, emit_changed)

var _character: StringName = &''
var _dialogue: String = ''
