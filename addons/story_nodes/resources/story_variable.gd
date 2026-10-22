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
		if _name == new_value:
			return
		if _history == null:
			_name = new_value
			emit_changed()
			return
		_history.record_property('Set Name', self, &'_name', new_value, _name, emit_changed)

@export var type: Type:
	get:
		return _type
	set(new_value):
		if _type == new_value:
			return
		if _history == null:
			_type = new_value
			emit_changed()
			return

		_history.record_property('Set Type', self, &'_type', new_value, _type, emit_changed)

@export var default_value: Variant:
	get:
		return _default_value
	set(new_value):
		if _default_value == new_value:
			return
		if _history == null:
			_default_value = new_value
			emit_changed()
			return

		_history.record_property(
			'Set Default Value',
			self,
			&'_default_value',
			new_value,
			_default_value,
			emit_changed,
		)

var value: Variant = default_value

var _name: StringName = &''
var _type: Type = Type.STRING
var _default_value: Variant = ''
var _history: StoryHistory


func set_history(history: StoryHistory) -> void:
	if history == null:
		push_error('Every story variable needs access to the story\'s history!')
		return

	_history = history
