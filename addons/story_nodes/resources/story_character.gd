@tool
class_name StoryCharacter
extends Resource

@export var name: String:
	get:
		return _name
	set(new_value):
		var old_value = _name
		if old_value == new_value:
			return
		if _history == null:
			_name = new_value
			emit_changed()
			return

		_history.record_property('Set Name', self, &'_name', new_value, old_value, emit_changed)

@export var image: Texture2D:
	get:
		return _image
	set(new_value):
		var old_value = _image
		if old_value == new_value:
			return
		if _history == null:
			_image = new_value
			emit_changed()
			return

		_history.record_property('Set Image', self, &'_image', new_value, old_value, emit_changed)

@export var color: Color:
	get:
		return _color
	set(new_value):
		var old_value = _color
		if old_value == new_value:
			return
		if _history == null:
			_color = new_value
			emit_changed()
			return

		_history.record_property('Set Color', self, &'_color', new_value, old_value, emit_changed)


@export var id: StringName:
	get:
		return _id

var _name: String = ''
var _image: Texture2D
var _color: Color = Color.WHITE
var _history: StoryHistory

var _id: StringName = &''


func _init(character_name: String = '') -> void:
	_id = character_name.replace(' ', '_').to_lower()
	name = character_name


func set_history(history: StoryHistory) -> void:
	if history == null:
		push_error('Every story node needs access to the story\'s history!')
		return

	_history = history
